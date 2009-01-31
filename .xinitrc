#!/bin/sh
GDK_USE_XFT=1
xrdb -merge $HOME/.Xresources &
#xcompmgr -C &
setxkbmap es&
urxvtd -o -q -f &
parcellite &
if [ -f /usb/bin/wicd-client ] ; then wicd-client& ; fi

exec awesome
