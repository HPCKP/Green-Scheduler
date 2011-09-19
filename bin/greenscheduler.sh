#!/bin/bash
#
#                        Green Scheduler Daemon core  
#===============================================================================
# AUTHOR:                                      Written by Jordi Blasco Pallares
# REPORTING BUGS:                       Report bugs to <jordi.blasco@gmail.com>.
#   Please report all bugs after reviewing project details located at
#              http://sourceforge.net/projects/greenscheduler/
#===============================================================================
#
set -xv
source /etc/greenscheduler/greenscheduler.conf

if [ -d $WORKDIR ]; then mkdir -p $WORKDIR; fi


if [ $BQS = "SGE" ]; then
   export SGE_ROOT=$BQSPATH
   . $SGE_ROOT/default/common/settings.sh
   hoststats() {
      qhost | gawk 'BEGIN{NL=2}{print $0}' | grep -v HOSTNAME | grep -v global
   }

   queues() {
      #queues=$(qconf -sql)  # We only use xhpc.q in order to verify and test the performance.
      queues=$(qconf -sql | grep xhpc.q)  # We only use xhpc.q in order to verify and test the performance.
   }
   qwjobs() {
      QW=0
      #QW=$(qstat -u *, -s p -q $1 | wc -l)
      QW=$(qstat -u *, -s p | wc -l) # GE don't filter the qw jobs by queue!!! I have to review job by job. 
   }
   disablenode() {
     qmod -d $1@$2
   }
   enablenode() {
     qmod -e $1@$2
   }
   freeslots() {
     FSLOTS=$(qstat -g c -q $1 | tail -1 | gawk '{print $5}')
   }


elif [ $BQS = "PBS" ]; then
   echo "pending"

elif [ $BQS = "Torque" ]; then
   echo "pending"

elif [ $BQS = "Slurm" ]; then
   echo "pending"

elif [ $BQS = "LSF" ]; then
   echo "pending"

else
   echo "ALERT : You must define your Batch Queue System in /etc/greenscheduler/greenscheduler.conf"; exit 0
fi

nodestatus() {
    whost=$(cat /etc/greenscheduler/whost | gawk '{print $1}')
    hoststats > $WORKDIR/nodestatus.dat
    for ahost in $whost
       do 
	  echo "Skipping $ahost ..."
	  gawk -v ahost="$ahost" '{if(match ($1,ahost)==0){print $0}}' $WORKDIR/nodestatus.dat >  $WORKDIR/nodestatus.tmp
          cp $WORKDIR/nodestatus.tmp $WORKDIR/nodestatus.dat
       done
    for host in $(cat $WORKDIR/nodestatus.dat | gawk '{print $1}')
	do 
	    echo $host
	    # Add data like Temperature, uptime, reboots and create arrays
	done
}

log(){
    type=$1
    node=$2
    utime=$3
    echo $(date +%s) $node $type > $LOGFILE
}

acct(){
    node=$1
    UWU=$2
    USD=$(cat $LOGFILE | grep DOWN | grep $node | tail -1 | gawk '{print $1}')
    TSAVED=$(($UWU-$USD))
    PSAVED=$((echo "$TSAVED*$PCONSUM/3600"| bc -l))
    echo "$(date)  $node  TimeSaved  $TSAVED  PowerSaved  $PSAVED"
}

SDCandidate() {
    ToSTOP=$(sort $WORKDIR/nodestatus.dat -k$SP | grep $1 | gawk -v n=$2 'BEGIN{C=0}{C=C+$3; if (C <= n){print $1}}')
    return $ToSTOP
}

SDnodes() {
ssh $1 "shutdown -h now"
}

Disablenodes() {
queue=$1
$ToSTOP=$(SDCandidate $queue $EFSLOTS)
for node in $ToSTOP
    do
      disablenode $queue $node
      vrfy=$(qhost -h $node | grep $node | gawk '{if ($4 < 1){print 1}}')
      if $vrfy; then SDnodes $node; fi
    done
}

WUCandidate() {
    ToWakeUp=$(sort $WORKDIR/nodestatus.dat -k$SP | grep $1 | gawk -v n=$2 'BEGIN{C=0}{C=C+$3; if (C <= n){if( /-/ ~ $4){print $1}}}')
    return $ToWakeUp
}


WUnodes() {
    node=$1
    utime=$(date +%s)
    case $ITYPE in
      lanplus)
	ipmitool -I lanplus -H ${node}-${IHEX} -U $LOGIN -P $PASSWD chassis bootdev disk
	ipmitool -I lanplus -H ${node}-${IHEX} -U $LOGIN -P $PASSWD chassis power on 
	ipmitool -I lanplus -H ${node}-${IHEX} -U $LOGIN -P $PASSWD chassis bootdev disk
      ;;
      bmc)
      ;;
      lipmi)
      ;;
      lan)
      ;;
      free)
      ;;
      imb)
      ;;
      open)
      ;;
      sun)
      ;;
      xen)
	#This it isn't a real IPMI, but can be used to test and debug this project. 
	ssh xadmin@sge "xm create /etc/xen/vm_${node}.cfg"
      ;;
      *)
	echo "You must setup a valid IPMI Type in the configuration file."
      ;;
    esac
    log UP $node $utime
    acct $node $utime
}

Enablenodes() {
queue=$1
NSLOTS=$2
ToWakeUp=$(WUCandidate $queue $NSLOTS)
for node in $ToWakeUp
    do
      WUnodes $node
      $enablenode $queue $node
    done
}




CheckQueues() {
    for q in $1; do 
	qwjobs $q
	freeslots $q
	if (( $QW < 0 )); then
	    NSLOTS=$(($FSLOTS-$MFNSLOTS))
	    # Needed Slots : it will determine how many nodes it will need to wakeup
	    if (( $NSLOTS > 0 )) ; then
                echo "enable"
		Enablenodes $q $NSLOTS
	    fi
	    
	elif (( $QW >= 0 )); then
	    # Exedent Free Slots : it will determine how many nodes it will need to stop
	    EFSLOTS=$(($FSLOTS-$MFNSLOTS))
	    if (( $EFSLOTS > 0 )) ; then
                echo "disable"
		Disablenodes $q $EFSLOTS
	    fi
	fi
    done
}


#===============================================================================
#                        MAIN Green Scheduler Daemon core  
#===============================================================================

while true
do
    nodestatus
    queues
    CheckQueues $queues
    sleep $TIMEOUT
done
