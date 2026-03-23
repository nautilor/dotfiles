#!/usr/bin/env bash

if ! command -v clipse &> /dev/null || ! command -v clipse-gui &> /dev/null || ! command -v wl-copy &> /dev/null; then
		notify-send -i "error" "Clipboard Manager" "Required dependencies are not installed!"
		echo "Please install 'cliphist', 'rofi', and 'wl-copy' to use this script."
		exit 1
fi

toggle_clipboard() {
	# Check if clipboard-manager.py is already running
	# running using python ~/.config/hypr/bin/cli
	if pgrep -x "clipse-gui" > /dev/null; then
		# If running, kill the process
		pkill -x "clipse-gui"
	else
		# If not running, start the process
		clipse-gui &
	fi
}

clear_clipboard() {
	clipse -clear-all
	notify-send -i "clipboard" "Clipboard Cleared" "All clipboard history has been cleared."
}


if [ "$@" == "clear" ]; then
	clear_clipboard
else
	toggle_clipboard
fi
