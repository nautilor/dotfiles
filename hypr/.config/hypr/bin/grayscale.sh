#!/usr/bin/env bash
SHADER_LOCATION="$HOME/.config/hypr/shaders/grayscale.frag"
GRAYSCALE_MODE_ENABLED=/tmp/grayscale_mode_enabled

if [[ ! -f $SHADER_LOCATION ]]; then
		echo "Grayscale shader not found at $SHADER_LOCATION"
		exit 1
fi

if [[ -f $GRAYSCALE_MODE_ENABLED ]]; then
		rm $GRAYSCALE_MODE_ENABLED
		hyprctl keyword decoration:screen_shader ""
		notify-send -i "color-picker" "Grayscale shader removed."
else 
		touch $GRAYSCALE_MODE_ENABLED
	hyprctl keyword decoration:screen_shader "$SHADER_LOCATION"
	notify-send -i "color-picker" "Grayscale shader applied."
fi
