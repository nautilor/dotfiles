#!/usr/bin/env bash

# if no argument is provided, quit

if [ -z "$1" ]; then
		echo "Usage: $0 <classname1>||<classname2>"
		echo "if multiple classnames are provided, the first one that matches will be focused"
		exit 1
fi

CLASSNAME="$1"

# check if the classname contains "||", if it does, split it into an array
if [[ "$CLASSNAME" == *"||"* ]]; then
		IFS='||' read -ra CLASSNAMES <<< "$CLASSNAME"
else
		CLASSNAMES=("$CLASSNAME")
fi

# loop through the classnames and focus the first one that matches
for CLASSNAME in "${CLASSNAMES[@]}"; do
		CLASSNAME=$(echo "$CLASSNAME" | xargs)
		address=$(hyprctl -j clients | jq -r ".[] | select(.class == \"$CLASSNAME\") | .address")
		# if one or more windows match the classname, focus the first one and exit
		if [ -n "$address" ]; then
				address=$(echo "$address" | head -n 1)
				hyprctl dispatch focuswindow address:"$address"
				exit 0
		fi
done
