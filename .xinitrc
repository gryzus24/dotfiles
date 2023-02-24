#!/bin/sh

export BROWSER=firefox
export EDITOR=vim
export PAGER=less
export TERMINAL=xterm
export VISUAL=vim

setxkbmap -option caps:escape
xrdb -merge $HOME/.Xresources
xset b off

exec i3 >/dev/null 2>&1
