#!/bin/sh
# I log
errorlog="$HOME/.xsession.err"
if ( cp /dev/null "$errorlog" 2> /dev/null )
then
    chmod 600 "$errorlog"
    exec > "$errorlog" 2>&1
    break
fi
# I merge
xrdb -merge -load ~/.Xdefaults
# nasTests
test -f `which xcompmgr`    && xcompmgr &
test -f `which urxvtd`      && urxvtd -o -q -f
test -f `which parcellite`  && parcellite &
test -f `which wicd-client` && wicd-client
test -f `which ipt2awe.plt` && ipt2awe.pl
test -f `which wmname`      && wmname LG3D # Java Apps Workaround
exec ck-launch-session awesome > ~/.awesome.err 2>&1
