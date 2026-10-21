# ─────────────────────────────────────────────
# MISC
# ─────────────────────────────────────────────
shopt -s autocd

# ─────────────────────────────────────────────
# HISTORY
# ─────────────────────────────────────────────
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=$HISTSIZE
HISTCONTROL=ignorespace:erasedups
shopt -s histappend
# share history between sessions: append now, re-read what others wrote
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ─────────────────────────────────────────────
#  KEY BINDINGS
# ─────────────────────────────────────────────
set -o emacs
bind '"\ef": "switch-session.sh\C-m"'
bind '"\eo": "ff\C-m"'
bind '"\C-p": history-search-backward'
bind '"\C-n": history-search-forward'

# Ctrl + Arrow navigation (word-wise)
bind '"\e[1;5D": backward-word'
bind '"\e[1;5C": forward-word'

# Home / End
if [[ -n "$TMUX" ]]; then
  bind '"\e[1~": beginning-of-line'
  bind '"\e[4~": end-of-line'
else
  bind '"\e[H": beginning-of-line'
  bind '"\e[F": end-of-line'
fi

# Delete key
bind '"\e[3~": delete-char'

# sudo plugin: Esc Esc prepends sudo
bind '"\e\e": "\C-asudo \C-e"'

# ─────────────────────────────────────────────
# COMPLETIONS
# ─────────────────────────────────────────────
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set menu-complete-display-prefix on'
[[ -f /etc/bash_completion || -f /run/current-system/sw/share/bash-completion/bash_completion ]] \
  && source /run/current-system/sw/share/bash-completion/bash_completion 2>/dev/null
