#!/bin/bash
## Created by Trevor Baker  ##
## vCenter Migration Script ##
## Last Updated 3/17/2017   ##

#PATH="/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin:/home/admin/scripts/vCenterRefresh:/usr/local/avamar/bin"
#JAVA_HOME="/usr/java/latest"

export PATH=/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/usr/local/avamar/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin:/home/admin/scripts/vCenterRefresh:/usr/local/avamar/bin/mccli:/usr/java/latest/bin/:/usr/java/latest/
export JAVA_HOME=/usr/java/latest




get_Client_Info()
{
  client=$1
  browse=$2

  ## Filter for current client info ##
  #data=$(echo "$browse" | grep -A 4 "$client")
 
data=$(echo "$browse" | sed -n "/$client</{N;N;N;N;N;N;p}")

#| awk -v var="$client" '/var/{x=NR+7}(NR<=x){print}')
  name=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$data")
  guest=$(grep -oPm1 "(?<=GuestOS>)[^<]+" <<< "$data")
  server=$(grep -oPm1 "(?<=Server>)[^<]+" <<< "$data")
  location=$(grep -oPm1 "(?<=Location>)[^<]+" <<< "$data")
  datacenter=$(echo "$location" | cut -d/ -f2 )
  folder=$(echo "$location" | sed 's|^/[^/]*||' | sed 's|^/[^/]*||' | sed 's,/*[^/]\+/*$,,' )
  template=$(grep -oPm1 "(?<=Template>)[^<]+" <<< "$data")
  poweredOn=$(grep -oPm1 "(?<=PoweredOn>)[^<]+" <<< "$data")
  changedBlock=$(grep -oPm1 "(?<=PoweredOn>)[^<]+" <<< "$data")
  protected=$(grep -oPm1 "(?<=Protected>)[^<]+" <<< "$data")

  ## Get Current Group Info ##
  clientVMGroupInfo=$(psql -P format=unaligned -p 5555 mcdb -c "select group_name,full_client_name,ds_id from v_group_members where full_client_name LIKE '%${client}%' AND group_name NOT LIKE 'Default Group' AND group_name NOT LIKE 'Default Proxy Group' AND group_name NOT LIKE 'Default Virtual Machine Group'" | grep "$client\_")
  clientBasedGroupInfo=$(psql -P format=unaligned -p 5555 mcdb -c "select group_name,full_client_name,ds_id from v_group_members where full_client_name LIKE '%${client}%' AND group_name NOT LIKE 'Default Group' AND group_name NOT LIKE 'Default Proxy Group' AND group_name NOT LIKE 'Default Virtual Machine Group'" | grep "$client\.")
  clientBased1GroupInfo=$(psql -P format=unaligned -p 5555 mcdb -c "select group_name,full_client_name,ds_id from v_group_members where full_client_name LIKE '%${client}%' AND group_name NOT LIKE 'Default Group' AND group_name NOT LIKE 'Default Proxy Group' AND group_name NOT LIKE 'Default Virtual Machine Group'" | grep "$client")

  if [ -z "$clientVMGroupInfo$clientBasedGroupInfo$clientBased1GroupInfo" -a "$clientVMGroupInfo" != " " -a "$clientBasedGroupInfo" != " " -a "$clientBased1GroupInfo" != " " ];
  then
    echo "$client,NoBackup,Doesnt Exist currently in a Group"
  elif [ ! -z "$clientVMGroupInfo" -a "$clientVMGroupInfo" != " " ];then
	  policy=$(echo $clientVMGroupInfo | cut -d "|" -f1)
	  vCenter=$(echo $clientVMGroupInfo | cut -d "|" -f2 | cut -d "/" -f2 )
	  domain=$(echo $clientVMGroupInfo | cut -d "|" -f2 | cut -d "/" -f3 )
	  clientID=$(echo $clientVMGroupInfo | cut -d "|" -f2 | cut -d "/" -f4 )
	  datasetID=$(echo $clientVMGroupInfo | cut -d "|" -f3 )
	echo "$name,$guest,$server,$datacenter,$folder,$location,$template,$poweredOn,$changedBlock,$protected,$domain,$vCenter,$policy,$datsetID,$clientID"
  elif [ ! -z "$clientBasedGroupInfo" -a "$clientBasedGroupInfo" != " " ];then
	  policy=$(echo $clientBasedGroupInfo | cut -d "|" -f1)
	  vCenter=""
	  domain=$(echo $clientBasedGroupInfo | cut -d "|" -f2 | cut -d "/" -f2 )
	  clientID=$(echo $clientBasedGroupInfo | cut -d "|" -f2 | cut -d "/" -f3 )
	  datasetID=$(echo $clientBasedGroupInfo | cut -d "|" -f4 )
	echo "$name,$guest,$server,$datacenter,$folder,$location,$template,$poweredOn,$changedBlock,$protected,$domain,$vCenter,$policy,$datsetID,$clientID"
  elif [ ! -z "$clientBased1GroupInfo" -a "$clientBased1GroupInfo" != " " ];then
	  policy=$(echo $clientBasedGroupInfo | cut -d "|" -f1)
	  vCenter=""
	  domain=$(echo $clientBasedGroupInfo | cut -d "|" -f2 | cut -d "/" -f2 )
	  clientID=$(echo $clientBasedGroupInfo | cut -d "|" -f2 | cut -d "/" -f3 )
	  datasetID=$(echo $clientBasedGroupInfo | cut -d "|" -f4 )
	echo "$name,$guest,$server,$datacenter,$folder,$location,$template,$poweredOn,$changedBlock,$protected,$domain,$vCenter,$policy,$datsetID,$clientID"
  else
	  echo "Script should not be here!!!!!!!!!"
	  echo "$client"
	  echo "$name,$guest,$server,$datacenter,$folder,$location,$template,$poweredOn,$changedBlock,$protected,$domain,$vCenter,$policy,$datsetID,$clientID"
  fi

}

