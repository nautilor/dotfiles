#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}  ✓ ${RESET}$*"; }
warn()    { echo -e "${YELLOW}${BOLD}  ! ${RESET}$*"; }
section() { echo -e "\n${BOLD}${CYAN}────────────────────────────────────────${RESET}"; \
            echo -e "${BOLD}$*${RESET}"; \
            echo -e "${BOLD}${CYAN}────────────────────────────────────────${RESET}"; }
die()     { echo -e "${RED}${BOLD}error: ${RESET}$*" >&2; exit 1; }

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
GTK_THEME_REPO="https://github.com/nautilor/tokyo-dark-colloid"
GTK_DESTINATION_FOLDER="$HOME/.themes/Tokyo Dark Colloid"
GTK_ICONS_REPO="https://github.com/m4thewz/dracula-icons"
GTK_ICONS_DESTINATION_FOLDER="$HOME/.icons/dracula-icons"

git clone "$GTK_THEME_REPO" "$GTK_DESTINATION_FOLDER"
git clone "$GTK_ICONS_REPO" "$GTK_ICONS_DESTINATION_FOLDER"

if [[ -d "$GTK_DESTINATION_FOLDER" && -d "$GTK_ICONS_DESTINATION_FOLDER" ]]; then
		success "GTK theme and icons downloaded and installed successfully."
else
		die "Failed to download and install the GTK theme and icons."
fi

# Set the GTK theme and icons
gsettings set org.gnome.desktop.interface gtk-theme "Tokyo Dark Colloid"
gsettings set org.gnome.desktop.interface icon-theme "Dracula"
