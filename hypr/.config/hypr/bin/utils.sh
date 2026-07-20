#!/usr/bin/env bash
#
# fzf-based menu (in a Kitty window) for scripts in ~/.config/fzf_utils/bin
#
set -euo pipefail

if ! command -v fzf &> /dev/null; then
	echo "fzf could not be found. Please install fzf to use this menu." >&2
	exit 1
fi

if ! command -v kitty &> /dev/null; then
	echo "Kitty terminal could not be found. Please install Kitty to use this menu." >&2
	exit 1
fi

readonly BASE_PATH="${HOME}/.config/utils/bin"
readonly SOURCE_FILE="${HOME}/.config/utils/source.sh"

mkdir -p "$BASE_PATH"
touch "$SOURCE_FILE"

kitty --class fzf_utils -e env BASE_PATH="$BASE_PATH" SOURCE_FILE="$SOURCE_FILE" bash -c "source \"\$SOURCE_FILE\"; selected=\$(find \"\$BASE_PATH\" -maxdepth 1 -type f -executable -printf '%f\n' | fzf --prompt='Select an option: ' --border); if [[ -n \"\$selected\" ]]; then \"\$BASE_PATH/\$selected\"; fi"