#Check for GC
maint_wait_func(){
        echo "Checking to see if GC is running."
        while true ;
        do
                if [ $(status.dpn | grep gc) ];then
                        echo "`date +"%T"` GC is running.  sleeping 60 sec."
                else
                        echo "`date +"%T"` GC Not running."
                        break
                fi;
                sleep 60;
        done
}

#Error Checker -- This function should ONLY be ran IMMEDIATELY after a command you want to check to see if it worked.
error_exit_func()
{
if [ "$?" = "0" ]; then
        echo "`date +"%T"` Last command ran successfully."
else
        echo "`date +"%T"` error: Exiting Script. "
        false
        email_func
        exit 1;
fi
}

error_proceed_func()
{
if [ "$?" = "0" ]; then
        echo "`date +"%T"` Last command ran successfully." >> /home/admin/scripts/vCenterRefresh/masterDayLogs/${runDay}masterLog.txt
else
	echo "`date +"%T"` Last command failed." >> /home/admin/scripts/vCenterRefresh/masterDayLogs/${runDay}masterLog.txt 
		false
        email_func
		false
fi
}

#email
email_func()
{
if [ "$?" = "0" ]; then
        status1="SUCCESS"
        cat /home/admin/scripts/vCenterRefresh/masterDayLogs/${runDay}masterLog.txt | mailx -s "vCenter Automated Migration: $hostname - $status1" $email;
else
        status1="ALERT";
        tail -n 30 /home/admin/scripts/vCenterRefresh/masterDayLogs/${runDay}masterLog.txt | mailx -s "Avamar Automated Migration: $hostname - $status1" $email;
fi
}

#vCenter Cache Update
cache_update()
{
  echo "`date +"%T"` Starting vCenter Cache Update Method."
  allDomains=$(mccli domain show --recursive=true --xml)
  vActive=0
  for i in $allDomains;
  do
   domain=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$i")
   vcenter=$(grep -E '(.*\.)' <<< "$domain")
   vcenter=$(echo $vcenter | cut -d "/" -f2)

   if [ "$vcenter" == "" ];then
      : #This is a blank line from the output from mccli command
   else
      jobsActive=$(mccli activity show --active=true --xml | grep "$vcenter")
     if [ "$jobsActive" == "" ];then
       echo "`date +"%T"` $vcenter No active vm backup jobs."
     else
       echo "`date +"%T"` $vcenter Active vm backup jobs."
       vActive=1
     fi
   fi
  done
   
  if  [ "$vActive" -ne "1" ] ;then
	echo "`date +"%T"` No active vm backup jobs for any vCenters."
	echo "`date +"%T"` Running vCenter Sync Now."

	java -jar /home/admin/scripts/vCenterRefresh/proxycp.jar --syncvmnames
	error_exit_func;

	echo "`date`">/home/admin/scripts/vCenterRefresh/lastVSyncRan.txt
	echo "`date +"%T"` vCenter Sync Completed."
  else
	echo "`date +"%T"` No vCenter Cache Sync Perfomed"
  fi
}




