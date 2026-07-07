#!/usr/bin/env bash
#
# Pomodoro timer for a status bar (e.g. waybar), driven by a small state file.
#
set -euo pipefail

readonly STATE_FILE="/tmp/pomodoro"
readonly DURATION=1500 # 25 minutes

current_status() {
	if [[ -f "$STATE_FILE" ]]; then
		sed -n '1p' "$STATE_FILE"
	else
		echo "stopped"
	fi
}

state_value() {
	sed -n '2p' "$STATE_FILE"
}

is_running() { [[ "$(current_status)" == "running" ]]; }
is_paused()  { [[ "$(current_status)" == "paused" ]]; }
is_break()   { [[ "$(current_status)" == "break" ]]; }
is_stopped() { [[ "$(current_status)" == "stopped" ]]; }

finish_timer() {
	printf "break\n%s\n" "$DURATION" > "$STATE_FILE"
}

reset_timer() {
	printf "stopped\n%s\n" "$DURATION" > "$STATE_FILE"
}

remaining_seconds() {
	local start_time now elapsed
	start_time="$(state_value)"
	now=$(date +%s)
	elapsed=$((now - start_time))
	printf '%s' "$((DURATION - elapsed))"
}

toggle_timer() {
	if is_break || is_stopped; then
		printf "running\n%s\n" "$(date +%s)" > "$STATE_FILE"
	elif is_running; then
		local remaining
		remaining=$(remaining_seconds)
		if (( remaining <= 0 )); then
			finish_timer
		else
			printf "paused\n%s\n" "$remaining" > "$STATE_FILE"
		fi
	else
		local remaining elapsed new_start
		remaining="$(state_value)"
		elapsed=$((DURATION - remaining))
		new_start=$(( $(date +%s) - elapsed ))
		printf "running\n%s\n" "$new_start" > "$STATE_FILE"
	fi
}

format_pomodoro() {
	printf '{"text": "%s", "tooltip": "", "class": [%s], "alt": ""}\n' "$1" "$2"
}

format_minutes_seconds() {
	local total_seconds="$1" minutes seconds
	minutes=$((total_seconds / 60))
	seconds=$((total_seconds % 60))
	printf "%02d:%02d" "$minutes" "$seconds"
}

timer_status() {
	while true; do
		sleep 0.10

		if is_running; then
			local remaining
			remaining=$(remaining_seconds)
			if (( remaining <= 0 )); then
				finish_timer
				format_pomodoro "25:00" '"break"'
				continue
			fi
			format_pomodoro "$(format_minutes_seconds "$remaining")" '"work"'
		elif is_paused; then
			local remaining
			remaining="$(state_value)"
			format_pomodoro "$(format_minutes_seconds "$remaining")" '"pause"'
		elif is_break; then
			format_pomodoro "25:00" '"break"'
		else
			# stopped
			format_pomodoro "25:00" '"stopped"'
		fi
	done
}

usage() {
	cat <<'EOF'
Usage: pomodoro.sh [toggle|reset|help]
Options:
  toggle       Start, pause, or resume a 25-minute work session
  reset        Reset the timer
  help         Show this help message
EOF
}

case "${1:-}" in
	help)
		usage
		;;
	toggle)
		toggle_timer
		;;
	reset)
		reset_timer
		;;
	*)
		timer_status
		;;
esac
