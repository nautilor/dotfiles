#!/usr/bin/env bash

set -euo pipefail

mapfile -t SOURCES < <(pactl list short sources | awk '!/monitor/ {print $1}')

ANY_UNMUTED=false
for id in "${SOURCES[@]}"; do
	if [[ "$(pactl get-source-mute "$id" | awk '{print $2}')" == "no" ]]; then
		ANY_UNMUTED=true
		break
	fi
done

if $ANY_UNMUTED; then
	TARGET=1
	MESSAGE="Microphone muted"
	ICON="microphone-sensitivity-muted"
else
	TARGET=0
	MESSAGE="Microphone unmuted"
	ICON="microphone-sensitivity-high"
fi

for id in "${SOURCES[@]}"; do
	pactl set-source-mute "$id" "$TARGET"
done

swayosd-client \
	--custom-message="$MESSAGE" \
	--custom-icon="$ICON"
