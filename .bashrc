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

if hash cgb; then
    PS1="\$(cgb)$magenta[$green\u $bold_yellow\w$reset$magenta]$reset\n\$ "
else
    PS1="(no cgb) $magenta[$green\u $bold_yellow\w$reset$magenta]$reset\n\$ "
fi

set -o vi

stty -ixon
bind -x '"\C-l":clear -x'

bind 'set completion-ignore-case on'

shopt -s cdspell     # autocorrects cd misspellings
shopt -s cmdhist     # save multi-line commands in history as single line
shopt -s dotglob     # include .files in pathname expansion
shopt -s histappend  # do not overwrite history

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
