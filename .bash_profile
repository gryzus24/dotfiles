#
# ~/.bash_profile
#

# In case some program does not fall back on the default values.
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR=vim
export VISUAL=vim
export PAGER=less

type -p alacritty >/dev/null && export TERMINAL=alacritty || export TERMINAL=xterm
type -p librewolf >/dev/null && export BROWSER=librewolf || export BROWSER=firefox

export LESS=-iR

[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"

[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx
fi
