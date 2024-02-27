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
reset='\033[0m'

PS1="$magenta[$green\u $bold_yellow\w$reset$magenta]$reset\n\$ "
hash cgb && PROMPT_COMMAND+=(cgb)

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

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
