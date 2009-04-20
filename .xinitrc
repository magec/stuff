#!/bin/sh
#   I log
errorlog="$HOME/.xsession-errors"
if ( cp /dev/null "$errorlog" 2> /dev/null )
then
    chmod 600 "$errorlog"
    exec > "$errorlog" 2>&1
    break
fi
#   nasTests
test -f `which xcompmgr`    && xcompmgr        &
test -f `which urxvtd`      && urxvtd -o -q -f &
test -f `which parcellite`  && parcellite      &
test -f `which wicd-client` && wicd-client     &
#test -f `which setxkbmap`   && setxkbmap es    &
#   o-som
exec awesome > $HOME/.awesome.err 2>&1
