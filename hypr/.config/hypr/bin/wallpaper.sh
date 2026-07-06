#!/usr/bin/env bash
#
# Set the Hyprland wallpaper via awww, starting the daemon if needed.
#
set -euo pipefail

readonly WALLPAPER="${HOME}/.config/hypr/assets/wallpaper.png"

set_wallpaper() {
	awww img "$1" --transition-type=fade --transition-duration=0.5
}

set_default_wallpaper() {
	set_wallpaper "$WALLPAPER"
}

init() {
	if ! pgrep -f "awww-daemon" > /dev/null; then
		awww-daemon & disown
	fi
	set_default_wallpaper
}

if ! command -v awww &> /dev/null; then
	echo "awww could not be found, please install awww to use this script." >&2
	exit 1
fi

case "${1:-}" in
	init) init ;;
	*)
		echo "Usage: $0 {init}" >&2
		exit 1
		;;
esac
