export FZF_CTRL_T_OPTS="--preview 'eza --tree --color=always {} | head -200'"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
	--color=fg:#abb2bf,hl:#c678dd
	--color=fg+:#abb2bf,hl+:#61afef
	--color=info:#61afef,prompt:#56b6c2,pointer:#56b6c2
	--color=marker:#98c379,spinner:#98c379,header:#98c379"

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
