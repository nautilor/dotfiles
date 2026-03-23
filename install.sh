#!/usr/bin/env bash
# =============================================================================
# Arch Linux install script for edoardo's dotfiles
# Usage: bash install.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}  ✓ ${RESET}$*"; }
warn()    { echo -e "${YELLOW}${BOLD}  ! ${RESET}$*"; }
section() { echo -e "\n${BOLD}${CYAN}────────────────────────────────────────${RESET}"; echo -e "${BOLD}$*${RESET}"; echo -e "${BOLD}${CYAN}────────────────────────────────────────${RESET}"; }

# =============================================================================
# Helpers
# =============================================================================

pacman_install() {
    info "pacman: $*"
    sudo pacman -S --needed --noconfirm "$@"
}

yay_install() {
    info "yay (AUR): $*"
    yay -S --needed --noconfirm "$@"
}

cmd_exists() { command -v "$1" &>/dev/null; }

# =============================================================================
# Ensure yay is available
# =============================================================================

ensure_yay() {
    if cmd_exists yay; then
        success "yay is already installed"
        return
    fi

    warn "yay not found — building from AUR..."
    pacman_install git base-devel
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    success "yay installed"
}

# =============================================================================
# Main
# =============================================================================

section "Hyprland dotfiles — Arch Linux package installer"

ensure_yay

# ── Wayland compositor & ecosystem ──────────────────────────────────────────
section "Compositor & Hyprland ecosystem"
pacman_install \
    hyprland \
    hyprlock \
    hypridle \
    hyprsunset \
    hyprpicker \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    polkit-gnome

# ── Status bar, notifications & OSD ─────────────────────────────────────────
section "Status bar, notifications & OSD"
pacman_install \
    waybar

yay_install \
    swaync \
    swayosd

# ── Wallpaper ────────────────────────────────────────────────────────────────
section "Wallpaper daemon"
yay_install swww

# ── App launcher & desktop overlays ─────────────────────────────────────────
section "App launcher & desktop overlays"
pacman_install \
    rofi-wayland

yay_install \
    quickshell-git

# ── Screenshot, recording & color picker ────────────────────────────────────
section "Screenshot, recording & color picker"
pacman_install \
    grim \
    slurp \
    wf-recorder \
    imagemagick

yay_install \
    hyprshot \
    satty

# ── Clipboard ────────────────────────────────────────────────────────────────
section "Clipboard"
pacman_install \
    wl-clipboard

yay_install \
    clipse \
    wl-clip-persist

# ── Audio ────────────────────────────────────────────────────────────────────
section "Audio (PipeWire)"
pacman_install \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber

yay_install \
    wiremix

# ── Networking & Bluetooth ───────────────────────────────────────────────────
section "Networking & Bluetooth"
pacman_install \
    networkmanager \
    network-manager-applet \
    blueman \
    bluez \
    bluez-utils

yay_install \
    bluetui

# ── System control ───────────────────────────────────────────────────────────
section "System control (brightness, media, notifications)"
pacman_install \
    playerctl \
    brightnessctl \
    libnotify

# ── Qt theming (required by environment.conf) ────────────────────────────────
section "Qt theming"
pacman_install \
    qt5ct \
    kvantum \
    kvantum-qt5

# ── Cursor theme (HYPRCURSOR_THEME = Catppuccin Mocha Dark) ──────────────────
section "Cursor theme"
yay_install \
    hyprcursor-catppuccin-mocha-dark-git

# ── Terminal & multiplexer ───────────────────────────────────────────────────
section "Terminal & multiplexer"
pacman_install \
    kitty \
    tmux

# ── Shell ────────────────────────────────────────────────────────────────────
section "Zsh shell"
pacman_install zsh

# Set zsh as default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    success "Default shell changed to zsh (takes effect on next login)"
fi

# ── CLI utilities ────────────────────────────────────────────────────────────
section "CLI utilities"
pacman_install \
    fzf \
    fd \
    bat \
    eza \
    lazygit \
    yazi \
    zathura \
    zathura-pdf-mupdf \
    git \
    jq

# ── Spotify ──────────────────────────────────────────────────────────────────
section "Spotify"
yay_install spotify-launcher

# ── Neovim ───────────────────────────────────────────────────────────────────
section "Neovim"
pacman_install neovim

# ── Development runtimes (for Neovim LSPs & formatters) ─────────────────────
section "Development runtimes"
pacman_install \
    nodejs \
    npm \
    python \
    python-pip \
    rustup \
    clang \
    jdk21-openjdk \
    go

# Install a stable Rust toolchain (needed for rust-analyzer via Mason)
if cmd_exists rustup; then
    info "Initializing rustup default toolchain..."
    rustup default stable || true
fi

# Qt6 tools — provides qmlls (QML language server)
pacman_install qt6-tools

# ── Fonts ────────────────────────────────────────────────────────────────────
section "Fonts"
pacman_install \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
    ttf-roboto

# SF Pro (used in hyprlock clock) — Apple font, install manually or via AUR
warn "SF Pro Rounded Bold (hyprlock clock font) must be installed manually."
warn "  AUR option: yay -S apple-fonts"

# ── Stow dotfiles ─────────────────────────────────────────────────────────────
section "Stow dotfiles"
pacman_install stow

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Stowing all packages from $DOTFILES_DIR ..."
cd "$DOTFILES_DIR"
stow --no-folding -v hypr kitty nvim tmux zsh waybar swaync swayosd rofi \
    lazygit yazi zathura ideavim fd fzutils quickshell

success "All packages stowed."

# ── Post-install notes ────────────────────────────────────────────────────────
section "Post-install notes"

echo -e "
${BOLD}Manual steps still required:${RESET}

  ${CYAN}1. Tmux Plugin Manager (tpm)${RESET}
     git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
     Then inside tmux: prefix + I  (to install plugins)

  ${CYAN}2. Neovim LSPs & formatters${RESET}
     Open nvim and run:  :MasonInstall pyright ts_ls eslint clangd lua_ls \\
       rust_analyzer jdtls dartls qmlls black prettierd

  ${CYAN}3. Zinit (Zsh plugin manager)${RESET}
     Auto-installed on first zsh launch via .zshrc.

  ${CYAN}4. Powerlevel10k theme${RESET}
     Installed automatically by zinit on first zsh launch.
     Run  p10k configure  to set up the prompt.

  ${CYAN}5. Flutter / Android SDK${RESET}
     Install Flutter manually to ~/.local/flutter/
     https://docs.flutter.dev/get-started/install/linux

  ${CYAN}6. Spicetify${RESET}
     curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh

  ${CYAN}7. Enable services${RESET}
     sudo systemctl enable --now NetworkManager
     sudo systemctl enable --now bluetooth

  ${CYAN}8. Hyprland plugins${RESET}
     hyprpm update  (run after first Hyprland launch)
"
success "Done! Log out and back in (or reboot) to start Hyprland."
