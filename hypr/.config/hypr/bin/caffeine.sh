#!/usr/bin/env bash

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine.pid"

qs_ipc() {
    qs ipc --any-display --newest call "$@" >/dev/null 2>&1 || true
}

start() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        qs_ipc osd caffeine
        exit 0
    fi

    systemd-inhibit \
        --what=idle:sleep \
        --mode=block \
        --why="Caffeine active" \
        sleep infinity &

    echo $! > "$PIDFILE"

    pkill -x -SIGRTMIN+1 waybar >/dev/null 2>&1 || true
    qs_ipc osd caffeine
}

stop() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        kill "$(cat "$PIDFILE")"
        rm -f "$PIDFILE"
    fi

    pkill -x -SIGRTMIN+1 waybar >/dev/null 2>&1 || true
    qs_ipc osd caffeine
}

state() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        printf 'active\n'
    else
        printf 'inactive\n'
    fi
}

status() {
    if [[ "$(state)" == "active" ]]; then
        exit 0
    else
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
        echo '{"text":"󰅶","class":"active"}'
    else
        echo '{"text":"󰅶","class":"inactive"}'
    fi
}

case "$1" in
    start)  start ;;
    stop)   stop ;;
   state)  state ;;
   status) status ;;
   toggle) toggle ;;
   icon) icon ;;
   *) echo "Usage: $0 {start|stop|state|status|toggle|icon}" ;;
esac
