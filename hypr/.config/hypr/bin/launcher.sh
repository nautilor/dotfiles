#!/usr/bin/env bash

# Check if quickshell is running
pgrep -x "quickshell" > /dev/null
if [ $? -ne 0 ]; then
	quickshell & disown
	sleep 0.5
fi

quickshell ipc call launcher toggle

if [ $? -ne 0 ]; then
		notify-send -i "error" "Quickshell Error" "Failed to launch Quickshell with the specified configuration."
		exit 1
fi
