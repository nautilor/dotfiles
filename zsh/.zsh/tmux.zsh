# Attach to or create the main tmux session
function t() {
  [[ $(tmux ls 2>/dev/null | grep -E "^main:.*") ]] && tmux || tmux new -s main
}
