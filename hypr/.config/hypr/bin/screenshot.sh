#!/usr/bin/env bash
#
# Take a region screenshot with hyprshot, disabling animations during
# capture, then offer to view/edit/open it via a notification action.
#
set -uo pipefail

readonly OUTPUT_DIR="${HOME}/Pictures/Screenshots"

filename="screenshot-$(date +%Y-%m-%d-%H-%M-%S).png"

mkdir -p "$OUTPUT_DIR"

hyprctl keyword animations:enabled false
trap 'hyprctl keyword animations:enabled true' EXIT

if ! DXVK_FILTER_DEVICE_NAME="NVIDIA" hyprshot --freeze -m region -f "$filename" -o "$OUTPUT_DIR" -s; then
	notify-send -i "error" "Screenshot Failed" "hyprshot did not complete successfully."
	exit 1
fi

action=$(notify-send "Screenshot saved" "Saved to ${OUTPUT_DIR}/${filename}" \
	-i "info" -t 5000 \
	--action="view=View" \
	--action="open=Open folder" \
	--action="edit=Edit image")

case "$action" in
	view)
		xdg-open "${OUTPUT_DIR}/${filename}"
		;;
	edit)
		satty --filename "${OUTPUT_DIR}/${filename}"
		;;
	open)
		xdg-open "$OUTPUT_DIR"
		;;
esac
