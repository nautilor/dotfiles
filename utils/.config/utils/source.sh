#!/usr/bin/env bash
#
# fzf environment configuration (source this file, don't execute it).
#

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
	--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
	--color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff
	--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
	--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"

export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
