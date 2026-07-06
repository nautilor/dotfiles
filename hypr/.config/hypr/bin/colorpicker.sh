#!/usr/bin/env bash
#
# Pick a color with hyprpicker, copy it to clipboard, and show a preview notification.
#
set -euo pipefail

readonly OUTPUT_IMAGE="/tmp/colorpicker.png"

color=$(hyprpicker)

if [[ -n "$color" ]]; then
	echo -n "$color" | wl-copy
	magick -size 100x100 xc:none -fill "${color}" -draw "roundRectangle 0,0 100,100 15,15" "$OUTPUT_IMAGE"
	notify-send -i "$OUTPUT_IMAGE" "Color Copied" "${color}"
fi
