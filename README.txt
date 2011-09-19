===============================================================================
 Green Scheduler 
===============================================================================
 AUTHOR:                                      Written by Jordi Blasco Pallares
 REPORTING BUGS:                       Report bugs to <jordi.blasco@gmail.com>.
   Please report all bugs after reviewing project details located at
              http://sourceforge.net/projects/greenscheduler/
===============================================================================

Green Scheduler uses popular HPC batch queues and standards BMC/IPMI connectors 
in order to turn off idle nodes and wake up when is needed using a complex 
function of temperature, rank position, and job queue requirements.

This project is under development and it's not for production environment.

DEPENDENCIES
===============================================================================
You will need gawk and nail in order to install Green Scheduler

INSTALL
===============================================================================
just clone the stable branch tree and execute install script as root

$ git://greenschedduler.git.sourceforge.net/gitroot/greenschedduler/greenschedduler
$ cd greenschedduler
$ sudo ./install.sh

CONFIGURATION
===============================================================================
Set your mail and other varibles at /etc/greenscheduler/greenscheduler.conf
MAIL=
# Timeout in seconds - suggested 10 minuts (600 seconds)
TIMEOUT=600
LOGFILE=/var/log/greenscheduler.log
ACCTFILE=/var/log/greenscheduler.acct
WORKDIR=/var/cache/greenscheduler
# BQS can be SGE, Torque, LSF, Slurm, PBS
BQS=SGE
BQSPATH=/sge
# Min. free SLOTS (per queue)
FNSLOTS=24
# Sort Policy 1:Temperature, 2:Reboots, 3:NeighboursTemperature
SP=1
# Login and Passwd of IPMI and BMC
LOGIN=admin


STARTING DAEMON MANUALLY
===============================================================================

You can use the daemon script to test it:

$ sudo /usr/local/greenscheduler/bin/greenscheduler.sh

To stop the daemon, just press Crtl+C

STARTING DAEMON AUTOMATICALLY
===============================================================================

If you want to iniciate the daemon on boot time, then:

  1) Debian Based

    $ sudo update-rc.d gsd defaults


  2) RedHad/SuSE Based

    $ sudo chkconfig --add gsd

