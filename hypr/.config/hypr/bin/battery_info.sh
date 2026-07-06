#!/usr/bin/env bash
#
# Notify when battery level drops to or below a critical threshold.
#
set -euo pipefail

readonly BATTERY_PATH="/sys/class/power_supply/BAT1/capacity"
readonly LOW_THRESHOLD=15
readonly CHECK_INTERVAL=120
readonly ALERT_INTERVAL=1200

while true; do
	bat_lvl=$(cat "$BATTERY_PATH")

	if (( bat_lvl <= LOW_THRESHOLD )); then
		notify-send --urgency=CRITICAL -i battery-caution-symbolic "Battery Low" "Level: ${bat_lvl}%"
		sleep "$ALERT_INTERVAL"
	else
		sleep "$CHECK_INTERVAL"
	fi
done
