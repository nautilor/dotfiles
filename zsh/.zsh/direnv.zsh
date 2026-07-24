alias dup="devenv up -d && [[ ! -n "$DEVENV_ROOT" ]] && devenv shell"
alias down='[[ -n "$DEVENV_ROOT" ]] && devenv processes down'
eval "$(direnv hook zsh)"
