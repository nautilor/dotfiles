# ─────────────────────────────────────────────
#  OH-MY-ZSH
# ─────────────────────────────────────────────

export ZSH="/home/edoardo/.oh-my-zsh"
ZSH_THEME="fluzz"
plugins=(git zsh-sdkman ssh-agent)

source $ZSH/oh-my-zsh.sh
source $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue,bold'


# ─────────────────────────────────────────────
#  ENVIRONMENT
# ─────────────────────────────────────────────

export EDITOR=nvim

# Android
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk

# Go
export GOPATH=$HOME/.go

# jdtls / Lombok
export JDTLS_JVM_ARGS="-javaagent:$HOME/.local/share/java/lombok.jar"


# ─────────────────────────────────────────────
#  PATH
# ─────────────────────────────────────────────

export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$HOME/.local/flutter/bin
export PATH=$PATH:$HOME/.local/bin:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.config/tmux/bin
export PATH=$PATH:/home/edoardo/.spicetify


# ─────────────────────────────────────────────
#  FZF
# ─────────────────────────────────────────────

export FZF_CTRL_T_OPTS="--preview 'eza --tree --color=always {} | head -200'"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'

eval "$(fzf --zsh)"

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \$' {}" "$@" ;;
    *)            fzf --preview 'bat -n --color=always --line-range :500 {}' "$@" ;;
  esac
}


# ─────────────────────────────────────────────
#  NMTUI COLORS
# ─────────────────────────────────────────────

export NEWT_COLORS='
root=#c0caf5,#1a1b26
roottext=#c0caf5
helpline=#7dcfff
border=#7aa2f7,#1a1b26
window=#c0caf5,#1a1b26
shadow=#c0caf5,#1a1b26
title=#bb9af7,#1a1b26
button=#1a1b26,#7aa2f7
actbutton=#1a1b26,#bb9af7
compactbutton=#c0caf5,#1a1b26
checkbox=#c0caf5,#1a1b26
actcheckbox=#1a1b26,#7dcfff
entry=#c0caf5,#1a1b26
label=#c0caf5,#1a1b26
listbox=#c0caf5,#1a1b26
actlistbox=#7aa2f7,#1a1b26
actsellistbox=#bb9af7,#1a1b26
'


# ─────────────────────────────────────────────
#  KEY BINDINGS
# ─────────────────────────────────────────────

bindkey -s '\ef' "switch-session.sh\n"
bindkey -s '\eo' "ff\n"


# ─────────────────────────────────────────────
#  ALIASES
# ─────────────────────────────────────────────

# Editors
alias vim=nvim
alias v=nvim

# Navigation
alias ff='cd $(fd -t d . ~ ~/.config | fzf --prompt="directory: ")'

# File listing
alias ls=eza
alias l=eza
alias lr="ls -R"

# Git
alias lg=lazygit

# Tmux
alias ta='tmux a'
alias tmux='tmux'

# Yazi
alias y=yazi


# ─────────────────────────────────────────────
#  FUNCTIONS — MARKS
# ─────────────────────────────────────────────

alias mfzf='cat ~/.marks | fzf --preview "eza -l --color=always {} | head -200"'

# Navigate to a marked directory
function mf() {
  dir=$(mfzf) || return
  cd "${dir/#\~/$HOME}"
}

# Unmark a directory
function mr() {
  dir=$(mfzf) || return
  sed -i "\|^${dir}$|d" ~/.marks
  echo "Unmarked $dir"
}

# Mark the current directory
function mm() {
  local current_dir=$(pwd)
  if [[ -f ~/.marks ]]; then
    if ! grep -Fxq "$current_dir" ~/.marks; then
      echo "$current_dir" >> ~/.marks
      echo "Marked $current_dir"
    else
      echo "Directory already marked" >&2
    fi
  else
    echo "$current_dir" > ~/.marks
    echo "Marked $current_dir"
  fi
}


# ─────────────────────────────────────────────
#  FUNCTIONS — TMUX
# ─────────────────────────────────────────────

# Attach to or create the main tmux session
function t() {
  [[ $(tmux ls 2>/dev/null | grep -E "^main:.*") ]] && tmux || tmux new -s main
}

# Fuzzy-attach to an existing tmux session
function ms() {
  local sessions session
  sessions=$(tmux ls 2>/dev/null | cut -d: -f1)
  session=$(echo "$sessions" | fzf) || return
  tmux attach-session -t "$session"
}


# ─────────────────────────────────────────────
#  FUNCTIONS — NODE / PACKAGE MANAGER DETECTION
# ─────────────────────────────────────────────

_detect_pm() {
  if   [[ -f pnpm-lock.yaml ]];  then echo pnpm
  elif [[ -f yarn.lock ]];       then echo yarn
  elif [[ -f bun.lockb ]];       then echo bun
  elif [[ -f expo.json ]];       then echo expo
  elif [[ -f deno.json ]];       then echo deno
  elif [[ -f package-lock.json ]]; then echo npm
  else echo npm
  fi
}

function nd() {
  [[ ! -f package.json ]] && echo "No package.json found" && return 1
  local pm=$(_detect_pm)
  case $pm in
    deno) deno run --allow-net --allow-read dev.ts ;;
    *)    $pm run dev ;;
  esac
}

function nb() {
  [[ ! -f package.json ]] && echo "No package.json found" && return 1
  local pm=$(_detect_pm)
  case $pm in
    deno) deno run --allow-net --allow-read build.ts ;;
    *)    $pm run build ;;
  esac
}

function ns() {
  [[ ! -f package.json ]] && echo "No package.json found" && return 1
  local pm=$(_detect_pm)
  case $pm in
    deno) deno run --allow-net --allow-read start.ts ;;
    *)    $pm run start ;;
  esac
}


# ─────────────────────────────────────────────
#  FUNCTIONS — SSH
# ─────────────────────────────────────────────

# Fall back to xterm-256color for servers without kitty terminfo
function ssh() {
  TERM=xterm-256color /usr/bin/ssh "$@"
}


# ─────────────────────────────────────────────
#  SDKMAN  (must stay last)
# ─────────────────────────────────────────────

export SDKMAN_DIR="$HOME/.sdkman"
local old_sdkman_offline_mode=${SDKMAN_OFFLINE_MODE:-}
export SDKMAN_OFFLINE_MODE=true
source "$SDKMAN_DIR/bin/sdkman-init.sh"

if [[ -n $old_sdkman_offline_mode ]]; then
  export SDKMAN_OFFLINE_MODE=$old_sdkman_offline_mode
else
  unset SDKMAN_OFFLINE_MODE
fi
unset old_sdkman_offline_mode
