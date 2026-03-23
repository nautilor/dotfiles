# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Everything is themed around **Tokyo Night** (Night variant).

## Setup

```bash
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles

# Stow individual packages
stow hypr kitty nvim tmux zsh waybar swaync swayosd rofi \
     lazygit yazi zathura ideavim fd fzutils quickshell
```

Each top-level directory is a Stow package. Running `stow <package>` creates
symlinks from the package contents into `$HOME`, mirroring the directory
structure inside the package (e.g. `hypr/.config/hypr/` → `~/.config/hypr/`).

---

## Packages

### `hypr` — Hyprland compositor

Full Wayland desktop environment built on [Hyprland](https://hyprland.org/).

**Config layout** (`~/.config/hypr/`):

| File / Directory | Purpose |
|---|---|
| `hyprland.conf` | Entry point; sources all sub-configs |
| `config/autostart.conf` | Startup apps (waybar, swaync, hypridle, quickshell, clipse…) |
| `config/binding.conf` | Keybindings (Super-based, vim-style navigation) |
| `config/animation.conf` | Window animations |
| `config/decoration.conf` | Blur, rounding, shadows |
| `config/input.conf` | Keyboard / touchpad settings |
| `config/monitor.conf` | Monitor layout |
| `config/workspace.conf` | Workspace rules |
| `config/rule.conf` | Window rules |
| `config/general.conf` | Gaps, border widths |
| `config/environment.conf` | Env vars (Wayland, XDG, GPU) |
| `config/permission.conf` | Hyprland security rules |
| `hypridle.conf` | Idle management: dim → lock (4 min) → DPMS off (5 min) → suspend (30 min) |
| `hyprlock.conf` | Lock screen with custom wallpaper, blurred bg, pink time display |
| `hyprsunset.conf` | Blue-light filter |
| `shaders/grayscale.frag` | GLSL shader for grayscale mode |
| `assets/` | Wallpapers and lockscreen image |
| `bin/` | Helper scripts (see below) |

**Helper scripts** (`bin/`):

| Script | What it does |
|---|---|
| `wallpaper.sh` | Sets / rotates wallpapers |
| `screenshot.sh` | Region / fullscreen screenshots |
| `recorder.sh` | Screen recording toggle |
| `colorpicker.sh` | Picks a color to clipboard or editor |
| `powermenu.sh` | Rofi power menu (shutdown / reboot / suspend / lock) |
| `launcher.sh` | App launcher via Rofi |
| `focus_mode.sh` | Toggle focus / Zen mode (grayscale + waybar hide) |
| `focus_by_class.sh` | Jump to a window by WM class |
| `floating.sh` | Toggle floating + center for the active window |
| `clipboard.sh` | Open `clipse` clipboard history picker |
| `caffeine.sh` | Prevent screen lock (inhibit idle) |
| `hints.sh` | Show keybinding cheatsheet overlay |
| `battery_info.sh` | Battery notification daemon |
| `grayscale.sh` | Toggle grayscale shader |
| `workspace_focus` / `workspace_move` | Named-workspace focus/move (Q W E R T) |
| `rofi_sessions` | Session switcher via Rofi |
| `xdg-portal-restart.sh` | Restart XDG desktop portal on login |

**Key bindings (highlights):**

| Binding | Action |
|---|---|
| `Super + Return` | Open Kitty |
| `Super + D` | App launcher |
| `Super + Shift+D` | Rofi run menu |
| `Super + V` | Clipboard history |
| `Super + Shift+S` | Screenshot |
| `Super + Shift+M` | Lock screen |
| `Super + H/J/K/L` | Move focus (vim-style) |
| `Super + Shift+H/J/K/L` | Move window |
| `Super + Ctrl+H/J/K/L` | Resize window |
| `Super + Q/W/E/R/T` | Switch to named workspace |
| `Super + B` | Toggle focus mode |
| `Super + F11` | Color picker |
| `Super + [/]` | Volume down/up |
| `Super + ,/.` | Brightness down/up |

**Dependencies:** `hyprpm`, `hypridle`, `hyprlock`, `hyprsunset`, `waybar`,
`swaync`, `swayosd`, `quickshell`, `rofi`, `kitty`, `clipse`, `wl-clip-persist`,
`nm-applet`, `playerctl`, `brightnessctl`, `polkit-gnome`, `spotify-launcher`

---

### `nvim` — Neovim

Full-featured Neovim setup managed by [lazy.nvim](https://github.com/folke/lazy.nvim).
Config namespace: `shadow`.

**Plugins:**

| Plugin | Purpose |
|---|---|
| `tokyonight.nvim` | Colorscheme (night, transparent bg) |
| `snacks.nvim` | Dashboard, file picker/explorer, indent guides, zen mode, scroll, words, statuscolumn |
| `blink.cmp` | Completion (LSP + path + buffer, super-tab preset) |
| `nvim-lspconfig` + `mason.nvim` | LSP: pyright, ts_ls, eslint, clangd, lua_ls, rust_analyzer, dartls, qmlls |
| `nvim-jdtls` | Java LSP with debug adapter and test bundles |
| `conform.nvim` | Format on save: black (Python), prettierd/prettier (JS/TS/HTML/CSS/JSON) |
| `nvim-treesitter` | Syntax highlighting & parsing |
| `lualine.nvim` | Status line |
| `copilot.vim` | GitHub Copilot inline suggestions |
| `lazygit.nvim` | Lazygit inside Neovim |
| `toggleterm.nvim` | Terminal inside Neovim |
| `markview.nvim` | Rendered Markdown preview |
| `obsidian.nvim` | Obsidian vault integration (`~/.obsidian/Notes`) |
| `nvim-autopairs` | Auto-close brackets/quotes |
| `nvim-ts-autotag` | Auto-close/rename HTML tags |
| `nvim-colorizer` | Inline color previews |
| `multicursor.nvim` | Multiple cursors |
| `mini.move` | Move lines/blocks with Alt+arrows |
| `timber.nvim` | Smart log statement insertion |
| `todo-comments.nvim` | Highlight TODO/FIXME/etc. |
| `inline-diagnostic` | Inline diagnostic messages |
| `vscode-diff` | Git diff view similar to VS Code |

**Key bindings (highlights):**

| Binding | Action |
|---|---|
| `Space` | Leader key |
| `Ctrl+S` | Save |
| `jj` | Exit insert mode |
| `Tab` / `Shift+Tab` | Next/prev buffer |
| `ss` / `sv` | Vertical / horizontal split |
| `sd` | Close window/buffer |
| `Ctrl+/` | Comment line/selection |
| `Ctrl+Y` / `Ctrl+P` | System clipboard yank/paste |
| `Ctrl+J` | Next diagnostic |
| `Space+/` | Clear search highlight |
| `Space+gd` | Git diff current file |
| `Space+bd` | Delete buffer |

---

### `zsh` — Zsh shell

Oh My Zsh setup with the `fluzz` theme.

**Plugins:** `git`, `zsh-sdkman`, `ssh-agent`, `zsh-syntax-highlighting`

**Environment setup:**
- `EDITOR=nvim`
- Android SDK, Go, Flutter paths
- JDTLS Lombok agent for Java LSP
- tmux `bin/` on `$PATH`
- Spicetify on `$PATH`

**FZF integration:**
- `Ctrl+T` previews directories with `eza --tree`
- Tokyo Night colors applied globally
- `_fzf_comprun` for context-aware previews

**Aliases:**

| Alias | Command |
|---|---|
| `v` / `vim` | nvim |
| `l` / `ls` / `lr` | eza |
| `ff` | fuzzy `cd` via `fd` |
| `lg` | lazygit |
| `y` | yazi |
| `ta` | `tmux attach` |
| `t` | attach/create `main` session |

**Functions:**

| Function | Purpose |
|---|---|
| `ff` | Fuzzy jump to any directory under `~` or `~/.config` |
| `mm` / `mf` / `mr` | Bookmark (`~/.marks`): mark / jump to / remove |
| `t` / `ms` | Tmux: smart attach / fuzzy session picker |
| `nd` / `nb` / `ns` | Run `dev` / `build` / `start` with auto-detected package manager |
| `ssh` | Wrapper that forces `TERM=xterm-256color` for compatibility |

**Key bindings:**

| Binding | Action |
|---|---|
| `Alt+F` | `switch-session.sh` (tmux session picker) |
| `Alt+O` | `ff` (fuzzy directory jump) |

---

### `tmux` — Tmux multiplexer

Prefix: `Ctrl+A` (changed from default).

**Plugins:** `tpm`, `tmux-mighty-scroll`

**Key bindings:**

| Binding | Action |
|---|---|
| `Alt+Q/W/E/R/T` | Select window 0–4 |
| `Alt+J` | New window (current path) |
| `Alt+N` / `Alt+M` | Next / previous window |
| `Alt+C` | Kill window |
| `Alt+F` | Fuzzy session picker popup |
| `Alt+Tab` / `Alt+Shift+Tab` | Switch sessions |
| `Alt+L` | Open lazygit in new window |
| `Alt+O` | `ff` directory picker popup |
| `Alt+P` | Open GitHub Copilot CLI |
| `Alt+S` / `Alt+V` | Split horizontally / vertically |
| `Alt+K` | Kill pane |
| `Alt+I` | Enter copy mode (vi keys) |
| `Alt+,` / `Alt+.` | Rename window / session |
| `Ctrl+R` | Reload config |

**Theme:** Tokyo Night Moon (`#1E2030` bg, `#D3869B` active, `#82AAFF` accents).
Status bar shows session name (left) and shortened current path (right).

---

### `kitty` — Terminal emulator

| Setting | Value |
|---|---|
| Font | JetBrainsMono Nerd Font, 12pt |
| Cursor | Block, no blink, trail effect |
| Opacity | 1 (dynamic opacity enabled) |
| Padding | 10px all sides |
| Colorscheme | Tokyo Night Night |
| Remote control | Enabled |
| Bell | Disabled |

---

### `waybar` — Status bar

Positioned at the bottom with 5px margin and 10px side margins.

**Left:** workspace layout toggle, Hyprland workspaces  
**Center:** active window title  
**Right:** pomodoro timer, caffeine toggle, network, bluetooth, microphone,
power profile, battery, clock, extras group (tray, privacy)

Custom scripts in `bin/`:
- `pomodoro` — pomodoro timer binary
- `caffeine.sh` — idle inhibit toggle status for the bar
- `workspace_layout.sh` — toggle workspace layout display

---

### `rofi` — Application launcher / menus

Three themes:

| File | Used for |
|---|---|
| `application.rasi` | App launcher (Material 3 Dark Grid style) |
| `menu.rasi` | General purpose menus |
| `power.rasi` | Power menu |

Icon theme: `oomox-TokyoNight-Moon`, Font: Roboto 11.

---

### `swaync` — Notification center

- Positioned top-right
- Notification timeout: 3s (critical: no auto-dismiss)
- Custom Tokyo Night CSS styling

---

### `swayosd` — Volume / brightness OSD

On-screen display for volume and brightness changes.
Styled with rounded pill shape, JetBrainsMono Nerd Font.

---

### `quickshell` — QML shell overlay

Two modules:

| Module | Purpose |
|---|---|
| `Launcher` | App launcher overlay |
| `RoundCorner` | Decorative rounded screen corners |

---

### `lazygit` — Git TUI

Themed with **Tokyo Night Moon** colors.  
Nerd Fonts v3 icons enabled.

---

### `yazi` — Terminal file manager

Tokyo Night (Catppuccin-inspired) theme applied via `theme.toml`.

---

### `zathura` — PDF viewer

Full Tokyo Night Night colorscheme:
- Dark background with light text
- Blue selection highlights
- Document recoloring enabled (dark mode for PDFs)

---

### `fd` — File finder

`ignore` file excludes `node_modules`, `.git`, `dist`, `build`, `target`
from all `fd` searches.

---

### `fzutils` — FZF utility scripts

Located at `~/.config/fzf_utils/`.

**`source.sh`** — Exports Tokyo Night FZF colors and `NEWT_COLORS` for `nmtui`.
Source this in your shell to apply colors.

**Scripts in `bin/`:**

| Script | Purpose |
|---|---|
| `manage_audio.sh` | FZF audio sink/source selector |
| `network_tool.sh` | FZF network manager interface |
| `select_bluetooth.sh` | FZF Bluetooth device selector |
| `kill_tray.sh` | Kill a tray application |
| `restart_network.sh` | Restart NetworkManager |
| `restart_notification.sh` | Restart SwayNC |
| `test_notification.sh` | Send a test notification |

These scripts are invoked from the Hyprland `fzf_utilities.sh` launcher.

---

### `ideavim` — IdeaVim for JetBrains IDEs

`.ideavimrc` provides a near-Neovim experience inside IntelliJ-based IDEs.

**Plugins:** `vim-highlightedyank`, `vim-commentary`, `NERDTree`

**Highlights:**

| Binding | Action |
|---|---|
| `Space` | Leader key |
| `ss` / `sv` | Split vertically / horizontally |
| `Ctrl+O` | Search everywhere |
| `Ctrl+F` | Find in path |
| `Ctrl+G` / `gd` | Go to declaration |
| `Tab` / `Shift+Tab` | Next / previous editor tab |
| `bd` | Close editor tab |
| `F2` / `Space+R` | Rename element |
| `Ctrl+Y` / `Ctrl+P` | System clipboard yank/paste |
| `Space+E` | NERDTree toggle |
| `Ctrl+Z` | Distraction-free mode |
| `Ctrl+T` | Terminal tool window |
| `Shift+Down/Up` | Move line(s) down/up |

---

## Dependencies summary

```
# Wayland / Desktop
hyprland hyprlock hypridle hyprsunset hyprpm
waybar swaync swayosd quickshell
rofi kitty clipse wl-clip-persist
nm-applet playerctl brightnessctl
polkit-gnome spotify-launcher

# Shell / CLI
zsh oh-my-zsh zsh-syntax-highlighting
tmux tpm fzf fd bat eza lazygit yazi zathura

# Editors
neovim
# Neovim LSPs (via Mason): pyright ts_ls eslint clangd lua_ls rust_analyzer jdtls dartls qmlls
# Neovim formatters (via Mason): black prettierd prettier

# Fonts
JetBrainsMono Nerd Font
"SF Pro Rounded Bold"  # lock screen clock
```
