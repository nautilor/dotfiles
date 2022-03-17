if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# * ZSH THEME
ZSH_THEME="nautilor"

plugins=(git)

# * EXPORTS
export PATH=$PATH:$HOME/.local/bin
export ZSH="/home/edoardo/.oh-my-zsh"
export EDITOR=nvim
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
    --color=fg:#e5e9f0,bg:#2E3440,hl:#81a1c1
    --color=fg+:#e5e9f0,bg+:#2E3440,hl+:#81a1c1
    --color=info:#eacb8a,prompt:#bf6069,pointer:#b48dac
    --color=marker:#a3be8b,spinner:#b48dac,header:#a3be8b'

# * ALIAS
alias vim=nvim
alias p=pather
alias llr="ls -lR"
alias lr="ls -R"
alias cm='clear && figlet -c CUFFIE MORTE && read'
alias c='clear'
alias pac='sudo pacman -S'
alias pacu='sudo pacman -Syu'
alias emacs='emacs -nw'

# * SOURCES
source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source ~/.config/lsx/lsx.sh
source $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
