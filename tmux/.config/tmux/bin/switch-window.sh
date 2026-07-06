#!/usr/bin/env bash
#
# Fuzzy-pick an existing tmux window or create a new one by typing a name.
#
set -uo pipefail

selection=$(tmux list-windows -F "#I:#W" | fzf --prompt="window: " --print-query)
[[ -z "$selection" ]] && exit 0

query=$(head -n1 <<< "$selection")
window=$(tail -n1 <<< "$selection")

if [[ "$window" != "$query" ]]; then
	window_id="${window%%:*}"
	window_name="${window#*:}"
	tmux select-window -t "$window_id"
else
	window_name="$query"
	window_path="#{pane_current_path}"
	tmux new-window -n "$window_name" -c "$window_path"
fi
