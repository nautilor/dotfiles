#!/usr/bin/env bash
#
# Toggle floating mode for the active window and resize/center it appropriately.
#
set -euo pipefail

hyprctl dispatch togglefloating

active_window=$(hyprctl activewindow -j)
tags=$(echo "$active_window" | jq -r '.tags | join(", ")')
stableId=$(echo "$active_window" | jq -r '.stableId')
is_floating=$(echo "$active_window" | jq -r '.floating')

if [ "$is_floating" = "true" ]; then
	exit 0
fi

if echo "$tags" | grep -q "terminal"; then
	hyprctl dispatch resizeactive exact 800 600
	hyprctl dispatch centerwindow 1
else
	hyprctl dispatch resizeactive exact 1300 800
	hyprctl dispatch centerwindow 1
fi
hyprctl dispatch focuswindow "$active_window"
