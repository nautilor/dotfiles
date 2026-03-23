#!/usr/bin/env bash

OUTPUT_IMAGE="/tmp/colorpicker.png"
COLOR=`hyprpicker`
RGB_TOOL="~/.config/hypr/bin/rgb_color.py"

[ -z "$COLOR" ] && exit 1

# check if and argument is passed to the script
if [ "$1" == "editor" ]; then
	echo $COLOR | bash -c "$RGB_TOOL"
	exit 0
fi

echo -n $COLOR | wl-copy

magick -size 100x100 xc:none -fill "${COLOR}" -draw "roundRectangle 0,0 100,100 15,15" "$OUTPUT_IMAGE"

notify-send -i "$OUTPUT_IMAGE" "Color Copied" "${COLOR}"

rm "$OUTPUT_IMAGE"
