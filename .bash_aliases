#
# ~/.bash_aliases
#

# typos
alias cd..='cd ..'

# colors
alias grep='grep --color=auto'
alias egrep='grep --color=auto -E'
alias fgrep='grep --color=auto -F'
alias diff='diff --color=auto'
alias ip='ip -color=auto'

# list
alias l='ls -l'
alias ls='ls --color=auto -hN'
alias ls.="ls -A | grep --color=never -E '^\.'"
alias la='ls -A'

# other
alias nal="$EDITOR ~/.config/alacritty/alacritty.yml"
alias acti='. venv/bin/activate'
