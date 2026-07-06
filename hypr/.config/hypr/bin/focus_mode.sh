#!/usr/bin/env bash
#
# Toggle "focus mode": strips visual clutter in Hyprland and syncs
# QuickShell's Do Not Disturb + RoundCorner module state.
#
set -euo pipefail

readonly FOCUS_MODE_ENABLED_FILE="/tmp/focus_mode_enabled_${USER}"
readonly CONTROL_CENTER_SCRIPT="${HOME}/.config/quickshell/bin/control-center.sh"

sync_dnd() {
	local desired_state="$1"

	if [[ -x "$CONTROL_CENTER_SCRIPT" ]]; then
		if [[ "$(bash "$CONTROL_CENTER_SCRIPT" dnd-status)" != "$desired_state" ]]; then
			bash "$CONTROL_CENTER_SCRIPT" dnd-toggle >/dev/null 2>&1 || true
		fi
	fi
}

toggle_quickshell_module() {
	if command -v qs >/dev/null 2>&1; then
		if ! pgrep -f "quickshell" >/dev/null 2>&1; then
			quickshell >/dev/null 2>&1 &
			disown
			sleep 0.2
		fi
		qs ipc --any-display --newest call root toggle >/dev/null 2>&1 || true
	fi
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

	# Ensure QuickShell DnD is enabled when entering focus mode
	sync_dnd "on"

	# Hide QuickShell RoundCorner module if QuickShell is running (or start it)
	toggle_quickshell_module
}

disable_focus_mode() {
	rm -f "$FOCUS_MODE_ENABLED_FILE"
	hyprctl reload

	# Ensure QuickShell DnD is disabled when leaving focus mode
	sync_dnd "off"

	# Restore QuickShell RoundCorner module (toggle back)
	toggle_quickshell_module
}

if [[ -f "$FOCUS_MODE_ENABLED_FILE" ]]; then
	disable_focus_mode
else
	enable_focus_mode
fi
