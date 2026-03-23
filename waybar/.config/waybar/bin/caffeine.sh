#!/usr/bin/env bash

PIDFILE="$XDG_RUNTIME_DIR/caffeine.pid"

start() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        notify-send -i dialog-information "Caffeine" "Already active"
        exit 0
    fi

    systemd-inhibit \
        --what=idle:sleep \
        --mode=block \
        --why="Caffeine active" \
        sleep infinity &

    echo $! > "$PIDFILE"

    notify-send -i dialog-information "Caffeine Started" \
        "System will not sleep"

    pkill -SIGRTMIN+1 waybar
}

stop() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        kill "$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
        notify-send -i dialog-information "Caffeine Stopped" \
            "System can sleep"
    else
        notify-send -i dialog-information "Caffeine" "Not active"
    fi

    pkill -SIGRTMIN+1 waybar
}

status() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
			notify-send -i dialog-information "Caffeine" "Active"
        exit 0
    else
			notify-send -i dialog-information "Caffeine" "Inactive"
        exit 1
    fi
}

toggle() {
		if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
				stop
		else
				start
		fi
}

icon() {
		if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
			echo '{"text":"","class":"active"}'
    else
			echo '{"text":"","class":"inactive"}'
		fi
}

case "$1" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
		toggle) toggle ;;
		icon) icon ;;
    *) echo "Usage: $0 {start|stop|status|toggle|icon}" ;;
esac

