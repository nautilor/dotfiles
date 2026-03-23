# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─────────────────────────────────────────────
# ZINITIALIZATION
# ─────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d $ZINIT_HOME ]; then
	mkdir -p "$(dirname $ZINIT_HOME)"
	git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

source ~/.zsh/plugins.zsh
source ~/.zsh/snippets.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


source ~/.zsh/enviroments.zsh
source ~/.zsh/paths.zsh
source ~/.zsh/fzf.zsh
source ~/.zsh/zsh.zsh
source ~/.zsh/nmtui.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/tmux.zsh
source ~/.zsh/node.zsh
source ~/.zsh/ssh.zsh

eval "$(fzf --zsh)"
