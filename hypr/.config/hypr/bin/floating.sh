#!/usr/bin/env bash
#
# Toggle floating mode for the active window and resize/center it appropriately.
#
set -euo pipefail

hyprctl dispatch togglefloating

active_window=$(hyprctl activewindow)

if echo "$active_window" | grep -q "tags: *terminal" && echo "$active_window" | grep -q "floating: 1"; then
	hyprctl dispatch resizeactive exact 800 600
	hyprctl dispatch centerwindow 1
elif echo "$active_window" | grep -q "floating: 1"; then
	hyprctl dispatch resizeactive exact 1300 800
	hyprctl dispatch centerwindow 1
fi
