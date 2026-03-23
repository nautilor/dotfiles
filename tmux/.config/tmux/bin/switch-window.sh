#!/usr/bin/env bash

selection=$(tmux list-windows -F "#I:#W" | fzf --prompt="window: " --print-query)

[ -z "$selection" ] && exit 0

query=$(echo "$selection" | head -n1)
window=$(echo "$selection" | tail -n1)

if [ "$window" != "$query" ]; then
	window_id="${window%%:*}"
	window_name="${window#*:}"
	tmux select-window -t "$window_id"
else 
	window_name="$query"
	window_path="#{pane_current_path}"
	tmux new-window -n "$window_name" -c "$window_path"
fi
