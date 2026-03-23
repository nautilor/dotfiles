#!/usr/bin/env bash

# check if fzf is installed
if ! command -v fzf &> /dev/null
then
		echo "fzf could not be found. Please install fzf to use this menu."
		exit 1
fi

if ! command -v kitty &> /dev/null
then
		echo "Kitty terminal could not be found. Please install Kitty to use this menu."
		exit 1
fi

# if argument is passed, run in indipendent mode

if [ "$1" == "--indipendent" ]; then
		INDIPENDENT="true"
else
		INDIPENDENT="false"
fi

BASE_PATH="$HOME/.config/fzf_utils/bin"
SOURCE_FILE="$HOME/.config/fzf_utils/source.sh"
FZF_COMMAND='fzf --prompt="Select an option: " --border'

mkdir -p "$BASE_PATH"
touch "$SOURCE_FILE"

OPTIONS=`ls $BASE_PATH`

if [ "$INDIPENDENT" = "false" ]; then
	OPTIONS=$(echo "$OPTIONS" | $FZF_COMMAND)
else
	 # SPAWN a terminal and run it
	 kitty --class fzf_utils -e bash -c "source $BASE_PATH/../source.sh && echo \"$OPTIONS\" | $FZF_COMMAND | xargs -I {} sh -c \"$BASE_PATH/{}\""
fi


if [ -n "$SELECTED_OPTION" ]; then
		"$BASE_PATH/$SELECTED_OPTION"
fi
