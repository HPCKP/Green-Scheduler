#!/bin/bash
#
#                        Green Scheduler Daemon 
#===============================================================================
# AUTHOR:                                      Written by Jordi Blasco Pallarès
# REPORTING BUGS:                       Report bugs to <jordi.blasco@gmail.com>.
#   Please report all bugs after reviewing project details located at
#              http://sourceforge.net/projects/greenscheduler/
#===============================================================================
#
# Valid for Linux/Debian Style

DAEMON=/usr/local/greenscheduler/bin/greenschd.sh
NAME=greenschd
DESC=" Green Scheduler Daemon (greenschd)"

test -x $DAEMON || exit 0


set -e

case "$1" in
start)
     echo -n "Iniciant $DESC: $NAME"
     #start-stop-daemon --start --quiet --pidfile /var/run/greenschd.pid --exec $DAEMON &
     #PID=`ps -fea | grep greenschd | head -1| gawk '{print $2}'`
     #echo $PID  > /var/run/greenschd.pid
     #For debian
     start-stop-daemon -b --start --quiet --pidfile /var/run/greenschd.pid --exec $DAEMON
     echo "."
    ;;
stop)
    echo -n "Aturant $DESC: greenschd"
    #start-stop-daemon --stop --quiet --pidfile /var/run/greenschd.pid
    start-stop-daemon --stop --quiet --oknodo --pidfile /var/run/greenschd.pid
    #kill $PID
    echo "."
    ;;
*)
    echo "Usage: /etc/init.d/greenschd {start|stop|restart}"
    exit 1
esac

exit 0
