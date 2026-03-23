#!/usr/bin/env bash

# the previous command in a floating popup window and store the selected directory in a variable
path="$(fd -t d . ~ ~/.config | fzf --prompt='directory: ')"
# if in a tmux session open a new tmux window with the selected directory

if [[ -n "$TMUX" && -n "$path" ]]; then
		tmux new-window -c "$path"
fi
