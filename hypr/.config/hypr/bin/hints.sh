#!/usr/bin/env bash

# if missing add ~/.local/bin to PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
		export PATH="$HOME/.local/bin:$PATH"
fi

# Check if hints exists 
if `which hints &> /dev/null`; then
	# Run hints and check if it was successful
	if hints; then
		exit 0
	else
		# Notify user of failure
		notify-send "Hints generation failed" "An error occurred while generating hints."
	fi
else
		notify-send "hints command not found" "Please install hints to use this script."
fi
exit 1
