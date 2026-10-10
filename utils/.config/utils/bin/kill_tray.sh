#!/usr/bin/env bash
#
# Force-kill selected chat/game apps via an fzf picker.
#
set -uo pipefail

readonly OPTIONS=(
	"Steam"
	"Telegram"
	"WhatsApp"
	"All"
)


function is_running() {
	local process_name="$1"
	if pgrep "$process_name" > /dev/null; then
		return 0
	else
		return 1
	fi
}

function kill_process() {
	local process_name="$1"
	local custom_command="${2:-}"
	if is_running "$process_name"; then
		if [[ -n "$custom_command" ]]; then
			eval "$custom_command"
		else
			pkill -9 "$process_name"
		fi
	fi
}

selected=$(printf '%s\n' "${OPTIONS[@]}" | ${FZF_COMMAND:-fzf})

case "$selected" in
	"Steam")
		kill_process "steam" "steam -shutdown"
		;;
	"Telegram")
		kill_process "Telegram"
		;;
	"WhatsApp")
		kill_process "zapzap"
		;;
	"All")
		kill_process "steam" "steam -shutdown"
		kill_process "Telegram"
		kill_process "zapzap"
		;;
esac
