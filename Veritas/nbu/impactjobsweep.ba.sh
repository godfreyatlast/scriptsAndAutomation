#!/bin/bash
#  /usr/openv/netbackup/db/shared_scripts/impactjobsweep.ba.sh
#-------------------------------------------------------------------------------
# HISTORY:	CHANGE	DATE		WHO					Email						COMMENTS
#			0		00/00/11	James Godfrey			Initial Rev
PATH="/usr/bin::/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/volmgr/bin:/usr/openv/netbackup/bin/goodies:/usr/sbin:/usr/bin:/etc/opt/SUNWconn/bin:/opt/VRTS/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/netbackup/db/shared_scripts"

#Variables
tmpdir="/usr/openv/netbackup/logs/impactjobsweep"
bperrorout="/usr/openv/netbackup/logs/impactjobsweep/bperrorout"
bperrorout2="/usr/openv/netbackup/logs/impactjobsweep/bperrorout2"
mailreport="/usr/openv/netbackup/logs/impactjobsweep/mailreport"
rmall=`rm $mailreport;rm $bperrorout;`
subject="Ticket Sweep"
TO="jm"

ERRORS=( 84 86 800 2074 58 )
FILESWEEP=/tmp/err.sweep

if [ ! -a $tmpdir ]; then
mkdir $tmpdir
fi

####START SCRIPT####

#run command to look at failed jobs in X amount of hours
bperror -backstat -U -hoursago 8 | awk '$1 != "0" && $1 != "1" && $1 != "71" && $1 != "150" && $0 !~ /the requested operation was partially successful/ && $0 !~ /none of the files in the file list exist/ && $0 !~ /termination requested by administrator/' >> $bperrorout

egrep -i '52|84|86|800' $bperrorout >> $bperrorout2



>>EOF

#mail info
if [ "$mailreport" -gt 0 ]
then
		mailx -s"$subject" $TO < $mailreport
else
        exit 0
fi

#grab media id and logs and freeze tape

#save the 84 - ect, tape info and email to duty manager

#restart and remove job 

#






#look for 86, 84, 800, 52, etc
cd /opt/openv/netbackup/db/jobs/trylogs

for errcode in $ERRORS
do
grep "Status $errcode" ./* | cut -c 3-9 > $FILESWEEP # need to add better logic to this b/c job id's are 8 charatures in GH
done

#take job id's and find info
for i in $FILESWEEP
do 
bpdbjobs -jobid $i >> $mailreport
