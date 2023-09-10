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

# other
alias acti='. venv/bin/activate'
alias nal='$EDITOR $HOME/.config/alacritty/alacritty.yml'
alias zath='devour zathura'

# functions
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

# completions

## `complete -c ...`          complete commands
## `complete -F _command ...` complete commands and directories in $PWD
complete -cf devour
complete -c cdw
complete -c faketty
complete -f "$BROWSER"

compdir=/usr/share/bash-completion/completions

. "$compdir/zathura" 2>/dev/null && complete -F _zathura zath

unset compdir
