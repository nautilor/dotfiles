#!/usr/bin/env bash

current_path="$1"
session="$(echo "$current_path" | md5sum | cut -c1-5)"
current_session="$(tmux display-message -p '#S' 2>/dev/null)"
if ! tmux has-session -t "$session" 2>/dev/null; then
	tmux new-session -d -s "$session" -c "#{pane_current_path}" "copilot"
	tmux popup -w80% -h80% -xC -yC -E "tmux attach-session -t $session"
else 
	if [ "$current_session" = "$session" ]; then
		tmux detach-client
	else
		tmux popup -w80% -h80% -E "tmux attach-session -t $session"
	fi
fi
