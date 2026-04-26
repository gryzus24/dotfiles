#
# ~/.bash_profile
#

[[ -d ~/.local/bin ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d ~/bin ]] && PATH="$HOME/bin:$PATH"

# In case some program does not fall back on the default values.
export XDG_CACHE_HOME=~/.cache
export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state

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
    # Compositor/WM specific, set later.
    export TERMINAL
fi

export _PLATFORM=desktop

[[ -f ~/.bashrc ]] && . ~/.bashrc

if type -p sway >/dev/null; then
    TERMINAL="${TERMINAL:-foot}"
    [[ "$XDG_VTNR" == 1 && -z "$WAYLAND_DISPLAY" ]] && exec run-sway
elif type -p i3 >/dev/null; then
    TERMINAL="${TERMINAL:-xterm}"
    [[ "$XDG_VTNR" == 1 && -z "$DISPLAY" ]] && exec startx
else
    echo 'ERROR: Compositor/WM not found' >&2
fi