####*************************MAIN METHOD************************************************####

#User Configurable Variables
email=DL-GAI.ITServices.Enterprise.Backup@GAIG.COM
avamar=$(hostname)
#AUDITEMAIL=DL-GAI.ITServices.Enterprise.Backup@GAIG.COM
#EMAIL=jgodfrey@gaic.com
#AUDITEMAIL=jgodfrey@gaig.com

## OPTION PARSE ##
ov=""
nv=""

while [ $# -gt 0 ]
do
    case "$1" in
        -ov)  ov="$2"; shift;;
        -nv)  nv="$2"; shift;;
        -*) echo >&2 \
            "usage: $0 [-ov OldVcenter] [-nv NewVcenter]"
            exit 1;;
        *)  break;;     # terminate while loop
    esac
    shift
done
if ( [ -n "$ov" ] && [ -n "$nv" ] && [ "$ov" != "$nv" ] ) ;then





runDay=`date +"%m%d%y"`

# Master Day Logging #
exec 1>>/home/admin/scripts/vCenterRefresh/masterDayLogs/${runDay}masterLog.txt 2>&1 
echo "**********************************************************************************************"
echo "********************`date +"%m/%d/%Y %T"` Script Started****************************************"
echo "`date +"%T"` Logging to ${runDay}masterLog.txt"

maint_wait_func;
cache_update;

  # Browse New Vceenter
	echo "`date +"%T"` Starting vcenter browse for $nv"
	
	 maint_wait_func;
     nvBrowse=$(mccli vcenter browse --name=$nv --type=VM --recursive=true --xml)
     error_exit_func

	echo "`date +"%T"` Finished vcenter browse for $nv"

  # Browse Old v
	echo "`date +"%T"` Starting vcenter browse for $ov"

	 maint_wait_func;
     ovBrowse=$(mccli vcenter browse --name=$ov --type=VM --recursive=true --xml)
     error_exit_func

	echo "`date +"%T"` Finished vcenter browse for $ov"

	echo "`date +"%T"` Creating client arrays"
  ovClients=()
  nvClients=()

 for i in $ovBrowse;do
  ovClient=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$i")
   if [ -n "$ovClient" ];then
    ovClients+=($ovClient);
   fi
 done

 for i in $nvBrowse;do
  nvClient=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$i")
   if [ -n "$nvClient" ];then
    nvClients+=($nvClient);
   fi
 done
	echo "`date +"%T"` Finished creating client arrays"


nvShortname=$(echo $nv | cut -d "." -f1)
ovShortname=$(echo $ov | cut -d "." -f1)


