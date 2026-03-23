#!/usr/bin/env bash

if ! command -v swaync &> /dev/null
then
		echo "swaync could not be found. Please install it first."
		exit 1
fi

if pgrep -x "swaync" > /dev/null
then
	pkill -x swaync
fi

notify-send "Notification Daemon" "Notification daemon restarted" -i "dialog-information"
