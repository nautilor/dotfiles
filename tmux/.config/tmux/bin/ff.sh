#!/usr/bin/env bash
#
# Fuzzy-pick a directory (via fd + fzf) and open it in a new tmux window.
#
set -uo pipefail

path="$(fd -t d . "$HOME" "$HOME/.config" | fzf --prompt='directory: ')"

# If in a tmux session, open a new tmux window with the selected directory.
if [[ -n "${TMUX:-}" && -n "$path" ]]; then
	tmux new-window -c "$path"
fi
