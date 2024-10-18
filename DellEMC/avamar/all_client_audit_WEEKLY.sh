# This script is dependent on another script /home/admin/scripts/avamar_sched_audit.pl
# This script generates an output file containing all clients in Avamar Production environment
# This script also generates a log file of what it has completed or failed to do.

export PATH=/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/usr/local/avamar/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin:/home/admin/scripts/vCenterRefresh:/usr/local/avamar/bin/mccli:/usr/java/latest/bin/:/usr/java/latest/
export JAVA_HOME=/usr/java/latest



hostname=`hostname`
fileDate=`date +"%m%d%y"`
XY=0
exec 1>/home/admin/scripts/WeeklyLogs/${fileDate}allAvaClientAuditLog.txt 2>&1

echo "`date`:    Script Started"


echo "`date`:    Executing Avamar Client Script";
output=""
output+="Environment,Server Name,Policy Name,Schedule"$'\n';
output1=`/home/admin/scripts/avamar_sched_audit.pl`;
echo "`date`:    Avamar Perl Script completed";


# Error check -- if Avamar perl script were successful:
if [ -z "$output1" ]; then
echo "`date`:  !ERROR! - Avamar command/script returned no data."; XY=1;
fi

# Add results to output #
output+=$output1



# Create ouput file:
echo "$output" >> /home/admin/scripts/WeeklyClientAudit/${fileDate}allAvaClientAudit.txt

# Error Check -- if output file was generated:
if [ -f /home/admin/scripts/WeeklyClientAudit/${fileDate}allAvaClientAudit.txt ]; then
   echo "`date`:    Output file has been generated";
else
   echo "`date`:  !ERROR! - Output File Not Generated";XY=1;
fi

# Check if file is empty:
if [ -s /home/admin/scripts/WeeklyClientAudit/${fileDate}allAvaClientAudit.txt ]; then
   echo "`date`:    Export File size is adequate";
else
   echo "`date`:  !ERROR! - Output File Is Empty";XY=1;
fi

#Removing useless lines.
if [ "$XY" == "1" ]; then
  echo "`date`:  !ERROR! - Sed command will not run if encounters error above";
else
  sed -i '/Avamar,,Default Group,Default Schedule/d' /home/admin/scripts/WeeklyClientAudit/${fileDate}allAvaClientAudit.txt
fi





####    Clean up old logs:      			     ####
####	Keeps a log for 42 days. 5 logs should always exist  ####

oldFileDate=`date -d "-42 days" +"%m%d%y"`

# Daily Log Cleanup:
  # If a log exist that is from 35days ago, it will remove it:
if [ -f /home/admin/scripts/WeeklyLogs/${oldFileDate}allAvaClientAuditLog.txt ]; then
   `rm /home/admin/scripts/WeeklyLogs/${oldFileDate}allAvaClientAuditLog.txt`;
   if [ ! -f /home/admin/scripts/WeeklyLogs/${oldFileDate}allAvaClientAuditLog.txt ];then
      echo "`date`:    Old log file deleted (${oldFileDate}allAvaClientAuditLog.txt)";
   else
      echo "`date`:  !ERROR! - Old log file delete failed (${oldFileDate}allAvaClientAuditLog.txt)"; XY=1;
   fi
else
   echo "`date`:    INFO - No old log file there to delete (${oldFileDate}allAvaClientAuditLog.txt)";
fi

# Daily Output Cleanup:
  # If output file exist that is from 30days ago, it will remove it:
if [ -f /home/admin/scripts/WeeklyClientAudit/${oldFileDate}allAvaClientAudit.txt ]; then
   `rm /home/admin/scripts/WeeklyClientAudit/${oldFileDate}allAvaClientAudit.txt`;
   if [ ! -f /home/admin/scripts/WeeklyClientAudit/${oldFileDate}allAvaClientAudit.txt ];then
      echo "`date`:    Old Audit file deleted (${oldFileDate}allAvaClientAudit.txt)";
   else
      echo "`date`:  !ERROR! - Old audit file delete failed (${oldFileDate}allAvaClientAudit.txt)"; XY=1;
   fi
else
   echo "`date`:    INFO - No old audit file there to delete (${oldFileDate}allAvaClientAudit.txt)";
fi


#### Final Error Check & Send Email ####

if [ "$XY" == "1" ]; then
 echo "`date`:  !FAILED! - Script Encountered An Error"
  echo -e "Script Failed!!!\n Logs Location: ${hostname}.td.afg/home/admin/scripts/WeeklyLogs/${fileDate}allAvaClientAuditLog.txt\n Script Location: ${hostname}.td.afg/home/admin/scripts/all_client_audit_WEEKLY.sh\n Output Location: /home/admin/scripts/WeeklyClientAudit/${fileDate}allAvaClientAudit.txt" | mailx -s 'Script Failed!!! Audit All Prod Clients - Avamar' -a /home/admin/scripts/WeeklyLogs/${fileDate}allAvaClientAuditLog.txt -r ${hostname}@gaig.com "DL-GAI.ITServices.Enterprise.Backup@GAIG.COM"

else
 echo "`date`:    Script Completed"
 echo "Audit All Prod Clients - Avamar" | mailx -s 'Audit All Prod Clients - Avamar' -a /home/admin/scripts/WeeklyClientAudit/${fileDate}allAvaClientAudit.txt -r ${hostname}@gaig.com -c "DL-GAI.ITServices.Enterprise.Backup@GAIG.COM" "BackupAudit@GAIG.COM"

fi


