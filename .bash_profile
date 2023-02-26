#
# ~/.bash_profile
#

# In case a program does not fall back on the default values.
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

[[ -f ~/.bashrc ]] && . ~/.bashrc

export PATH="$HOME/bin:$PATH"

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx
fi
