#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

set -o vi

stty -ixon
bind -x '"\C-l":clear -x'

HISTCONTROL=ignoredups:erasedups
HISTSIZE=20000

bold_yellow='\e[33;1m'
cyan='\e[36m'
green='\e[32m'
magenta='\e[35m'
reset='\e[0m'
white='\e[97m'
yellow='\e[33m'

PS1="$magenta[$green\u $bold_yellow\w$reset$magenta]$reset\n\$ "

bind 'set completion-ignore-case on'

shopt -s autocd          # change to named directory
shopt -s cdspell         # autocorrects cd misspellings
shopt -s cmdhist         # save multi-line commands in history as single line
shopt -s dotglob
shopt -s histappend      # do not overwrite history
shopt -s expand_aliases  # expand aliases

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