echo "`date +"%T"` NEW VCENTER CLIENTS**************************************************************"
for i in "${nvClients[@]}"
do
 xx=0
  clientNewData=$(get_Client_Info "$i" "$nvBrowse");
   currentVcenter=$(echo $clientNewData | cut -d "," -f12)
    if [[ ("$currentVcenter" != "$nv") && ("$currentVcenter" != "$ov") ]];then
			
      if [ `echo $clientNewData | cut -d "," -f2` == "NoBackup" ];then
		echo "`date +"%T"`,$i,not backed up"
        echo "`date +"%T"`,$i,not backed up">>/home/admin/scripts/vCenterRefresh/noBackup/${i}.csv &
        #echo $clientNewData
      elif [ "$i" == "$nvShortname" -o "$i" == "$ovShortname" ];then
		echo "`date +"%T"`,$i,is a vCenter"
	  else
		echo "`date +"%T"`,$i,is client based"
        #echo $clientNewData
        echo "`date +"%T"`,$i,is client based">>/home/admin/scripts/vCenterRefresh/avamarClientBased/${i}.csv &
      fi

    elif [ "$i" != "$nvShortname" ];then
      if [ `echo $clientNewData | cut -d "," -f12` != "$nv" ];then

    ### The GREAT MOVE ###
	#echo $clientNewData
	# Get Client Info for retire and re-add
	domain="`echo $clientNewData | cut -d "," -f11`"
	datacenter="`echo $clientNewData | cut -d "," -f4`"
    folder="`echo $clientNewData | cut -d "," -f5`"
	policy="`echo $clientNewData | cut -d "," -f13`"
	datasetID="`echo $clientNewData | cut -d "," -f14`"

	#Retire Client
	if [ "$xx" -eq 0 ]; then 
	echo "`date +"%T"` Retiring client ($i):"
	echo "`date +%Y%m%d%H%M%S`">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv 
	echo "`date +"%T"` $clientNewData">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv
	echo "`date +"%T"` Retiring client ($i):">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
	echo "`date +"%T"` Removing $i from domain /$currentVcenter/$domain"
	echo "`date +"%T"` Removing $i from domain /$currentVcenter/$domain">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
	#echo "mccli client retire --name=$i --domain=/$currentVcenter/$domain"
	maint_wait_func;
	
	mccli client retire --name=$i --domain=/$currentVcenter/$domain;
	error_proceed_func
	if [ $? -eq 0 ]; then
	    echo OK
	else
	    xx=1
	fi
     
	else
		echo "xx variable should always be 0 here"
		echo "`date +"%T"` ($i) did not get retired:"
	fi
	 
	
	#Add vm to new vCenter
	if [ "$xx" -eq 0 ]; then
	echo "`date +"%T"` Inviting ($i):"
	echo "`date +"%T"` Inviting ($i):">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
	echo "`date +"%T"` Inviting $i datacenter $datacenter domain /$nv/$domain folder $folder"
	echo "`date +"%T"` Inviting $i datacenter $datacenter domain /$nv/$domain folder $folder">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
	#echo "mccli client add --type=vmachine --name=$i --datacenter=$datacenter --domain=/$nv/$domain --folder=$folder --changed-block-tracking=true --contact="Migrated vCenter via Script `date +"%D %T"`";"
	maint_wait_func;
	
	mccli client add --type=vmachine --name=$i --datacenter=$datacenter --domain=/$nv/$domain --folder=$folder --changed-block-tracking=true --contact="Migrated vCenter via Script `date +"%D %T"`";
	error_proceed_func
        if [ $? -eq 0 ]; then
	  echo OK
        else
          xx=1
        fi
 
	else
	  echo "`date +"%T"` Error on previous command, skipping mccli client add Command $i"
    fi
	
	if [ "$xx" -eq 0 ]; then
        if [ "$datasetID" != "" ]; then
	  #Add vm to Group with Dataset Override
	  datasetName="`psql -p 5555 mcdb -c "select * from v_datasets" | grep $datasetID | cut -d " " -f2`"
	  echo "`date +"%T"` Adding ($i) to Group:"
          echo "`date +"%T"` Adding ($i) to Group:">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv 
	  echo "`date +"%T"` Adding $i to domain $domain schedule $policy dataset override $datasetName"
          echo "`date +"%T"` Adding $i to domain $domain schedule $policy">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv 
          #echo "mccli group add-client --client-name=$i --client-domain=/$nv/$domain --name=$policy --dataset=$datasetName"
	  maint_wait_func;
		  
	  mccli group add-client --client-name=$i --client-domain=/$nv/$domain --name=$policy --dataset=$datasetName
	  error_proceed_func
          if [ $? -eq 0 ]; then
              echo OK
          else
              xx=1
          fi


        else
	  #Add vm to Group
          echo "`date +"%T"` Adding ($i) to Group:"
          echo "`date +"%T"` Adding ($i) to Group:">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
          echo "`date +"%T"` Adding $i to domain $domain schedule $policy"
          echo "`date +"%T"` Adding $i to domain $domain schedule $policy">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
          #echo "mccli group add-client --client-name=$i --client-domain=/$nv/$domain --name=$policy"
		maint_wait_func;
	      mccli group add-client --client-name=$i --client-domain=/$nv/$domain --name=$policy;
          error_proceed_func
          if [ $? -eq 0 ]; then
              echo OK
          else
              xx=1
          fi

     
        fi
	else
	  echo "`date +"%T"` Error on previous command, skipping mccli group add-client Command $i"
    fi


	#File Cleanup If Server Got Moved
	if [ "$xx" -eq 0 ]; then
	echo "`date +"%T"` Client Moved Successfully"
	echo "`date +"%T"` Client Moved Successfully">>/home/admin/scripts/vCenterRefresh/clientsMoved/${i}.csv &
	echo "`date +"%T"`,$i,Client Moved Successfully">>/home/admin/scripts/vCenterRefresh/vmClientsGood/${i}.csv &
	  if [ -f /home/admin/scripts/vCenterRefresh/clientsNotMoved/${i}.csv ];then
	    rm /home/admin/scripts/vCenterRefresh/clientsNotMoved/${i}.csv & 
	  else
	    : # No Removal necessary
	  fi
	  if [ -f /home/admin/scripts/vCenterRefresh/avamarClientBased/${i}.csv  ];then
	    rm /home/admin/scripts/vCenterRefresh/avamarClientBased/${i}.csv &
	  else
	    : # No removal necessary
	  fi
	  if [ -f /home/admin/scripts/vCenterRefresh/noBackup/${i}.csv ];then
	    rm /home/admin/scripts/vCenterRefresh/noBackup/${i}.csv &
	  else
	    : # No removal necessary
	  fi
	else
	  echo "`date +"%T"` Error on previous command, skipping log cleanup $i"
    fi

      elif  [ `echo $clientNewData | cut -d "," -f12` == "$nv" ];then
	  echo "`date +"%T"`,$i,No Move Necessary,Already in backup"
	  echo "`date +"%T"`,$i,No Move Necessary,Already in backup,$time">>/home/admin/scripts/vCenterRefresh/vmClientsGood/${i}.csv &
	  echo "$clientNewData">>/home/admin/scripts/vCenterRefresh/vmClientsGood/${i}.csv &
	  error=0
      else
	  echo "`date +"%T"`,$i,in group,Script Should Never Be HERE!!!!!!!!!!!!!!!"
	  echo "$clientNewData"
	   error=1
      fi
    else
      echo "`date +"%T"`,$i is the Vcenter"
    fi
