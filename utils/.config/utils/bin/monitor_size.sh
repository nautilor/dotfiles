#!/usr/bin/env bash
#
# Pick "Original" or "Zoomed" monitor scaling via fzf, applied to the
# currently focused monitor.
#
set -euo pipefail

readonly OPTIONS=("Original" "Zoomed")

monitors=$(hyprctl monitors -j)
default_monitor=$(jq -r '.[] | select(.name | test("^(eDP|LVDS)")) | .name' <<< "$monitors")
focused_monitor=$(jq -r '.[] | select(.focused) | .name' <<< "$monitors")

if [[ "$focused_monitor" == "$default_monitor" ]]; then
	position="0x0"
else
	position="auto-up"
fi

selected=$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Select notification type: " --border)

case "$selected" in
	"Original")
		hyprctl keyword monitor "$focused_monitor,highres@highrr,$position,1"
		;;
	"Zoomed")
		hyprctl keyword monitor "$focused_monitor,highres@highrr,$position,2"
		;;
esac
