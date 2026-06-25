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
	# Ensure QuickShell DnD is enabled when entering focus mode
	if [[ -x "$HOME/.config/quickshell/bin/control-center.sh" ]]; then
		if [[ "$(bash "$HOME/.config/quickshell/bin/control-center.sh" dnd-status)" != "on" ]]; then
			bash "$HOME/.config/quickshell/bin/control-center.sh" dnd-toggle >/dev/null 2>&1 || true
		fi
	fi

	# Hide QuickShell RoundCorner module if QuickShell is running (or start it)
	if command -v qs >/dev/null 2>&1; then
		if ! pgrep -f "quickshell" >/dev/null 2>&1; then
			quickshell >/dev/null 2>&1 &
			disown
			sleep 0.2
		fi
		qs ipc --any-display --newest call root toggle >/dev/null 2>&1 || true
	fi
}

disable_focus_mode() {
	rm "$FOCUS_MODE_ENABLED_FILE"
	hyprctl reload
	update_wallpaper
	# Ensure QuickShell DnD is disabled when leaving focus mode
	if [[ -x "$HOME/.config/quickshell/bin/control-center.sh" ]]; then
		if [[ "$(bash "$HOME/.config/quickshell/bin/control-center.sh" dnd-status)" == "on" ]]; then
			bash "$HOME/.config/quickshell/bin/control-center.sh" dnd-toggle >/dev/null 2>&1 || true
		fi
	fi

	# Restore QuickShell RoundCorner module (toggle back)
	if command -v qs >/dev/null 2>&1; then
		if ! pgrep -f "quickshell" >/dev/null 2>&1; then
			quickshell >/dev/null 2>&1 &
			disown
			sleep 0.2
		fi
		qs ipc --any-display --newest call root toggle >/dev/null 2>&1 || true
	fi
}

[ -f "$FOCUS_MODE_ENABLED_FILE" ] && disable_focus_mode || enable_focus_mode
