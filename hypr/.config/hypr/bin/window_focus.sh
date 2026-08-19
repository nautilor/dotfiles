#!/usr/bin/env bash

function movefocus {
	hyprctl dispatch movefocus "$window_to_focus"
}

function movecolumn {
	if [ "$window_to_focus" == "r" ]; then
		column_to_focus="+col"
	fi
	hyprctl dispatch "layoutmsg move $column_to_focus"
}

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 l|r"
	exit 1
fi

window_to_focus="$1"
column_to_focus="-col"

if ! [[ "$window_to_focus" =~ ^[lr]$ ]]; then
	echo "Invalid argument: $window_to_focus. Use 'l' or 'r'."
	exit 1
fi

is_fullscreen=`hyprctl activewindow -j | jq -r '.fullscreen'`
if [ -z "$is_fullscreen" ] || [ "$is_fullscreen" == "null" ]; then
	is_fullscreen=1
fi

if [ "$is_fullscreen" -eq 1 ]; then
	movecolumn
else
	movefocus
fi

