# !/usr/bin/env bash

export FZF_COMMAND="fzf --border"

# NEWT COLORS for nmtui
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
actsellistbox=#bb9af7,#1a1b26'

# FZF
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_CTRL_T_OPTS="--preview ' eza --tree --color=always {} | head -200'"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
	--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
	--color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff
	--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff 
	--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'
