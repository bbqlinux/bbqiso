#!/bin/sh

#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)
#

DEFAULT_SESSION=startxfce4

case $1 in
kde)
	exec startkde
	;;
xfce4)
	exec startxfce4
	;;
icewm)
	icewmbg &
	icewmtray &
	exec icewm
	;;
wmaker)
	exec wmaker
	;;
blackbox)
	exec blackbox
	;;
*)
	exec $DEFAULT_SESSION
	;;
esac

