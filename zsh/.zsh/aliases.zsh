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

# Tmux
alias ta='tmux a'
alias tmux='tmux'

# Yazi
alias y=yazi
