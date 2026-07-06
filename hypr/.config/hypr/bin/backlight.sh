#!/usr/bin/env bash
#
# Cycle asusctl keyboard LED brightness: off -> low -> med -> high -> off
#
set -euo pipefail

readonly TEMP_FILE="/tmp/asusctl_leds_temp"

if ! command -v asusctl &> /dev/null; then
	notify-send -i "error" "asusctl" "Required dependencies are not installed!"
	echo "Please install 'asusctl' to use this script." >&2
	exit 1
fi

set_state() {
	local state="$1"
	asusctl leds set "$state"
	echo "$state" > "$TEMP_FILE"
}

current_state=$(cat "$TEMP_FILE" 2>/dev/null || echo "off")

case "$current_state" in
	off)
		set_state "low"
		;;
	low)
		set_state "med"
		;;
	med)
		set_state "high"
		;;
	*)
		set_state "off"
		;;
esac
