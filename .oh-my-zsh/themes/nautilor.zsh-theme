# * show the current hostname
hostname() {
    echo "%{$FG[004]%}%{$BG[004]%}%{$FG[008]%} %m %{$BG[002]%}%{$FG[004]%}"
}

# * show current directory, two levels deep
directory() {
    if [[ -z $(git_prompt_info) ]]; then
        echo "%{$BG[002]%}%{$FG[008]%} %2~ %{$reset_color%}%{$BG[004]%}%{$FG[002]%}%{$BG[003]%}%{$FG[008]%}"
    else
        echo "%{$BG[002]%}%{$FG[008]%} %2~ %{$reset_color%}%{$BG[003]%}%{$FG[002]%}%{$BG[003]%}%{$FG[008]%}"
    fi
}

# * show the current time with milliseconds
current_time() {
    # if return status is not zero
        echo "%{$reset_color%}%{$FG[005]%}%{$BG[005]%}%{$FG[008]%} %* %{$reset_color%}%{$FG[005]%}"
}

# * returns  if there are errors, nothing otherwise
return_status() {
    # if return status is not zero
    echo "%(?..%{$BG[005]%}%{$FG[008]%}%{$BG[008]%}%{$FG[001]%}  %{$reset_color%}%{$FG[008]%})"
}

after_git() {
    if [[ -z $(git_prompt_info) ]]; then
        echo "%{$FG[008]%}%{$BG[004]%} %% %{$reset_color%}%{$FG[004]%} "
    else
        echo "%{$FG[008]%}%{$BG[004]%} %% %{$reset_color%}%{$FG[004]%} "
    fi
}

ZSH_THEME_GIT_PROMPT_PREFIX="%{$BG[003]%}%{$FG[008]%} <"
ZSH_THEME_GIT_PROMPT_SUFFIX="> %{$BG[004]%}%{$FG[003]%}"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""


precmd () { 
    PROMPT="%B$(hostname)$(directory)$(git_prompt_info)$(after_git)%{$reset_color%}"
    RPROMPT="$(current_time)$(return_status)"
}