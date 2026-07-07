#!/usr/bin/env bash
set -euo pipefail

action="${1-}"

case "$action" in
	poweroff)
		exec systemctl poweroff -i
		;;
	reboot)
		exec systemctl reboot -i
		;;
	lock)
		hyprlock
		exit 0
		;;
	exit|logout)
		hyprctl dispatch exit
		exit 0
		;;
	"" )
		;;
	*)
		echo "Unknown action: $action" >&2
		exit 2
		;;
esac

# No action provided: show the rofi menu (legacy)
if pgrep -f rofi >/dev/null; then
	pkill -x rofi
	exit 0
fi

case $(printf "%s\n" "" "" "" "󰑓" | rofi -dmenu -theme power) in
	"")
		hyprctl dispatch exit
		;;
	"󰑓")
		exec systemctl reboot -i
		;;
	"")
		exec systemctl poweroff -i
		;;
	"")
		hyprlock
		;;
esac
