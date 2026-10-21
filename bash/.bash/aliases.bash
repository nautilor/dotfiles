# Editors
alias vim=nvim
alias v=nvim

# Navigation
alias ff='cd $(fd -t d . ~ ~/.config | fzf --prompt="directory: ")'

# File listing
alias ls=eza
alias l=eza
alias lr="ls -R"
alias la="ls -a"
alias ll="ls -l"
alias lt="ls -lt"

# Git
alias lg=lazygit
alias lt="nvim -c Task"

# cd
alias ..='cd ..'
alias ...='cd ../..'
alias cdr='cd $(git rev-parse --show-toplevel)'

# Tmux
alias ta='tmux a'
alias tmux='tmux'

# Yazi
alias y=yazi


function csv {
	if [[ -z "$1" ]]; then
		echo "Usage: csv <file>"
		return 1
	fi
	if [[ ! -f "$1" ]]; then
		echo "File not found: $1"
		return 1
	fi
	local first_line
	first_line=$(head -n 1 "$1")
	local delimiter
	if [[ "$first_line" == *","* ]]; then
		delimiter=","
	elif [[ "$first_line" == *";"* ]]; then
		delimiter=";"
	elif [[ "$first_line" == *$'\t'* ]]; then
		delimiter=$'\t'
	else
		echo "Could not determine delimiter for file: $1"
		return 1
	fi
	csvlens -d "$delimiter" "$1"
}
