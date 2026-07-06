#!/usr/bin/env bash
#
# Open (or attach to) a per-directory Claude tmux session in a popup.
#
set -uo pipefail

if [[ -z "${1:-}" ]]; then
	echo "Usage: $0 <path>" >&2
	exit 1
fi

current_path="$1"
session="$(printf '%s' "claude-${current_path}" | md5sum | cut -c1-5)"
current_session="$(tmux display-message -p '#S' 2>/dev/null || true)"

if ! tmux has-session -t "$session" 2>/dev/null; then
	tmux new-session -d -s "$session" -c "#{pane_current_path}" "claude"
	tmux popup -w80% -h80% -xC -yC -E "tmux attach-session -t $session"
else
	if [[ "$current_session" == "$session" ]]; then
		tmux detach-client
	else
		tmux popup -w80% -h80% -E "tmux attach-session -t $session"
	fi
fi
