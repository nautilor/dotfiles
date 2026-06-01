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

sync_git_repo() {
	local repo_url="$1"
	local destination="$2"
	local label="$3"

	if [[ -d "$destination/.git" ]]; then
		info "Updating $label in $destination"
		git -C "$destination" pull --ff-only
	elif [[ -e "$destination" ]]; then
		die "$label destination already exists and is not a git repository: $destination"
	else
		info "Cloning $label into $destination"
		git clone --depth 1 "$repo_url" "$destination"
	fi
}

install_kvantum_theme() {
	local repo_url="$1"
	local theme_name="$2"
	local destination="$HOME/.config/Kvantum/$theme_name"
	local tmp_dir
	local kvconfig_file
	local svg_file

	tmp_dir=$(mktemp -d)
	info "Installing Kvantum theme $theme_name from $repo_url"
	git clone --depth 1 "$repo_url" "$tmp_dir/repo"

	kvconfig_file=$(find "$tmp_dir/repo" -maxdepth 3 -type f -name '*.kvconfig' | head -n 1)
	svg_file=$(find "$tmp_dir/repo" -maxdepth 3 -type f -name '*.svg' | head -n 1)

	[[ -n "$kvconfig_file" ]] || die "No Kvantum .kvconfig file found in $repo_url"
	[[ -n "$svg_file" ]] || die "No Kvantum .svg file found in $repo_url"

	mkdir -p "$destination"
	install -Dm644 "$kvconfig_file" "$destination/$theme_name.kvconfig"
	install -Dm644 "$svg_file" "$destination/$theme_name.svg"
	rm -rf "$tmp_dir"

	success "Kvantum theme installed successfully."
}

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
KVANTUM_THEME_REPO="https://github.com/nautilor/tokyo-dark-colloid-kvantum"
KVANTUM_THEME_NAME="palette-tokyo-dark"
KVANTUN_THEME_DESTINATION_FOLDER="$HOME/.config/Kvantum/$KVANTUM_THEME_NAME"

sync_git_repo "$GTK_THEME_REPO" "$GTK_DESTINATION_FOLDER" "GTK theme"
sync_git_repo "$GTK_ICONS_REPO" "$GTK_ICONS_DESTINATION_FOLDER" "icon theme"
install_kvantum_theme "$KVANTUM_THEME_REPO" "$KVANTUM_THEME_NAME"

if [[ -d "$GTK_DESTINATION_FOLDER" && -d "$GTK_ICONS_DESTINATION_FOLDER" && -d "$KVANTUN_THEME_DESTINATION_FOLDER" ]]; then
		success "GTK theme, icon theme, and Kvantum theme installed successfully."
else
		die "Failed to install the GTK theme, icon theme, or Kvantum theme."
fi

# Set the GTK theme and icons
gsettings set org.gnome.desktop.interface gtk-theme "Tokyo Dark Colloid"
gsettings set org.gnome.desktop.interface icon-theme "Dracula"
