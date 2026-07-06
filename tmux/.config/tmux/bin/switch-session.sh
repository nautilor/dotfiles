#!/usr/bin/env bash
#
# Fuzzy-pick an existing tmux session or create a new one by typing a name,
# then attach or switch to it depending on whether we're already in tmux.
#
set -uo pipefail

selection=$(tmux list-sessions -F "#{session_name}:#{pane_current_path}" | fzf --prompt="Session: " --print-query)
[[ -z "$selection" ]] && exit 0

query=$(head -n1 <<< "$selection")
session=$(tail -n1 <<< "$selection")

if [[ "$session" != "$query" ]]; then
	session_name="${session%%:*}"
	session_path="${session#*:}"
else
	session_name="$query"
	session_path="$HOME"
	tmux new-session -d -s "$session_name" -c "$session_path"
fi

if [[ -z "${TMUX:-}" ]]; then
	tmux attach-session -t "$session_name"
else
	tmux switch-client -t "$session_name"
fi
