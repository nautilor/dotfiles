# ─────────────────────────────────────────────
# MISC
# ─────────────────────────────────────────────
setopt auto_cd

#──────────────────────────────────────────────
# HISTORY
# ─────────────────────────────────────────────	
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# ─────────────────────────────────────────────
#  KEY BINDINGS
# ─────────────────────────────────────────────

bindkey -e
bindkey -s '\ef' "switch-session.sh\n"
bindkey -s '\eo' "ff\n"
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Ctrl + Arrow navigation (word-wise)
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Home / End
if [[ -n "$TMUX" ]]; then
	bindkey '^[[1~' beginning-of-line
	bindkey '^[[4~' end-of-line
else
	bindkey '^[[H' beginning-of-line
	bindkey '^[[F' end-of-line
fi

# Delete key
bindkey '^[[3~' delete-char


# ─────────────────────────────────────────────
# COMPLETIONS
# ─────────────────────────────────────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

