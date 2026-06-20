#!/usr/bin/env bash


if ! command -v asusctl &> /dev/null; then
	notify-send -i "error" "asusctl" "Required dependencies are not installed!"
	echo "Please install 'asusctl' to use this script."
	exit 1
fi

TEMP_FILE="/tmp/asusctl_leds_temp"

function set() {
	local state="$1"
	asusctl leds set "$state"
	echo "$state" > "$TEMP_FILE"
}

current_state=$(cat "$TEMP_FILE" 2>/dev/null || echo "off")
case "$current_state" in
	off)
		set "low"
		;;
	low)
		set "med"
		;;
	med)
		set "high"
		;;
	*)
		set "off"
		;;
esac


