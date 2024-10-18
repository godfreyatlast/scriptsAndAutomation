## Created by Trevor Baker  ##
## vCenter Migration Script ##
## Last Updated 2/13/2017   ##


#PATH="/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin:/home/admin/scripts/vCenterRefresh:/usr/local/avamar/bin"
#JAVA_HOME="/usr/java/latest"

export PATH=/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/usr/local/avamar/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin:/home/admin/scripts/vCenterRefresh:/usr/local/avamar/bin/mccli:/usr/java/latest/bin/:/usr/java/latest/
export JAVA_HOME=/usr/java/latest


scriptFolder="/home/admin/scripts/vCenterRefresh"
oldDate=`date --date="24 hours ago" +%Y%m%d%H%M%S`
output=""
hostname=`hostname`
lastVsync=`cat $scriptFolder/lastVSyncRan.txt`



output+="vCenter Automated Migration Status\n"
output+="Last vCenter sync ran at $lastVsync\n"
output+="\n Avamar VMs Moved In Last 24hrs:\n"
output+="Client\tAction\tDateTime (YmdHMS)\n"
for file in $scriptFolder/clientsMoved/{.,}*;
do
 client=$(echo $file | rev | cut -d "/" -f1 | rev | cut -d "." -f1)
 if [[ -z "${client// }" ]];then
   :
   #echo "These are blank files or directories $client"
 else
   date=$(head -n 1 $file)
   if [ $date -gt $oldDate ];then
     output+="$client\tmoved\t$date\n"
   else
   : #output+="$client was moved more than 25hrs ago.\n"
   fi
 fi
done

#output+="\n\nClients Not Yet Migrated To New vCenter  ***********************************************************\n"
#for file in $scriptFolder/clientsNotMoved/{.,}*;
#do
#  client=$(echo $file | rev | cut -d "/" -f1 | rev | cut -d "." -f1) 
#  if [[ -z "${client// }" ]];then
#  :
#  else
#	output+="$client\n"
#  fi
#done

#output+="\n\n Clients Not In Backups ***********************************************************\n"
#for file in $scriptFolder/noBackup/{.,}*;
#do
# client=$(echo $file | rev | cut -d "/" -f1 | rev | cut -d "." -f1)
# if [[ -z "${client// }" ]];then
#  :
# else
#  output+="$client\n"
# fi
#done

#output+="\n\n Avamar Client Based Backups ***********************************************************\n"
#for file in $scriptFolder/avamarClientBased/{.,}*;
#do
#  client=$(echo $file | rev | cut -d "/" -f1 | rev | cut -d "." -f1)
#  if [[ -z "${client// }" ]];then
#   :
#  else
#   output+="$client\n"
#  fi
#done

#output+="\n\n VM Clients In Proper Location ***********************************************************\n"
#for file in $scriptFolder/vmClientsGood/{.,}*;
#do
# client=$(echo $file | rev | cut -d "/" -f1 | rev | cut -d "." -f1)
# if [[ -z "${client// }" ]];then
#  :
# else
#  output+="$client\n"
# fi
#done



  # Browse New Vceenter
     nvBrowse=$(mccli vcenter browse --name=cvgapvbvcs01.td.afg --type=VM --recursive=true --xml)
  # Browse Old v
     ovBrowse=$(mccli vcenter browse --name=cvgwpvcs55.ga.afginc.com --type=VM --recursive=true --xml)

  ovArray=()
  nvArray=()

 for i in $ovBrowse;do
  ovClient=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$i")
   if [ -n "$ovClient" ];then
    ovArray+=($ovClient);
   fi
 done

 for i in $nvBrowse;do
  nvClient=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$i")
   if [ -n "$nvClient" ];then
    nvArray+=($nvClient);
   fi
 done




output+="\n\nAll vCenter VMs as seen by Avamar:\n"
output+="cvgwpvcs55.ga.afginc.com\tcvgapvbvcs01.td.afg\n"

lengthOV=${#ovArray[@]}
lengthNV=${#nvArray[@]}

output+="${lengthOV}\t${lengthNV}\n"
output+="----------\t----------\n"


if [ $lengthOV -gt $lengthNV  ];then
  echo "here"
  for i in "${!ovArray[@]}"
  do
    temp=$(echo "${ovArray[$i]}\t${nvArray[$i]}")
    output+="$temp\n"
  done
else
  for i in "${!nvArray[@]}"
  do
    temp=$(echo "${ovArray[$i]}\t${nvArray[$i]}")
    output+="$temp\n"
  done
fi


echo -e $output | mailx -s "$hostname vCenter Automated Migration Status" DL-GAI.ITServices.Enterprise.Backup@GAIG.COM, cknaley@GAIG.COM, mlsmith2@GAIG.COM, REllis@GAIG.COM, amilazzo@GAIG.COM, BackupAudit@GAIG.COM
#echo -e $output | mailx -s "$hostname vCenter Automated Migration Status" tbaker2@gaig.com


