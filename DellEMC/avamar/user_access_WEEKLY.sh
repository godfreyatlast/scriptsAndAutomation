# This script is depenedent on mccli and mailx.
# Script is used to send weekly email to audit containing who has access to backup environment. #
# Created by Trevor Baker 

#!/bin/bash
export PATH=/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/usr/local/avamar/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin:/home/admin/scripts/vCenterRefresh:/usr/local/avamar/bin/mccli:/usr/java/latest/bin/:/usr/java/latest/
export JAVA_HOME=/usr/java/latest


fileDate=`date +"%m%d%y"`
hostname=`hostname`
logOutput="`date`:    Script Started\n"

output=`/usr/local/avamar/bin/mccli user show | sed "1 d"`;

logOutput+="\n\n${output}\n\n"

if [ -z "$output" ]; then
logOutput+="`date`:  !ERROR! - mccli command returned no data.\n"; XY=1;
fi

# Create ouput file:
echo "$output" >> /home/admin/scripts/WeeklyUserAccessAudit/${fileDate}userAccessAudit.txt

# Error Check -- if output file was generated:
if [ -f /home/admin/scripts/WeeklyUserAccessAudit/${fileDate}userAccessAudit.txt ]; then
   logOutput+="`date`:    Output file has been generated\n";
else
   logOutput+="`date`:  !ERROR! - Output File Not Generated\n";XY=1;
fi

# Check if file is empty:
if [ -s /home/admin/scripts/WeeklyUserAccessAudit/${fileDate}userAccessAudit.txt ]; then
   logOutput+="`date`:    Export File size is adequate\n";
else
   logOutput+="`date`:  !ERROR! - Output File Is Empty\n";XY=1;
fi


#### Final Error Check & Send Email ####

if [ "$XY" == "1" ]; then
 logOutput+="`date`:  !FAILED! - Script Encountered An Error\n"
  echo -e "Script Failed!!!\n Script Location: ${hostname}.td.afg/home/admin/scripts/user_access_WEEKLY.sh\n${logOutput}" | mailx -s "Script Failed!!! Audit User Access - ${hostname}" -r ${hostname}@gaig.com "DL-GAI.ITServices.Enterprise.Backup@GAIG.COM"

else
 logOutput+="`date`:    Script Completed\n"
  echo -e "Audit User Access  - ${hostname}\n\n${output}" | mailx -s "Audit User Access - ${hostname}" -a /home/admin/scripts/WeeklyUserAccessAudit/${fileDate}userAccessAudit.txt -a /home/admin/scripts/user_access_WEEKLY.sh -r ${hostname}@gaig.com -c "DL-GAI.ITServices.Enterprise.Backup@GAIG.COM" "BackupAudit@GAIG.COM"

fi


####    Clean up old logs:                                   ####
####    Keeps a log for 42 days. 5 logs should always exist  ####

oldFileDate=`date -d "-42 days" +"%m%d%y"`

# Daily Output Cleanup:
# If output file exist that is from 42days ago, it will remove it:

if [ -f /home/admin/scripts/WeeklyUserAccessAudit/${oldFileDate}userAccessAudit.txt ]; then
   `rm /home/admin/scripts/WeeklyUserAccessAudit/${oldFileDate}userAccessAudit.txt`;
   if [ ! -f /home/admin/scripts/WeeklyUserAccessAudit/${oldFileDate}userAccessAudit.txt ];then
      logOutput+="`date`:    Old access audit file deleted (${oldFileDate}userAccessAudit.txt)\n";
   else
      logOutput+="`date`:  !ERROR! - Old access audit file delete failed (${oldFileDate}userAccessAudit.txt)\n"; XY=1;
   fi
else
   logOutput+="`date`:    INFO - No old access audit file there to delete (${oldFileDate}userAccessAudit.txt)\n";
fi



## Uncomment and add your email address to test script and recieve Log Data.
##  echo -e "Audit User Access Log - ${hostname}\n\n${logOutput}" | mailx -s "Audit User Access Log - ${hostname}" -a /home/admin/scripts/WeeklyUserAccessAudit/${fileDate}userAccessAudit.txt -r ${hostname}@gaig.com "tbaker2@GAIG.COM"



