#
# ~/.bashrc
#

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000

# Sets current branch name to CGB on success. The caller is responsible
# for clearing CGB. This function doesn't fork and is thus the ultimate
# /cgb/.
sh_cgb() {
    # Add a leading / to avoid an infinite loop on relative paths in
    # case someone, completely by accident, assigns to PWD something
    # nasty or the shell reports '(unreachable)', but I'm not sure if
    # that can be the case with bash.
    local d="/$PWD" h

    while :; do
        h="$d/.git/HEAD"
        if [[ -r "$h" ]]; then
            local l r

            # Do not suppress the read error,
            # I would love to see it if the race happens.
            IFS=': ' read -r l r <"$h" || return $?

            local b=$'\x01\033[90m\x02'
            if [[ -n "$r" ]]; then
                CGB="$b(${r##*/}) "
            else
                # Detached HEAD state.
                CGB="$b(${l:0:12}) "
            fi
            return 0
        fi

        d="${d%/*}"
        # Note that the "/$HOME" checking fast-path works only if
        # the starting directory was one directory down from $HOME.
        if [[ "$d" == "/$HOME" || -z "$d" ]]; then
            return 1
        fi
    done
}

prompt_cmd() {
    # Set terminal title to something PS1 like.
    local a='\u@\h:\w'
    printf '\033]0;%s\007' "${a@P}"

    # Update CGB.
    CGB=
    if [[ "$PWD" == $HOME/* ]]; then
        sh_cgb
    fi
}

ps1_simple() {
    local rs=$'\033[m'
    local ye=$'\033[33;1m'
    PS1="\$CGB\[$ye\]\$\[$rs\] "
}

ps1_normal() {
    local bb=$'\033[40m'
    local gr=$'\033[32m'
    local rs=$'\033[m'
    local ye=$'\033[33;1m'
    PS1="\[$bb\]\$CGB\[$gr\]\u@\h \[$ye\]\w \[$rs\]\n\[$ye\]\$\[$rs\] "
}

# Override PROMPT_COMMAND from /etc/bash.bashrc.
unset PROMPT_COMMAND
PROMPT_COMMAND=prompt_cmd
ps1_simple

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
if [[ -n "$DISPLAY" ]] && command -v devour >/dev/null; then
    alias zath='devour zathura'
else
    alias zath='zathura'
fi

## Functions

agrep() {
    command grep --color=always "$@" | grepalign
    return "${PIPESTATUS[0]}"
}

cdw() {
    local path
    path="$(which "$1")" || return 1
    cd "$(dirname "$path")" || return 1
}

faketty() {
    script -qfec "$(printf "%q " "$@")" /dev/null
}

icd() {
    local a
    read -p "$FUNCNAME> " -ei "${1:-$PWD}" a && cd "$a"
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

COMPDIR=/usr/share/bash-completion/completions

. "$COMPDIR/zathura" 2>/dev/null && complete -F _zathura zath

unset COMPDIR

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
