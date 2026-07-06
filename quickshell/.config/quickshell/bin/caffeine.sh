#!/usr/bin/env bash
#
# Toggle a "caffeine" mode that inhibits idle/sleep via systemd-inhibit.
#
set -euo pipefail

readonly PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine.pid"

qs_ipc() {
	qs ipc --any-display --newest call "$@" >/dev/null 2>&1 || true
}

is_active() {
	[[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

notify_waybar() {
	pkill -x -SIGRTMIN+1 waybar >/dev/null 2>&1 || true
}

start() {
	if is_active; then
		qs_ipc osd caffeine
		exit 0
	fi

	systemd-inhibit \
		--what=idle:sleep \
		--mode=block \
		--why="Caffeine active" \
		sleep infinity &
	echo $! > "$PIDFILE"

	notify_waybar
	qs_ipc osd caffeine
}

stop() {
	if is_active; then
		kill "$(cat "$PIDFILE")"
		rm -f "$PIDFILE"
	fi

	notify_waybar
	qs_ipc osd caffeine
}

state() {
	if is_active; then
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
	if is_active; then
		stop
	else
		start
	fi
}

icon() {
	if is_active; then
		echo '{"text":"󰅶","class":"active"}'
	else
		echo '{"text":"󰅶","class":"inactive"}'
	fi
}

case "${1:-}" in
	start)  start ;;
	stop)   stop ;;
	state)  state ;;
	status) status ;;
	toggle) toggle ;;
	icon)   icon ;;
	*)
		echo "Usage: $0 {start|stop|state|status|toggle|icon}" >&2
		exit 1
		;;
esac
