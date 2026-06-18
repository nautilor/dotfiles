#!/usr/bin/env bash

OPTIONS=("Original" "Zoomed")
DEFAULT_MONITOR="eDP-1"
MONITOR=$(hyprctl monitors -j | jq '.[] | select(.focused)')
NAME=$(echo "$MONITOR" | jq -r '.name')
POSITION=$([ $NAME == $DEFAULT_MONITOR ] && echo "0x0" || echo "auto-up")
SELECTED=$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Select notification type: " --border)
case $SELECTED in
		"Original")
			 hyprctl keyword monitor "$NAME,highres@highrr,$POSITION,1"
				;;
		"Zoomed")
			 hyprctl keyword monitor "$NAME,highres@highrr,$POSTION,2"
				;;
esac
