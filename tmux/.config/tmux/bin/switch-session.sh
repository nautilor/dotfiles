#!/usr/bin/env bash

selection=$(tmux list-sessions -F "#{session_name}:#{pane_current_path}" | fzf --prompt="Session: " --print-query)

[ -z "$selection" ] && exit 0

query=$(echo "$selection" | head -n1)
session=$(echo "$selection" | tail -n1)

if [ "$session" != "$query" ]; then
	session_name="${session%%:*}"
	session_path="${session#*:}"

	if [ -z "$TMUX" ]; then
		tmux attach-session -t "$session_name"
	else
		tmux switch-client -t "$session_name"
	fi	
else 
	session_name="$query"
	session_path="$HOME"
	tmux new-session -d -s "$session_name" -c "$session_path"
	if [ -z "$TMUX" ]; then
		tmux attach-session -t "$session_name"
	else
		tmux switch-client -t "$session_name"
	fi
fi
