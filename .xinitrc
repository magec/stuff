#!/bin/sh
GDK_USE_XFT=1
xrdb -merge $HOME/.Xresources &
#xcompmgr -C &
setxkbmap es&
urxvtd -o -q -f &
exec awesome

#parcellite &
#exec xterm
