#!/usr/bin/env bash

options=("Original" "Zoomed")
monitors=`hyprctl monitors -j`
default_monitor=`echo $monitors | jq -r '.[] | select(.name | test("^(eDP|LVDS)")) | .name'`
focused_monitor=`echo $monitors | jq -r '.[] | select(.focused) | .name'`
position=$([ $focused_name == $default_monitor ] && echo "0x0" || echo "auto-up")

selected=$(printf '%s\n' "${options[@]}" | fzf --prompt="Select notification type: " --border)
case $selected in
		"Original")
			 hyprctl keyword monitor "$name,highres@highrr,$position,1"
				;;
		"Zoomed")
			 hyprctl keyword monitor "$name,highres@highrr,$position,2"
				;;
esac
