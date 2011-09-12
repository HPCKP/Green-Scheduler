#!/bin/bash

pc=10  #%

cd /home/xadmin/CLUSTER/

randomize() {
    while IFS='' read -r l ; do printf "$RANDOM\t%s\n" "$l"; done |
    sort -n |
    cut -f2-
    }


llistat_nodes() {

cluster=$1

	lnodes=`qstat -f -q ${cluster}.q| grep -v "\-NA\-" | grep -v g7| grep -v g5 | grep -v g14 | grep [0-9]*/0/`

	total=`echo "$lnodes" | wc -l `

	nodes=`echo "$lnodes" | awk '{ print $1 }' | cut -d@ -f 2 | randomize | head -n$total`


	echo "$nodes"
}

jobsqw() {

cluster=$1

cores=0
nodes=0
ncor=0

if [ $cluster = "iqtc01" ];then
 tot=4
elif [ $cluster = "iqtc04" ]; then
 tot=12
else
 tot=8
fi

jobs=`qstat -u *, | grep " qw "`

for i in `echo "$jobs"| awk '{ print $1 }'`; do

	job=`qstat -j $i`
	l=`echo "$job" | grep hard_queue_list | awk '{ print $2 }' | cut  -d. -f 1 | grep $cluster`

     if [ $? -eq 0 ]; then

		pe=`echo "$job" | grep "parallel environment" | awk '{ print $3 }'`
		ncor=`echo "$job" | grep "parallel environment" | awk '{ print $5 }'`


		if [ "x$pe" = "x" ]; then
			pe=smp
			ncor=1
		fi
		excl=`echo "$job" | grep "exclusive=true"| awk '{ print $3 }'| cut -d= -f2`

	if [ "$pe" = "smp" ]; then
		if [ "$excl" = "true" ]; then
			let nodes=($nodes+1)
		else
			if [ $ncor -lt $tot ]; then
		 	 let cores=($cores+$ncor)
			else
			 let nodes=($nodes+1)
			fi
		fi
	else

		if [ "$excl" = "true" ]; then
			nodes=`echo "(${cores}+(${tot}-1))/${tot}"| bc`
		else
			let cores=($cores+$ncor)
		fi
	fi
     fi
done

nodes_par=`echo "(${cores}+(${tot}-1))/$tot"| bc`

let nodes=($nodes+$nodes_par)

echo "$nodes"

}

down () {

nodes="$1"
cluster=$2

if [ "x$nodes" = "x" ]; then
echo "no hi ha nodes a parar"
return 0
fi

lnodes=""
for i in `echo "$nodes"`; do
 
 grep $i nodes.trencats >> /dev/null
 if [ $? -ne 0 ]; then
  echo $i
  echo qmod -d ${cluster}.q@$i
  lnodes="$lnodes $i "
 fi
done
lnodes=`echo $lnodes | tr " " "\n"`


for i in `echo "$lnodes"`; do
 
 echo ssh $i "shutdown -h now" >> log.txt
 echo $i >> nodesdown.$cluster
 echo wget --http-user=$NUSER --http-password=$NPASSWD --post-data='cmd_typ=25&cmd_mod=2&host=g10node7&btnSubmit=Commit' 'http://localhost:8080/icinga/cgi-bin/cmd.cgi' -O /dev/null
done

}


up () {

engegar=$1
cluster=$2
skip=0


for i in `cat nodesdown.$cluster`; do

 grep $i nodes.trencats >> /dev/null
 if [ $? -ne 0 ]; then
  echo $i >> /tmp/down.txt
 fi

done

if [ -e /tmp/down.txt ]; then
   mv /tmp/down.txt nodesdown.$cluster
fi

nodes=`cat nodesdown.$cluster | randomize | head -n$engegar`

if [ "x$nodes" = "x" ]; then
echo "No hi han nodes disponibles per engegar, no fem res" >> log.txt
	skip=1
fi

if [ $skip -ne 1 ]; then
	for i in `echo "$nodes"`; do

	    echo $i
	    echo qmod -e ${cluster}.q@$i
	    lnodes="$lnodes $i "
	    sed -i -e "/$i/d" nodesdown.$cluster

	done

	for i in `echo "$nodes"`; do
 
	 echo ipmitool -I lanplus -H ${i}-ilo -U admin -P admin chassis bootdev disk
	 echo ipmitool -I lanplus -H ${i}-ilo -U admin -P admin chassis bootdev disk
	 echo ipmitool -I lanplus -H ${i}-ilo -U admin -P admin chassis power on  >> log.txt
	 echo ipmitool -I lanplus -H ${i}-ilo -U admin -P admin chassis bootdev disk
	
	done

	sleep 300

	for i in `echo "$nodes"`; do
	
	 echo ssh $i "/etc/init.d/sgeexecd.iqtc start"
	 echo wget --http-user=$NUSER --http-password=$NPASSWD --post-data='cmd_typ=24&cmd_mod=2&host=g10node7&btnSubmit=Commit' 'http://localhost:8080/icinga/cgi-bin/cmd.cgi' -O /dev/null

	done
fi	
	echo "surto UP"
}

#### MAIN

export SGE_ROOT=/sge
. /sge/default/common/settings.sh
#cd /home/jingles/scripts/GREENSGE
if [ -e petrificus_totalis ]; then
exit 0
fi
touch petrificus_totalis

for k in iqtc01 iqtc02 iqtc03 iqtc04; do

echo $k
nodes=`llistat_nodes $k`

total=`echo "$nodes" | sed -e '/^ *$/d' | wc -l`

echo `date` >> log.txt
echo "Nodes per parar de $k: $total" >> log.txt

 let percentatge=($total*$pc/100)

numnod=`jobsqw $k`

echo "Calculs en cua de $k necessiten $numnod" >> log.txt

echo "Percentatge de nodes de reserva $percentatge" >> log.txt

let numnod=($numnod-$percentatge)

echo "Nodes necessaris un cop eliminat del pool del percentate: $numnod" >> log.txt

if [ $numnod -lt 0 ]; then
 let aparar=($total-$percentatge)
else
 let aparar=($total-$numnod-$percentatge)
fi

echo "Nodes total que es PARARAN: $aparar" >> log.txt

if [ $aparar -lt 0 ]; then
 let engegar=(0-$aparar)   # absolut

echo "Com que es negatiu, necessitem engegar $engegar nodes" >> log.txt

 up $engegar $k

else

 lnodes=`echo "$nodes" | randomize | head -n$aparar`
 down "$lnodes" $k

fi
echo una nova volta
echo "_________________" >> log.txt
done

echo blabla
rm petrificus_totalis

echo bye
echo "=====================================================" >> log.txt
echo "" >> log.txt
