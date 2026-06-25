#!/usr/bin/env bash

WALLPAPER="$HOME/.config/hypr/assets/wallpaper.png"
FOCUS_MODE_WALLPAPER="$HOME/.config/hypr/assets/wallpaper_focus.png"

set_default_wallpaper() {
	set_wallpaper "$WALLPAPER"
}

set_wallpaper() {
	awww img "$1" --transition-type=fade --transition-duration=0.5
}

init() {
	if ! pgrep -f "awww-daemon" > /dev/null
	then
			awww-daemon & disown
	fi
	set_default_wallpaper
}

toggle_focus_mode() {
	# Determine current displayed wallpaper basename
	current_wallpaper=$(awww  query | sed 's/.*image://g' | head -n 1 | sed 's/.*\///g')

	cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
	mkdir -p "$cache_dir"
	blurred="$cache_dir/wallpaper_blurred.png"

	orig_base="$(basename "$WALLPAPER")"	
	blur_base="$(basename "$blurred")"

	# If the current wallpaper is the original, create (or refresh) a blurred copy and use it.
	if [[ "$current_wallpaper" == "$orig_base" ]]; then
		# Regenerate blurred image if missing or older than source
		if [[ ! -f "$blurred" || "$blurred" -ot "$WALLPAPER" ]]; then
			if command -v magick >/dev/null 2>&1; then
				magick "$WALLPAPER" -resize 3840x2160\> -blur 0x10 "$blurred"
			elif command -v convert >/dev/null 2>&1; then
				convert "$WALLPAPER" -resize 3840x2160\> -blur 0x8 "$blurred"
			else
				echo "ImageMagick not found; cannot generate blurred wallpaper" >&2
				return 1
			fi
		fi

		set_wallpaper "$blurred"
	# If the current wallpaper is already the blurred copy, restore the original
	elif [[ "$current_wallpaper" == "$blur_base" ]]; then
		set_wallpaper "$WALLPAPER"
	# Fallback: if current is something else, switch to blurred version
	else
		if [[ ! -f "$blurred" || "$blurred" -ot "$WALLPAPER" ]]; then
			if command -v magick >/dev/null 2>&1; then
				magick "$WALLPAPER" -resize 3840x2160\> -blur 0x10 "$blurred"
			elif command -v convert >/dev/null 2>&1; then
				convert "$WALLPAPER" -resize 3840x2160\> -blur 0x8 "$blurred"
			else
				echo "ImageMagick not found; cannot generate blurred wallpaper" >&2
				return 1
			fi
		fi
		set_wallpaper "$blurred"
	fi
}


# check if awww is installed
if ! command -v awww &> /dev/null
then
		echo "awww could not be found, please install awww to use this script."
		exit 1
fi

# check for arguments
case "$1" in
	init) init;;
	focus_mode) toggle_focus_mode;;
	*) echo "Usage: $0 {init|focus_mode}"; exit 1;;
esac


