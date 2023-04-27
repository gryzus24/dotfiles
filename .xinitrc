#!/bin/sh

export BROWSER=firefox
export EDITOR=vim
export PAGER=less
export TERMINAL=xterm
export VISUAL=vim

setxkbmap -option caps:escape

xinput set-prop "Dell Dell USB Optical Mouse" "libinput Accel Speed" -0.6
xinput set-prop "SteelSeries SteelSeries Sensei 310 eSports Mouse" "libinput Accel Profile Enabled" 0 1
xinput set-prop "SteelSeries SteelSeries Sensei 310 eSports Mouse" "libinput Accel Speed" 0
xinput set-prop "PixArt Dell MS116 USB Optical Mouse" "libinput Accel Speed" -0.6

xrdb -merge "$HOME/.Xresources"
xset b off

exec i3 >"$HOME/.i3.log" 2>&1
