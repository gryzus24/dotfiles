#
# ~/.bashrc
#

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000

YEL='\033[33;1m'
GRE='\033[32m'
MAG='\033[35m'
RST='\033[m'
BGB='\033[40m'
V=$'\x01'
E=$'\x02'

ps1_simple() {
    PS1="$V$GRE$E\$$V$RST$E "
}

ps1_normal() {
    PS1="$V$BGB$MAG$E[$V$GRE$E\u$V$RST$BGB$E@$V$GRE$E\h $V$YEL$E\w$V$RST$BGB$MAG$E]$V$RST$E\n\$ "
}

ps1_normal
if [ "${#PROMPT_COMMAND[@]}" -eq 1 ]; then
    hash cgb && PROMPT_COMMAND+=('[[ $PWD = $HOME/* ]] && cgb')
fi

stty -ixon
bind -x '"\C-l":clear -x'
bind '"\C-e":shell-expand-line'

shopt -s cdspell     # autocorrects cd misspellings
shopt -s cmdhist     # save multi-line commands in history as single line
shopt -s dotglob     # include .files in pathname expansion
shopt -s histappend  # do not overwrite history

# CDPATH=".:"
#
# function cd() {
#     local a
#     [[ -z "$*" ]] && a="$HOME" || a="$*"
#     builtin cd "$a" >/dev/null
# }

## Aliases

# typos
alias cd..='cd ..'

# colors
alias diff='diff --color=auto'
alias egrep='grep --color=auto -E'
alias fgrep='grep --color=auto -F'
alias grep='grep --color=auto'
alias ip='ip -color=auto'

# utils
alias ls='ls --color=auto --time-style=long-iso -N'
alias l='ls -lh'
alias la='ls -A'
alias mv='mv -n'

# ffmpeg
alias ffmpeg='ffmpeg -hide_banner'
alias ffplay='ffplay -hide_banner'
alias ffprobe='ffprobe -hide_banner'

# other
alias acti='. venv/bin/activate'
alias chx='chmod +x'
alias n='nvim'
alias nal='$EDITOR $HOME/.config/alacritty/alacritty.toml'
alias reset='reset && stty -ixon'
if [ -n "$DISPLAY" ] && command -v devour >/dev/null; then
    alias zath='devour zathura'
else
    alias zath='zathura'
fi

## Functions

cdw() {
  local path
  path="$(which "$1")" || return 1
  cd "$(dirname "$path")" || return 1
}

faketty() {
    script -qfec "$(printf "%q " "$@")" /dev/null
}

agrep() {
    command grep --color=always "$@" | grepalign
    return "${PIPESTATUS[0]}"
}

wmem() {
    local t
    t="a = tonumber('$1'); if a == nil then io.write(0.5) else io.write(a) end"
    watch -n "$(luajit -e "$t")" 'grep "Buffers\|Dirty\|Writeback" /proc/meminfo'
}

## Completions
# `complete -c ...`          complete commands
# `complete -F _command ...` complete commands and directories in $PWD

complete -cf devour
complete -c cdw
complete -c faketty
complete -f "$BROWSER"

compdir=/usr/share/bash-completion/completions

. "$compdir/zathura" 2>/dev/null && complete -F _zathura zath

unset compdir

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
