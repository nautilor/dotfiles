#!/usr/bin/env bash

# ==============================================================================
# Configure tpm (tmux plugin manager) to use a custom plugins directory.
# ==============================================================================
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi


# ==============================================================================
# Add hyprpm plugins
# ==============================================================================
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprexpo


# ==============================================================================
# Create ~/.ssh folder with 700 permissions if it doesn't exist.
# ==============================================================================
if [[ ! -d "$HOME/.ssh" ]]; then
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"
fi

# ==============================================================================
# Create ~/.obsidian/Notes folder if it doesn't exist.
# ==============================================================================
if [[ ! -d "$HOME/.obsidian/Notes" ]]; then
	mkdir -p "$HOME/.obsidian/Notes"
fi
