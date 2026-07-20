#!/usr/bin/env bash

current="$(hyprctl activeworkspace -j)"
monitors=$(hyprctl monitors -j)
default_monitor=$(echo "$monitors" | jq -r '.[] | select(.name | test("^(eDP|LVDS)")) | .name')
current_monitor=$(jq -r '.monitor' <<< "$current")


if [[ "$default_monitor" == "$current_monitor" ]]; then
		next_workspace=$(sed 'y/qwert/12345/' <<< "$1")
		hyprctl dispatch movetoworkspacesilent "$next_workspace"
else
		next_workspace=$(sed 'y/qwert/67899/' <<< "$1")
		hyprctl dispatch movetoworkspacesilent "$next_workspace"
fi

if pgrep -f "waybar" >/dev/null 2>&1; then
		pkill -SIGRTMIN+2 waybar
fi

