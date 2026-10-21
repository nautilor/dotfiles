# Approximation of the powerlevel10k layout:
#   <blank>
#   <git root> <dir> <git branch/status>
#   :   (magenta ok / red on error)
_prompt_git() {
  local branch dirty
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return
  [[ -n $(git status --porcelain 2>/dev/null | head -n1) ]] && dirty='*'
  printf ' %s%s' "$branch" "$dirty"
}

_prompt_root() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null) || return
  printf '%s ' "${root##*/}"
}

_prompt_nix() {
  [[ -n $IN_NIX_SHELL ]] && printf ' (nix)'
  [[ -n $VIRTUAL_ENV ]] && printf ' (%s)' "${VIRTUAL_ENV##*/}"
}

_prompt_char() {
  if (( $1 == 0 )); then printf '\[\e[35m\]:\[\e[0m\] '; else printf '\[\e[31m\]:\[\e[0m\] '; fi
}

_set_prompt() {
  local ret=$?
  PS1="\n\[\e[90m\]\$(_prompt_root)\[\e[0m\]\[\e[34m\]\w\[\e[0m\]\[\e[90m\]\$(_prompt_git)\$(_prompt_nix)\[\e[0m\]\n$(_prompt_char $ret)"
}
PROMPT_COMMAND="_set_prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
