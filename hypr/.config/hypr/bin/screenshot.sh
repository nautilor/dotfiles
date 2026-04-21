#!/usr/bin/env bash
hyprctl keyword animations:enabled false
FILENAME="screenshot-$(date +%Y-%m-%d-%H-%M-%S).png"
OUTPUT_DIR="$HOME/Pictures/Screenshots"
if [ ! -d "$OUTPUT_DIR" ]; then
		mkdir -p "$OUTPUT_DIR"
fi
DXVK_FILTER_DEVICE_NAME="NVIDIA" hyprshot --freeze -m region -f "$FILENAME" -o "$OUTPUT_DIR" -s

action=`notify-send "Screenshot saved" "Saved to $OUTPUT_DIR/$FILENAME" -i "info" -t 5000 --action="view=View" --action="open=Open folder" --action="edit=Edit image"`

if [ "$action" = "view" ]; then
	xdg-open "$OUTPUT_DIR/$FILENAME"
elif [ "$action" = "edit" ]; then
	satty --filename "$OUTPUT_DIR/$FILENAME"
elif [ "$action" = "open" ]; then
	xdg-open "$OUTPUT_DIR"
fi

# DXVK_FILTER_DEVICE_NAME="NVIDIA" hyprshot --freeze -m region --raw | satty --filename -
hyprctl keyword animations:enabled true
