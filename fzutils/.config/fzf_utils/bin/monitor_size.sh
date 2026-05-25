#!/usr/bin/env bash

OPTIONS=("Original" "Default")
SELECTED=$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Select notification type: " --border)

case $SELECTED in
		"Original")
			 hyprctl keyword monitor "eDP-1,highres@highrr,0x0,1"
				;;
		"Default")
			 hyprctl keyword monitor "eDP-1,highres@highrr,0x0,2"
				;;
esac
