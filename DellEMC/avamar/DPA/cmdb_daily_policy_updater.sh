#!/bin/bash -x
#==============================================================================
#  SCRIPT.........:  /app/opt/emc/dpa/scripts/cmdb_daily_policy_updater.sh
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  james.david.godfrey@gmail.com; 
#  CREATED........:  3-31-17
#  DESCRIPTION....:  To pull csv of all clients from DPA.  Make any needed text manipulation.  And send to the location on isilon which moved to Service-Now by "MoveIt" (moveit is controlled by EISG) 
#  NOTES..........:  
#==============================================================================
# Please note all changes including changes lines.  See example "CHANGE1"
# CHANGE	DATE		Email/Name						COMMENTS
# 0			3-31-17 									Inital Rev
#==============================================================================
#TODO:
# 1	None
#==============================================================================
PATH="/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/sbin:/usr/sbin:/root/bin:/app/opt/emc/dpa/services/bin"
DATE=$(date +"%m/%d/%y/ %H:%M:%S");
LOGFILE=/tmp/$$.log; exec > >(tee ${LOGFILE}) 2>&1; ###Makes stdout and stderr print to log and screen at the same time
printf "Script initiated from $(printf $SSH_CLIENT | awk '{ print $1}'| nslookup | grep name | awk '{print $4}')
Executed on $(uname -a | awk '{print $2}')
$DATE \n\n" ; ###Prints source ip of ssh session & name of host

#User Configurable Variables
#EMAIL=jgodfrey@gaig.com
EMAIL=

#Functions:
#email
email_func(){
if [ "$?" = "0" ]; then
	STATUS="SUCCESS";
	#No need to email on success
else
	STATUS="ALERT";
	cat $LOGFILE | mailx -s "cmdb_daily_policy_updater.sh - $STATUS" $EMAIL;
fi

}
#Error Checker -- This function should ONLY be ran IMMEDIATELY after a command you want to check to see if it worked.
error_exit_func(){
if [ "$?" = "0" ]; then
	printf  "Last command ran successfully. \n\n\n";
else
	printf  "error: Exiting Script. \n";
	false
	email_func;
	exit 1;
fi
}


###Start Script
#check to see if smb is installed  #this should be installed -> yum install samba-client cifs-utils
[ -f /usr/bin/smbclient ] && echo "smbclient is installed" || echo "smbclient is NOT installed.  This will install it -> yum install samba-client cifs-utils"
error_exit_func

#pull csv
wget --no-check-certificate --user=administrator --password=administrator https://cvglpdpa01.td.afg:9002/dpa-api/scheduledreport/results/cmdb_daily_policy_updater.csv
error_exit_func

#make any modificatons
(
cat cmdb_daily_policy_updater.csv | 
sed 's/ //g' | #1 Remove whitespace
sed 's/"//g' | #2 Remove double quotes
awk -F "," '{print $1,$2,$3,$4,$5,$6}'| #3 Replace commas with whitespace (needed for next command to work) 
tr ' ' ',' > cmdb_daily_policy_updater.csv.formatted #4 Convert whitespace into commas (Keeping consideration of header!!!)
)
mv cmdb_daily_policy_updater.csv.formatted cmdb_daily_policy_updater.csv



#send to isilon
smbclient -U ga/cvgavmvic%0Bj5CIwlgdYa //cvgisln01.nas.afg/sdrive --directory Shared/Oncall/CMDB -c 'put "cmdb_daily_policy_updater.csv"'
error_exit_func

#remove file
rm -f ./cmdb_daily_policy_updater*
error_exit_func

