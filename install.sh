#!/bin/bash

echo "==============================================================================="
echo "                               Green Scheduler"
echo "==============================================================================="
echo " AUTHOR:                                      Written by Jordi Blasco Pallarès"
echo " CONTACT EMAIL:                                         jordi.blasco@gmail.com"
echo " REPORTING BUGS: "
echo "    Please report all bugs after reviewing project details located at"
echo "               http://sourceforge.net/projects/greenscheduler/"
echo "==============================================================================="
echo

CURRENTUID=$(id -u)
if [ $CURRENTUID -ne 0 ]; then
        echo "ERROR: You must be logged in as root."
        echo "       $(id)"
        echo
        exit 1
fi

echo "Coping files...."
mkdir -p /usr/local/greenscheduler
cp -pr * /usr/local/greenscheduler/
ln -s /usr/local/greenscheduler/bin/gsd /etc/init.d/gsd
ln -s /usr/local/greenscheduler/etc/greenscheduler /etc/greenscheduler
echo "Making cache directory..."
mkdir -p /var/cache/injectiondenied
echo "Installation Complete"