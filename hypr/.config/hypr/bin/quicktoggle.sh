#!/usr/bin/env bash
#
# Ensure quickshell is running, then toggle a given IPC module.
#
set -uo pipefail

# Check if quickshell is running; start it if not.
if ! pgrep -f "quickshell" > /dev/null; then
	quickshell & disown
	sleep 0.5
fi

if [[ $# -eq 0 ]]; then
	echo "No arguments provided. Usage: $0 <config_file>" >&2
	exit 1
fi

module="$1"

if ! quickshell ipc call "$module" toggle; then
	notify-send -i "error" "Quickshell Error" "Failed to launch quickshell module ${module}."
	exit 1
fi
