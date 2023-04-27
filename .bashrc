#
# ~/.bashrc
#

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

set -o vi

stty -ixon
bind -x '"\C-l":clear -x'

HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000

bold_yellow='\033[33;1m'
cyan='\033[36m'
green='\033[32m'
magenta='\033[35m'
reset='\033[0m'
white='\033[97m'
yellow='\033[33m'

PS1="$magenta[$green\u $bold_yellow\w$reset$magenta]$reset\n\$ "

bind 'set completion-ignore-case on'

shopt -s autocd      # change to named directory
shopt -s cdspell     # autocorrects cd misspellings
shopt -s cmdhist     # save multi-line commands in history as single line
shopt -s dotglob     # include .files in pathname expansion
shopt -s histappend  # do not overwrite history

export LESS='-iR'

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
