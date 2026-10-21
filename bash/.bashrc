# Interactive shells only
[[ $- != *i* ]] && return

# ble.sh gives bash autosuggestions + syntax highlighting (zsh-autosuggestions / zsh-syntax-highlighting)
# Must be sourced first, attached at the end (see bottom).
BLE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/blesh"
if [[ ! -f $BLE_HOME/ble.sh ]]; then
  mkdir -p "$BLE_HOME"
  curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
    | tar -xJ --strip-components=1 -C "$BLE_HOME" 2>/dev/null
fi
[[ -f $BLE_HOME/ble.sh ]] && source "$BLE_HOME/ble.sh" --noattach

# Same module layout as ~/.zsh
source ~/.bash/git-omz.bash
source ~/.bash/enviroments.bash
source ~/.bash/paths.bash
source ~/.bash/fzf.bash
source ~/.bash/bash.bash
source ~/.bash/nmtui.bash
source ~/.bash/aliases.bash
source ~/.bash/tmux.bash
source ~/.bash/node.bash
source ~/.bash/java.bash
source ~/.bash/ssh.bash
source ~/.bash/nix.bash
source ~/.bash/less.bash
source ~/.bash/direnv.bash
source ~/.bash/git.bash
source ~/.bash/prompt.bash

# >>> Photon CLI >>>
case ":$PATH:" in
  *:'/home/edoardo/.photon/bin':*) ;;
  *) export PATH="$PATH":'/home/edoardo/.photon/bin' ;;
esac
# <<< Photon CLI <<<

[[ ${BLE_VERSION-} ]] && ble-attach
