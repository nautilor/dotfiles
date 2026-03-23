#!/usr/bin/env bash

hasFullscreen=$(hyprctl activeworkspace -j | jq -r '.hasfullscreen')

if [[ "$hasFullscreen" == "true" ]]; then
	echo '{ "text": "󰄶", "class": "workspace_mode_fullscreen" }'
else
		echo '{ "text": "󰙀", "class": "workspace_mode_tiling" }'
fi

