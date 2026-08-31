#!/usr/bin/env bash
#
# fzf environment configuration (source this file, don't execute it).
#

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
	--color=fg:#abb2bf,hl:#c678dd
	--color=fg+:#abb2bf,hl+:#61afef
	--color=info:#61afef,prompt:#56b6c2,pointer:#56b6c2
	--color=marker:#98c379,spinner:#98c379,header:#98c379"

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"

export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
