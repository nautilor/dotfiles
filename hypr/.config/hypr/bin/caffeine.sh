#!/usr/bin/env bash

PIDFILE="$XDG_RUNTIME_DIR/caffeine.pid"

start() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
			swayosd-client --custom-message="Caffeine already active" --custom-icon="caffeine"
        exit 0
    fi

    systemd-inhibit \
        --what=idle:sleep \
        --mode=block \
        --why="Caffeine active" \
        sleep infinity &

    echo $! > "$PIDFILE"

		swayosd-client --custom-message="Caffeine active" --custom-icon="caffeine"
    pkill -SIGRTMIN+1 waybar
}

stop() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        kill "$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
				swayosd-client --custom-message="Caffeine inactive" --custom-icon="caffeine"
    else
			swayosd-client --custom-message="Caffeine already inactive" --custom-icon="caffeine-off"
				exit 0
    fi

    pkill -SIGRTMIN+1 waybar
}

status() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
			swayosd-client --custom-message="Caffeine active" --custom-icon="caffeine" 
        exit 0
    else
			swayosd-client --custom-message="Caffeine inactive" --custom-icon="caffeine"
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

