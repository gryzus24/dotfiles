#!/bin/sh

if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

setxkbmap -option caps:escape

xinput set-prop 'Dell Dell USB Optical Mouse' 'libinput Accel Speed' -0.6 2>/dev/null
xinput set-prop 'SteelSeries SteelSeries Sensei 310 eSports Mouse' 'libinput Accel Profile Enabled' 0 1 2>/dev/null
xinput set-prop 'SteelSeries SteelSeries Sensei 310 eSports Mouse' 'libinput Accel Speed' 0 2>/dev/null
xinput set-prop 'PixArt Dell MS116 USB Optical Mouse' 'libinput Accel Profile Enabled' 0 1 2>/dev/null
xinput set-prop 'PixArt Dell MS116 USB Optical Mouse' 'libinput Accel Speed' 0 2>/dev/null

xrdb -merge "$HOME/.Xresources"
xset b off

exec i3 >/dev/null 2>&1
