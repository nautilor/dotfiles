#!/usr/bin/env bash

WALLPAPER="$HOME/.config/hypr/assets/wallpaper.png"
FOCUS_MODE_WALLPAPER="$HOME/.config/hypr/assets/wallpaper_focus.png"

set_default_wallpaper() {
	set_wallpaper "$WALLPAPER"
}

set_wallpaper() {
	swww img "$1" --transition-type=fade --transition-duration=0.5
}

init() {
	if ! pgrep -x "swww-daemon" > /dev/null
	then
			swww-daemon & disown
	fi
	set_default_wallpaper
}

toggle_focus_mode() {
	current_wallpaper=$(swww  query | sed 's/.*image://g' | head -n 1 | sed 's/.*\///g')
	if [[ "$WALLPAPER" =~ "$current_wallpaper" ]]; then
		set_wallpaper "$FOCUS_MODE_WALLPAPER"
	else
		set_wallpaper "$WALLPAPER"
	fi
}


# check if swww is installed
if ! command -v swww &> /dev/null
then
		echo "swww could not be found, please install swww to use this script."
		exit 1
fi

# check for arguments
case "$1" in
	init) init;;
	focus_mode) toggle_focus_mode;;
	*) echo "Usage: $0 {init|focus_mode}"; exit 1;;
esac


