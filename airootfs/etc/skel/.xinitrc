#!/bin/sh

#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)
#

DEFAULT_SESSION=mate-session

case $1 in
mate)
	exec mate-session
	;;
kde)
	exec startkde
	;;
plasma)
	exec startkde
	;;
gnome)
	exec gnome-session
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

