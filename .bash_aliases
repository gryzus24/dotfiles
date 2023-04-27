#
# ~/.bash_aliases
#

# typos
alias cd..='cd ..'

# colors
alias diff='diff --color=auto'
alias egrep='grep --color=auto -E'
alias fgrep='grep --color=auto -F'
alias grep='grep --color=auto'
alias ip='ip -color=auto'

# list
alias ls='ls --color=auto -N'
alias l='ls -lh'
alias la='ls -A'

# completions
compdir='/usr/share/bash-completion/completions'

alias zath='devour zathura'
. "$compdir/zathura" 2>/dev/null && complete -F _zathura zath

## `complete -c ...`          complete commands
## `complete -F _command ...` complete commands and directories in $PWD
complete -c devour

unset compdir

# functions
cdw() {
  path="$(which "$1")" || return 1
  cd "$(dirname "$path")"
}
complete -c cdw

# other
alias nal="$EDITOR $HOME/.config/alacritty/alacritty.yml"
alias acti='. venv/bin/activate'
