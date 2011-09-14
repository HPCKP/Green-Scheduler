#!/bin/bash
#
#                        Green Scheduler Daemon core  
#===============================================================================
# AUTHOR:                                      Written by Jordi Blasco Pallarès
# REPORTING BUGS:                       Report bugs to <jordi.blasco@gmail.com>.
#   Please report all bugs after reviewing project details located at
#              http://sourceforge.net/projects/greenscheduler/
#===============================================================================
#
#set -xv
source /etc/greenscheduler/greenscheduler.conf

if [ -d $WORKDIR ]; then mkdir -p $WORKDIR; fi


connector() {
if [ $BQS = "SGE" ];then
   export SGE_ROOT=$BQSPATH
   . $SGE_ROOT/default/common/settings.sh
   hoststats="qhost | gawk 'BEGIN{NL=2}{print $0}' | grep -v HOSTNAME | grep -v global"
   queues="qconf -sql"
   qwjobs="qstat -u *, -s p -q "
   disablenode="qmod -d "
   enablenode="qmod -e "

elif [ $BQS = "PBS" ];then

elif [ $BQS = "Torque" ];then

elif [ $BQS = "Slurm" ];then

elif [ $BQS = "LSF" ];then

else
   echo "ALERT : You must define your Batch Queue System in /etc/greenscheduler/greenscheduler.conf"; exit 0
fi
}

nodestatus() {
    whost=$(cat /etc/greenscheduler/whost)
    $($hoststats) > $WORKDIR/nodestatus.dat
    for ahost in $whost
       do 
	  echo "Skipping $ahost ..."
	  gawk -v ahost="$ahost" '{if(match ($1,ahost)==0){print $0}}' $WORKDIR/nodestatus.dat >  $WORKDIR/nodestatus.tmp
          cp $WORKDIR/nodestatus.tmp $WORKDIR/nodestatus.dat
       done
    for host in $(cat $WORKDIR/nodestatus.dat)
	do 
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
    USD=$(cat $LOGFILE | grep DOWN | grep $node | tail -1)
    TSAVED=$(($UWU-$USD))
    PSAVED=$((echo "$TSAVED*475/3600"| bc -l))
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
      $disablenode $node
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
    ipmitool -I lanplus -H ${node}-ilo -U $LOGIN -P $PASSWD chassis bootdev disk
    ipmitool -I lanplus -H ${node}-ilo -U $LOGIN -P $PASSWD chassis power on 
    ipmitool -I lanplus -H ${node}-ilo -U $LOGIN -P $PASSWD chassis bootdev disk
    log UP $node $utime
    acct $node $utime
}

Enablenodes() {
queue=$1
ToWakeUp=$(WUCandidate $queue $NSLOTS)
for node in $ToWakeUp
    do
      WUnodes $node
      $enablenode $node
    done
}




CheckQueues() {
    for $q in $queues; do 
	QW=$($qwjobs $q)
	if (( $QW < 0 )); then
	    NSLOTS=$(($FSLOTS-$MFNSLOTS))
	    # Needed Slots : it will determine how many nodes it will need to wakeup
	    if (( $NSLOTS > 0 ))
		Enablenodes $q $NSLOTS
	    fi
	    
	elif (( $QW => 0 )); then
	    # Exedent Free Slots : it will determine how many nodes it will need to stop
	    EFSLOTS=$(($FSLOTS-$MFNSLOTS))
	    if (( $EFSLOTS > 0 ))
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
    CheckQueues
    sleep $TIMEOUT
done