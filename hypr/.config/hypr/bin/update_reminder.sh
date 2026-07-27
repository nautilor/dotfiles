#!/usr/bin/env bash

# wait for quickshell to run
while ! pgrep -f "quickshell" > /dev/null; do
		sleep 3
done

sleep 3

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/update-reminder.last"

mkdir -p "$STATE_DIR"

NOW=$(date +%s)
WEEK=$((7 * 24 * 60 * 60))

if [[ -f "$STATE_FILE" ]]; then
    LAST=$(cat "$STATE_FILE")
else
    LAST=0
fi

if (( NOW - LAST >= WEEK )); then
    notify-send \
			  -i "$HOME/.config/hypr/assets/logo.png" \
        "NixOS Update Reminder" \
				"It's been a week since your last update."


    echo "$NOW" > "$STATE_FILE"
fi
