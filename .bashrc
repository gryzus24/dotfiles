#
# ~/.bashrc
#

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000

bold_yellow='\033[33;1m'
green='\033[32m'
magenta='\033[35m'
reset='\033[m'
bgblack='\033[40m'

PS1="$bgblack$magenta[$green\u $bold_yellow\w$reset$bgblack$magenta]$reset\n\$ "
hash cgb && PROMPT_COMMAND+=('[[ $PWD = $HOME/* ]] && cgb')

stty -ixon
bind -x '"\C-l":clear -x'

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
alias ls='ls --color=auto -N'
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
if command -v devour >/dev/null; then
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