done

echo "`date +"%T"` OLD VCENTER CLIENTS**************************************************************"
for i in "${ovClients[@]}"
do
  clientOldData=$(get_Client_Info "$i" "$ovBrowse");
  currentVcenter=`echo $clientOldData | cut -d "," -f12`
    if [[ ("$currentVcenter" != "$nv") && ("$currentVcenter" != "$ov") ]];then
	 if [ `echo $clientOldData | cut -d "," -f2` == "NoBackup" ];then
          echo "`date +"%T"`,$i,not backed up,sits on $ov"
          echo "`date +"%T"`,$i,not backed up,sits on $ov`date +"%T"`">>/home/admin/scripts/vCenterRefresh/noBackup/${i}.csv &
     elif [ "$i" == "$nvShortname" -o "$i" == "$ovShortname" ];then
		echo "`date +"%T"`,$i,is a vCenter"
     else
		echo "`date +"%T"`,$i,is client based,sits on $ov"
        echo "`date +"%T"`,$i,is client based,sits on $ov">>/home/admin/scripts/vCenterRefresh/avamarClientBased/${i}.csv &
     fi
    elif [ "$i" != "$ovShortname" ];then
      if [ `echo $clientOldData | cut -d "," -f12` == "$ov" ];then
	echo "`date +"%T"`,$i,Server not moved yet"
        echo "`date +"%T"`,$i,Server not moved yet">>/home/admin/scripts/vCenterRefresh/clientsNotMoved/${i}.csv &
      else
          echo "`date +"%T"`,$i,in group,Script Should Never Be HERE!!!!!!!!!!!!!!!"
          echo "$clientNewData"
          echo "$clientOldData"
      fi
    else
      echo "`date +"%T"`,$i is the Vcenter"
    fi
done

maint_wait_func;
cache_update;

echo "`date +"%T"` Stopping Script"
echo "********************`date +"%m/%d/%Y %T"` Script Ended******************************************"
echo "**********************************************************************************************"

else
 echo "usage: $0 [-ov OldVcenter] [-nv NewVcenter]"
fi

