#
# ~/.bashrc
#

# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

HISTCONTROL=ignoredups:erasedups
HISTSIZE=100000

bold_yellow='\033[33;1m'
cyan='\033[36m'
green='\033[32m'
magenta='\033[35m'
reset='\033[0m'
white='\033[97m'
yellow='\033[33m'

current_git_branch() {
  local t
  t="$(git branch --show-current 2>/dev/null)" || return
  printf '(%s) ' "$t"
}
PS1="\$(current_git_branch)$magenta[$green\u $bold_yellow\w$reset$magenta]$reset\n\$ "

set -o vi

stty -ixon
bind -x '"\C-l":clear -x'

bind 'set completion-ignore-case on'

shopt -s cdspell     # autocorrects cd misspellings
shopt -s cmdhist     # save multi-line commands in history as single line
shopt -s dotglob     # include .files in pathname expansion
shopt -s histappend  # do not overwrite history

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases
