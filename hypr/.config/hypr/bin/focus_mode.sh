#!/usr/bin/env bash
FOCUS_MODE_ENABLED_FILE="/tmp/focus_mode_enabled_$USER"
WALLPAPER_SCRIPT="$HOME/.config/hypr/bin/wallpaper.sh"

update_wallpaper() {
	$WALLPAPER_SCRIPT focus_mode
}

enable_focus_mode() {
	touch "$FOCUS_MODE_ENABLED_FILE"
	hyprctl keyword general:gaps_in 0
	hyprctl keyword general:gaps_out 0
	hyprctl keyword general:border_size 0
	hyprctl keyword decoration:rounding 0
	hyprctl keyword decoration:shadow:enabled false
	hyprctl keyword decoration:dim_inactive true
	hyprctl keyword animations:enabled false
	update_wallpaper
	swaync-client -dn
}

disable_focus_mode() {
	rm "$FOCUS_MODE_ENABLED_FILE"
	hyprctl reload
	update_wallpaper
	swaync-client -df
}

[ -f "$FOCUS_MODE_ENABLED_FILE" ] && disable_focus_mode || enable_focus_mode
