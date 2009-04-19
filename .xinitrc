#!/bin/sh
# Redirect and log errors to a file
errorlog="$HOME/.xsession-errors"
if ( cp /dev/null "$errorlog" 2> /dev/null )
then
    chmod 600 "$errorlog"
    exec > "$errorlog" 2>&1
    break
fi
#
GDK_USE_XFT=1
xrdb -merge $HOME/.Xresources &
xcompmgr &
urxvtd -o -q -f &
parcellite &
wicd-client &
setxkbmap es &
#
exec awesome > $HOME/.awesome.log 2>&1
