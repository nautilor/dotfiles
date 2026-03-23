#!/usr/bin/env bash

hyprctl dispatch togglefloating
if hyprctl activewindow | grep -q "tags: *terminal" && hyprctl activewindow | grep -q "floating: 1"; then 
	hyprctl dispatch resizeactive exact 800 600 
	hyprctl dispatch centerwindow 1;
elif hyprctl activewindow | grep -q "floating: 1"; then
	hyprctl dispatch resizeactive exact 1300 800 
	hyprctl dispatch centerwindow 1;
fi
