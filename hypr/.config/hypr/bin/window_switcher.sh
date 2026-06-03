#!/usr/bin/env bash

set -euo pipefail

if ! pgrep -f "quickshell" >/dev/null 2>&1; then
    quickshell >/dev/null 2>&1 &
    disown
    sleep 0.5
fi

if ! qs ipc call windowSwitcher toggle; then
    notify-send -i "error" "Quickshell Error" "Failed to open window switcher."
    exit 1
fi
