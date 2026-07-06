#!/usr/bin/env bash
#
# Clipboard manager wrapper: checks dependencies, supports clearing history.
#
set -euo pipefail

if ! command -v clipse &> /dev/null || ! command -v wl-copy &> /dev/null; then
	notify-send -i "error" "Clipboard Manager" "Required dependencies are not installed!"
	exit 1
fi

if [[ "${1:-}" == "clear" ]]; then
	clipse -clear-all
	notify-send -i "clipboard" "Clipboard Cleared" "All clipboard history has been cleared."
fi
