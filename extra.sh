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


# ==============================================================================
# Enable NetworkManager and Bluetooth services
# ==============================================================================
if command -v systemctl &> /dev/null; then
	sudo systemctl enable --now NetworkManager
	sudo systemctl enable --now Bluetooth
fi

# ==============================================================================
# Reload fonts configurations
# ==============================================================================
if command -v fc-cache &> /dev/null; then
	fc-cache -f -v
fi

# =============================================================================
# Download and install the GTK theme and icons
# =============================================================================
GTK_THEME_REPO="https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme"
GTK_THEME_TEMP_DIR="/tmp/tokyonight-gtk-theme"
GTK_ICON_EXTRACT_DIR="$HOME/.local/share/icons/"

# Download and install the GTK theme and icons
git clone "$GTK_THEME_REPO" "$GTK_THEME_TEMP_DIR"
cd "$GTK_THEME_TEMP_DIR/themes" || exit
./install.sh --tweaks storm macos -l -d ~/.themes
mkdir -p "$GTK_ICON_EXTRACT_DIR"
cd "$GTK_THEME_TEMP_DIR/icons" || exit
cp -R * "$GTK_ICON_EXTRACT_DIR"

# Clean up temporary directories
rm -rf "$GTK_THEME_TEMP_DIR"

# Set the GTK theme and icons
gsettings set org.gnome.desktop.interface gtk-theme "Tokyonight-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Tokyonight-Dark"
