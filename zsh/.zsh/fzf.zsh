export FZF_CTRL_T_OPTS="--preview 'eza --tree --color=always {} | head -200'"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#c2c2b0,bg:#222222,hl:#bb7744
  --color=fg+:#d7c483,bg+:#222222,hl+:#c9a554
  --color=info:#78824b,prompt:#5f875f,pointer:#5f875f
  --color=marker:#c9a554,spinner:#c9a554,header:#78824b'

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
