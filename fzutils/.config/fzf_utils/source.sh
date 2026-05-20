# !/usr/bin/env bash

export FZF_COMMAND="fzf --border"

# NEWT COLORS for nmtui
export NEWT_COLORS=' 
root=#c2c2b0,#222222
roottext=#c2c2b0
helpline=#c9a554
border=#78824b,#222222
window=#c2c2b0,#222222
shadow=#666666,#222222
title=#bb7744,#222222
button=#222222,#78824b
actbutton=#222222,#c9a554
compactbutton=#c2c2b0,#222222
checkbox=#c2c2b0,#222222
actcheckbox=#222222,#5f875f
entry=#d7c483,#1c1c1c
label=#c2c2b0,#222222
listbox=#c2c2b0,#222222
actlistbox=#222222,#78824b
actsellistbox=#222222,#bb7744'

# FZF
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_CTRL_T_OPTS="--preview ' eza --tree --color=always {} | head -200'"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS' 
	--color=fg:#c2c2b0,bg:#222222,hl:#bb7744
	--color=fg+:#d7c483,bg+:#1c1c1c,hl+:#c9a554
	--color=info:#78824b,prompt:#5f875f,pointer:#5f875f
	--color=marker:#c9a554,spinner:#c9a554,header:#78824b'
