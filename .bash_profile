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

export EDITOR=vim
export VISUAL=vim
export PAGER=less
export LESS=-iR
type -p librewolf >/dev/null && export BROWSER=librewolf || export BROWSER=firefox

if type -p alacritty >/dev/null; then
    export TERMINAL=alacritty
else
    # WM specific, set later.
    export TERMINAL=
fi

export _PLATFORM=laptop
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
        export XDG_CURRENT_DESKTOP=sway
        #export WLR_DRM_NO_ATOMIC=1
        #export QT_QPA_PLATFORM=wayland
        [[ -z "$TERMINAL" ]] && export TERMINAL=foot

        if [ "$XDG_VTNR" -eq 1 ]; then
            [[ -z "$WAYLAND_DISPLAY" ]] && exec sway >/tmp/swaylog 2>&1
        fi
        ;;
    i3)
        [[ -z "$TERMINAL" ]] && export TERMINAL=xterm

        if [ "$XDG_VTNR" -eq 1 ]; then
            [[ -z "$DISPLAY" ]] && exec startx
        fi
        ;;
    *)
        printf 'ERROR: _WM = %s\n' "$_WM"
        ;;
esac
