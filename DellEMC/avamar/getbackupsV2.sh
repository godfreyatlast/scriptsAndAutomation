#!/bin/bash
#set -x
: > clients_backups.log
#if [ "$#" -ne 2 ]
#then
#  echo "Usage: last_bkup_clnts.sh UNIXTIMESTAMP UNIXTIMESTAMP"
#  echo "Example: last_bkup_clnts.sh 1494339065 1494339565"
#  echo "First date range listStart second is listEnd"
#  exit 1
#fi
psql -p 5555 mcdb -c "select client_name,full_client_name from v_group_members" > /tmp/shortnames
psql -p 5555 mcdb -c "select full_client_name from v_group_members" | egrep -v Default | sort |uniq > /tmp/fullnames
for i in $(cat /tmp/fullnames)
do
	#for x in $(avmgr getb --acnt=$i --format=browser --ls=$1 --le=$2 | egrep -v succeeded | awk '{print $3}')
	for x in $(avmgr getb --acnt=$i --format=browser | egrep -v succeeded | awk '{print $3}')
	do 
		short_name=$(cat /tmp/shortnames | egrep -v Default | grep $i | awk '{print $1}' | uniq | cut -f1 -d"_" )
		time=$(date +"%m-%d-%y %H:%M:%S" -d @$x)
		printf "$short_name,$i,$time \n" >> /tmp/fileV2
	done
done
mv /tmp/fileV2 all_backups_after_$1_V2.csv
