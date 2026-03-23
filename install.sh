#!/usr/bin/env bash
# =============================================================================
# Arch Linux install script for edoardo's dotfiles
#
# Usage:
#   ./install.sh              # install packages + stow dotfiles (default)
#   ./install.sh --packages   # only install packages (pacman + AUR)
#   ./install.sh --stow       # only stow dotfiles
#   ./install.sh --help       # show this help
#
# Package lists are defined in packages.conf (same directory as this script).
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
section() { echo -e "\n${BOLD}${CYAN}────────────────────────────────────────${RESET}"; \
            echo -e "${BOLD}$*${RESET}"; \
            echo -e "${BOLD}${CYAN}────────────────────────────────────────${RESET}"; }
die()     { echo -e "${RED}${BOLD}error: ${RESET}$*" >&2; exit 1; }

# =============================================================================
# Resolve dotfiles directory and packages.conf
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_CONF="$DOTFILES_DIR/packages.conf"

[[ -f "$PACKAGES_CONF" ]] || die "packages.conf not found at $PACKAGES_CONF"

# =============================================================================
# Parse packages.conf
# Supports multiple [pacman] / [aur] / [stow] sections and inline # comments.
# =============================================================================

parse_packages() {
    local section=""
    local -n _pacman=$1
    local -n _aur=$2
    local -n _stow=$3

    while IFS= read -r raw_line; do
        # Strip inline comments and leading/trailing whitespace
        local line
        line="${raw_line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -z "$line" ]] && continue

        if [[ "$line" =~ ^\[([a-zA-Z]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi

        case "$section" in
            pacman) _pacman+=("$line") ;;
            aur)    _aur+=("$line")    ;;
            stow)   _stow+=("$line")   ;;
        esac
    done < "$PACKAGES_CONF"
}

# =============================================================================
# Helpers
# =============================================================================

cmd_exists() { command -v "$1" &>/dev/null; }

pacman_install() {
    [[ ${#@} -eq 0 ]] && return
    info "pacman -S ${*}"
    sudo pacman -S --needed --noconfirm "$@"
}

yay_install() {
    [[ ${#@} -eq 0 ]] && return
    info "yay -S ${*}"
    yay -S --needed --noconfirm "$@"
}

ensure_yay() {
    if cmd_exists yay; then
        success "yay already installed"
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
# Modes
# =============================================================================

do_packages() {
    local -a pacman_pkgs=() aur_pkgs=() stow_pkgs=()
    parse_packages pacman_pkgs aur_pkgs stow_pkgs

    section "Installing packages from $PACKAGES_CONF"
    info "${#pacman_pkgs[@]} pacman packages, ${#aur_pkgs[@]} AUR packages"

    ensure_yay

    section "pacman packages"
    pacman_install "${pacman_pkgs[@]}"

    section "AUR packages"
    yay_install "${aur_pkgs[@]}"

    # Set zsh as default shell if not already
    if [[ "$(basename "$SHELL")" != "zsh" ]]; then
        info "Setting zsh as default shell..."
        chsh -s "$(command -v zsh)"
        success "Default shell set to zsh (takes effect on next login)"
    fi

    # Initialise rustup stable toolchain
    if cmd_exists rustup && ! rustup toolchain list 2>/dev/null | grep -q stable; then
        info "Installing stable Rust toolchain via rustup..."
        rustup default stable
    fi

    success "Package installation complete"
}

do_extra() {
		# Run extra configuration steps that don't fit into stow or package installation
		# (e.g. configuring tpm, adding hyprland plugins, etc.)
		source "$DOTFILES_DIR/extra.sh"
}

do_stow() {
    local -a pacman_pkgs=() aur_pkgs=() stow_pkgs=()
    parse_packages pacman_pkgs aur_pkgs stow_pkgs

    cmd_exists stow || die "'stow' is not installed. Run './install.sh --packages' first."

    section "Stowing dotfiles from $DOTFILES_DIR"
    info "Packages: ${stow_pkgs[*]}"

    cd "$DOTFILES_DIR"
    stow -v "${stow_pkgs[@]}"
    success "Dotfiles stowed"
}

print_post_install_notes() {
    section "Post-install notes"
    echo -e "
${BOLD}Manual steps still required:${RESET}

  ${CYAN}1. Tmux Plugin Manager (tpm)${RESET}
     Inside tmux: prefix + I  (to install plugins)

  ${CYAN}2. Neovim LSPs & formatters${RESET}
     Open nvim and run:
       :MasonInstall pyright ts_ls eslint clangd lua_ls \\
         rust_analyzer jdtls dartls qmlls black prettierd

  ${CYAN}3. Flutter / Android SDK${RESET}
     Install Flutter manually to ~/.local/flutter/
     https://docs.flutter.dev/get-started/install/linux

  ${CYAN}4. Spicetify${RESET}
     curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
"
}

print_help() {
    echo -e "${BOLD}Usage:${RESET} $(basename "$0") [--packages | --stow | --all | --help]

  ${CYAN}--packages${RESET}   Install pacman + AUR packages defined in packages.conf
  ${CYAN}--stow${RESET}       Stow dotfiles only (symlink into \$HOME via GNU Stow)
  ${CYAN}--all${RESET}        Packages + stow + post-install notes (default)
  ${CYAN}--help${RESET}       Show this message

Edit ${BOLD}packages.conf${RESET} to add/remove packages or change which
directories get stowed without touching this script.
"
}

# =============================================================================
# Argument handling
# =============================================================================

MODE="${1:---all}"

case "$MODE" in
    --packages|-p)
        do_packages
        ;;
    --stow|-s)
        do_stow
        ;;
    --all|-a|"")
        do_packages
        do_stow
				do_extra
        print_post_install_notes
        ;;
    --help|-h)
        print_help
        exit 0
        ;;
    *)
        die "Unknown option '$MODE'. Run '$(basename "$0") --help' for usage."
        ;;
esac
