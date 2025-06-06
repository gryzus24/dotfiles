#
# ~/.bash_profile
#

[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"

# In case some program does not fall back on the default values.
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

if type -p nvim >/dev/null; then
    export EDITOR=nvim
    export VISUAL=nvim
else
    export EDITOR=vim
    export VISUAL=vim
fi
if type -p librewolf >/dev/null; then
    export BROWSER=librewolf
else
    export BROWSER=firefox
fi
export PAGER=less
export LESS=-iR
# I wonder if they ever reconsider the brain-damaged decision of not supporting
# .inputrc ... https://github.com/python/cpython/issues/118840
export PYTHON_BASIC_REPL=1

if type -p alacritty >/dev/null; then
    export TERMINAL=alacritty
else
    # WM specific, set later.
    export TERMINAL=
fi

export _PLATFORM=desktop
if type -p sway >/dev/null; then
    export _WM=sway
elif type -p i3 >/dev/null; then
    export _WM=i3
else
    export _WM=unknown
fi

[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"

case "$_WM" in
    sway)
        [[ -z "$TERMINAL" ]] && export TERMINAL=foot
        [[ "$XDG_VTNR" == 1 && -z "$WAYLAND_DISPLAY" ]] && exec run-sway
        ;;
    i3)
        [[ -z "$TERMINAL" ]] && export TERMINAL=xterm
        [[ "$XDG_VTNR" == 1 && -z "$DISPLAY" ]] && exec startx
        ;;
    *)
        echo "ERROR: _WM=$_WM" >&2
        ;;
esac
