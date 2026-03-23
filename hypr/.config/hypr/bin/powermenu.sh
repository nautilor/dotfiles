#!/bin/bash
if pgrep -x rofi; then
    killall rofi
else
		case $(printf "%s\n" "" "" "" "󰑓" | rofi -dmenu -theme power) in
			"")
				hyprctl dispatch exit
				;;
			"󰑓")
				exec systemctl reboot -i
				;;
			"")
				exec systemctl  poweroff -i
				;;
			"")
				hyprlock
				;;
		esac
fi
