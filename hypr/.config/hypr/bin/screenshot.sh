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

image_path="${OUTPUT_DIR}/${filename}"

action=$(notify-send \
	-i "gnome-screenshot" \
	-t 5000 \
	"Screenshot saved" "Saved to ${image_path}" \
	--action="view=View" \
	--action="open=Open folder" \
	--action="edit=Edit image")

case "$action" in
	view)
		xdg-open "${image_path}"
		;;
	edit)
		satty --filename "${image_path}"
		;;
	open)
		xdg-open "$OUTPUT_DIR"
		;;
esac
