#!/bin/bash
#==============================================================================
#  SCRIPT.........:  
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  
#  CREATED........:  12/21/11
#  DESCRIPTION....:  To Be used as an API like interface with front end scripts
#  NOTES..........:  See options from example syntax
#==============================================================================
# Please note all changes including changes lines.  See example "CHANGE1"
# CHANGE	DATE		Email/Name						COMMENTS
# 0			12-19-16									Inital Rev
# 1			02-07-17									CHANGE1 - fixed handling a situation when something is appended to the end of a 2nd vm display name. Example: cvgaagdtdc01 & cvgaagdtdc01_old.  I surrounded the $clientname_var variable with "" and placed a space before the final quote
# 2			03-27-17									CHANGE2 - Add the client to clients domain first, then activate, then once active move to final domain.
# 3			04-18-17									CHANGE3 - Avamar 7.4.1 changed vmbrowse command output, converted commands to use xml
# 4         08-16-17                                    CHANGE4 - Print the exact command that was ran.  Useful to know vCops ran the command right.
# 5         12-05-17                                    CHANGE5 - Add up to 90 sec random wait on server adds if more than 9 processes are detected. 
# 6			02-20-2018                                  Major update: created function for vmsync $ runbackup, recoded client add, created new func for policy picking when remote site is detected
# 7         02-27-2018                                  Adding functions for monitoring application states
# 8         04-30-2018                                  Added retire_client_func
# 9         06-30-2018                                  changed random wait from 90 to 300 sec and add_backup proc count from 9 to 7, --- Made vcenter a local cache that is recreated if older than 60 minutes
#10         07-14-2018                                  Added kill_old_avaworker_procs_2hr_funcs to kill hung avaworkers (this funtion never really worked as intended)
#11         08-16-2018                                  changed retire_client_func so that when it only found 1 item it would proceed, ALSO added "-a true" option so that when retire is ran from automation that it knows to die when it detects multiple lines. 
#==============================================================================
#TODO:
# 1	Put a check in to see if same hostname exists already
#==============================================================================
export PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/home/jgodfrey/bin:/usr/openv/netbackup/bin/goodies::/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/scripts:/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/usr/local/avamar/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin"
DATE=$(date +"%m/%d/%y %H:%M:%S");

#trap ctrl-c and call clean_logfile_func()
trap clean_logfile_func INT

#Verify only admin can run script
if [ "$(whoami)" != "admin" ]; then
        echo "Script must be run as user: admin"
        exit -1
fi

#Makes stdout and stderr print to log and screen at the same time
logfile_var=/tmp/$$.log; exec > >(tee ${logfile_var}) 2>&1; 
printf "Debug information only: \n Script initiated from $(printf $SSH_CLIENT | awk '{ print $1}'| nslookup | grep name | awk '{print $4}')
 Executed on $(uname -a | awk '{print $2}')
 $DATE \n" ; #Prints source hostname of ssh session & name of host
printf " Script pid $$ \n All instances of avaworker running \n$(ps -ef | grep avaworker | egrep -v grep) \n\n"; ###CHANGE4 Print the scripts at that moment

#User Configurable Variables
EMAIL=DL-GAI.ITServices.Enterprise.Backup@GAIG.COM
AUDITEMAIL=BackupAudit@GAIG.COM

#Functions (functions should always go up top so they are loaded into memory by the time they are invoked):	
function function_timeout_func { 
    #This monitors how long a called function, like the retire function, runs and kills this scripts pid if it runs longer than you want in seconds. 
	#Example: function_timeout_func "echoFooBar" 10
	cmd="$1"; timeout="$2";
    grep -qP '^\d+$' <<< $timeout || timeout=10

    ( 
        eval "$cmd" &
        child=$!
        trap -- "" SIGTERM 
        (       
                sleep $timeout
                kill $child 2> /dev/null 
        ) &     
        wait $child
    )
}

function clean_logfile_func() {
		rm -f $logfile_var;
}

function pick_group_func(){   #Pick the group from the grouplist - lowest number of clients and output
	grouplist=$(echo '
	AFG_0000
	AFG_0100
	AFG_0200
	AFG_1900
	AFG_2000
	AFG_2100
	AFG_2200
	AFG_2300
	');
	arrayGroup=()
	arrayClients=()
	for i in `echo $grouplist`;
		do
		x=$(psql -p 5555 mcdb -c "select group_name from v_group_members" |grep $i | wc -l);
		#echo $i = $x;
		arrayGroups+=($i)
		arrayClients+=($x)
	done
	min=1000000
	index=0
	for v in ${arrayClients[@]}; do
		if (( $v < $min )); then min=$v index1=$index; fi;
		((index=index+1))
	done
	echo ${arrayGroups[$index1]}
	#echo "Displaying clients using index" ${arrayClients[$index1]}
}

function pick_group_remote_sites_func(){   #Pick the group for remote sites
printf "\nRunning pick_group_remote_sites_func \n";	
	if [[ $domain_var = *"Sin"* ]]; then
		policy_var=AFG_1500
	fi
	
	if [[ $domain_var = *"Hong"* ]]; then
		policy_var=AFG_1500
	fi
	
	if [[ $domain_var = *"Mex"* ]]; then
		policy_var=AFG_2200
	fi
	echo "Remote server detected by hostname, group has been logically set.  If this needs changed use -p option or update this function in script."
}

function add_vmclient_func(){   #Add VM client to Avamar
printf "\nRunning add_vmclient_func \n";


vcentercache=/tmp/vcentercache.$vcenter_var
function create_vcentercache_func()
{
	#Build cache - if the command doesnt finish in 5 minutes (10 times * 30Sec) kill the task and retry one time
	mccli vcenter browse --name=$vcenter_var --type=VM --recursive=true --xml > $vcentercache.tmp & PID=$!
	for run in {1..10};	do
		if [[ $(ps -ef | grep $PID | grep "mccli vcenter browse") && $run = 10 ]] ; then
			echo "Aborting vcentercache build - command has not finished in 5 minutes";
			kill -HUP $PID;
			echo "Retrying vcentercache build one more time - waiting 2 minutes";
			mccli vcenter browse --name=$vcenter_var --type=VM --recursive=true --xml > $vcentercache.tmp & PID=$!
			sleep 120;
			if ps -ef | grep $PID | grep "mccli vcenter browse"; then
				echo "second attempt seems to be unsuccessful - aborting cache rebuild";
				kill -HUP $PID;	
			else
				echo "second attempt seems to be successful";
			fi
		elif ps -ef | grep $PID | grep "mccli vcenter browse"; then
			echo "vcentercache still building";
			sleep 30;
		else
			echo "finished building vcentercache"
			break;
		fi
	done
	mv $vcentercache.tmp $vcentercache;
}

#Checking to see if another script is creating a new cache file, if so wait 2 minutes.
echo "Checking to see if another script is creating a new cache file, if so wait 2 minutes.";
if [ -e "$vcentercache.tmp" ]; then
    echo "$vcentercache.tmp exists - waiting.";
	sleep 120;
else
	echo "$vcentercache.tmp DOES NOT exsist - moving on";
fi

#Check to see if vCenter cache exists at all and create if it doesnt.
echo "Checking to see if vCenter cache exists at all and creating if it doesn't."
if [ -e $vcentercache ]; then
    echo "$vcentercache exists - moving on"
else
    echo "Running create_vcentercache_func"
	create_vcentercache_func
fi

#Check to see if vCenter cache is older than 60 minutes, if it is recreate.
echo "Checking to see if vCenter cache is older than 60 minutes, if it is it will be recreated."
if test `find "$vcentercache" -mmin +60`
then
	echo "$vcentercache is older than 60 minutes or does not exists - recreating now.";
	create_vcentercache_func;
else
	echo "$vcentercache is newer than 60 minutes, script will use cache.  If cache needs rebuilt delete $vcentercache and rerun.";
fi

data=$(cat $vcentercache | sed -n "/$clientname_var</{N;N;N;N;N;N;p}"); #CHANGE3
location=$(grep -oPm1 "(?<=Location>)[^<]+" <<< "$data") #CHANGE3
#Set client name found in grep so we can test to verify its the same that was passed in
clientname_test=$(grep -oPm1 "(?<=Name>)[^<]+" <<< "$data") #CHANGE3
#Get VM Datacenter
datacenter=$(echo "$location" | cut -d/ -f2 ) #CHANGE3
#Get VM foldername
folder=$(echo "$location" | sed 's|^/[^/]*||' | sed 's|^/[^/]*||' | sed 's,/*[^/]\+/*$,,' )
#Add Client
# Check to make sure $clientname_var matches what it found in the vcentercache
if [ "$clientname_var" == "$clientname_test" ]; then 
	printf "Attempting to add VM $clientname_var to Avamar 
	Placing in $domain_var 
	Datacenter = $datacenter 
	Folder = $folder. \n";
	mccli client add --type=vmachine --name=$clientname_var --datacenter="$datacenter" --domain=/$domain_var --folder="$folder" --changed-block-tracking=true --contact="Added via Script $DATE";
	error_exit_func;
else
	printf "
	Error: Clientname verification match failed.  
	
	Double check to make sure hostname/displayname is correct.  
	If this is a VM add make sure the specified vCenter is correct.
	
	If you still are having issues tell James.";
	false;
	error_exit_func;
fi
}

function add_agentclient_func(){   #Add Agent client to Avamar
printf "\nRunning add_agentclient_func \n";
	if [ $(psql -p 5555 mcdb -c "select full_client_name from v_group_members" | grep "/clients/$clientname_var") ]; then 
		printf "$clientname_var is already in /clients domain. \n"; 
		client_activation_status=$(mccli client show --name=$clientname_var --domain=/clients | grep "Activated  " |awk '{print $2}');
		echo "Is client already activated? $client_activation_status"; ####testing
		if [ "$client_activation_status" = "No" ]; then
			printf "Attempting to invite $clientname_var to Activate. \n\n";
			mccli client invite --name=$clientname_var --domain=/clients;
			error_exit_func;
		else
			printf "$clientname_var is already activated. \n";
		fi
		printf "Attempting to move $clientname_var to $domain_var. \n";
		mccli client move --name=$clientname_var --domain=/clients --new-domain=/$domain_var;
		error_exit_func;
	else #CHANGE2
		printf "$clientname_var is not already in /clients domain. Checking to see if client pings. \n";
		ping -c1 $clientname_var;
		error_exit_func;
		printf "Attempting to add $clientname_var to Avamar and placing in /clients domain. \n";
		mccli client add --name=$clientname_var --domain=/clients --contact="Added via Script $DATE";
		error_exit_func;
		printf "Attempting to invite $clientname_var to Activate. \n\n"
		mccli client invite --name=$clientname_var --domain=/clients
		error_exit_func;
		printf "Attempting to move $clientname_var to $domain_var. \n";
		mccli client move --name=$clientname_var --domain=/clients --new-domain=/$domain_var;
		error_exit_func;
	fi
}

function add_group_func(){   #Add client to a group
printf "\nRunning add_group_func \n";	
	printf "Attempting to add $clientname_var to $policy_var. \n\n"
	mccli group add-client --client-name=$clientname_var --client-domain=/$domain_var --name=$policy_var;
	error_exit_func;
}

function maint_wait_func(){   #Check for GC or Checkpoint
printf "\nRunning maint_wait_func \n";	
	echo "Checking to see if GC or Checkpoint is running:  ";
	while true; do
		if [ $(status.dpn | grep "Currently running" | egrep "gc|cp") ]; then 
			printf "GC or Checkpoint is running.  Sleeping 60 sec. \n"; 
		else
			printf "GC or Checkpoint is not running. Proceeding. \n";
			break;
		fi;
		sleep 90; 
	done
}

function email_func(){   #email
printf "\nRunning email_func \n";	
if [ -z "$email_subject_var" ]; then
	email_subject_var="undefined subject"
fi
if [ -z "$status" ]; then
	status="undefined status"
fi
if [ -z "$EMAIL" ]; then
	EMAIL="undefined EMAIL"
fi

cat $logfile_var | mailx -s "$email_subject_var - $status" $EMAIL; 
}

function error_exit_func(){  #Error Checker -- This function should ONLY be ran IMMEDIATELY after a command you want to check to see if finished with status 0.
if [ "$?" = "0" ]; then
	status="SUCCESS";
	printf  "Last command ran successfully. \n\n\n";
else
	status="ALERT";
	printf "error: Exiting Script. \n";
	false;
	email_func;
	exit 1;
fi
}

function client_vmcache_resync_func(){   #Runs a vm cache resync for a single client
printf "\nRunning client_vmcache_resync_func \n";	
if psql -p 5555 mcdb -c "select full_client_name from v_group_members" | egrep -v Default | grep "$clientname_var"_ ; then ## If client exists in database get the name, domain name and group for mccli backup command
domain=$( psql -p 5555 mcdb -c "select full_client_name from v_group_members" | grep "$clientname_var"_ | sed 's,/*[^/]\+/*$,,' | uniq )
	mccli vmcache sync --domain=$domain --name=$clientname_var | uniq;
else
	printf "$clientname_var not found in mcdb or is not a VMWare VM backup, script is case sensitive and client must be typed exactly as seen in avamar.\n\n";
fi
}

function runbackup_func(){
printf "\nRunning runbackup_func \n";	
domain=$( psql -p 5555 mcdb -c "select full_client_name from v_group_members" | grep "$clientname_var" | sed 's,/*[^/]\+/*$,,' | uniq )
domain_vm=$( psql -p 5555 mcdb -c "select full_client_name from v_group_members" | grep "$clientname_var"_ | sed 's,/*[^/]\+/*$,,' | uniq )
groupname=$( psql -p 5555 mcdb -c "select group_name,full_client_name from v_group_members" | egrep -v Default | grep $clientname_var | awk '{print $1}' )
groupname_vm=$( psql -p 5555 mcdb -c "select group_name,full_client_name from v_group_members" | egrep -v Default | grep "$clientname_var"_ | awk '{print $1}' )
if psql -p 5555 mcdb -c "select full_client_name from v_group_members" | egrep -v Default | grep "$clientname_var"_ ; then ## If client exists in database get the name, domain name and group for mccli backup command
	## grepping for a "_" will make sure for VM client that we do not accidently start a client with a similar name ... example cvglp01 & cvglp010
	mccli client backup-group-dataset --domain=$domain_vm --name=$clientname_var --group-name=$groupname_vm | uniq;
else
	if psql -p 5555 mcdb -c "select full_client_name from v_group_members" | egrep -v Default | grep "$clientname_var" ; then
		mccli client backup-group-dataset --domain=$domain --name=$clientname_var --group-name=$groupname | uniq;
	else
		printf "$clientname_var not found in mcdb, script is case sensitive and client must be typed exactly as seen in avamar.\n\n";
	fi
fi
}

function monitor_app_state_func(){
printf "\nRunning monitor_app_state_func \n";	
if [ $openvar_var = "avamar" ]; then
	
	# Check 1) check avamar services
	printf "\nChecking for Avamar Processes \n";
	dpnctl status
	if cat $logfile_var | egrep INFO | egrep -v Unattended | egrep -i "unknown|down|not running|disabled|stop|starting|suspended"; then
		status="ALERT";
		printf "$status App check found keywords indicating an issue. Please review output. \n\n";
	else
		printf "$status App check did not detect any keywords indicating a down state. \n\n";
	fi
	
	# Check 2) check to see if any FS are filling up
	if df -h | awk '+$5 >= 80 {print}' | grep [0-9]; then
		status="ALERT";
		printf "$status Found filesystem over space warning threshold. \n"
	else
		status="SUCCESS";
		printf "\n$status App check did not detect any filesystem space issues. \n\n";
	fi
	
		# Check 3) check to see if DDR auth token is on
	grep "use_ddr_auth_token" /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml
	if cat $logfile_var | egrep use_ddr_auth_token | egrep true; then
		status="ALERT";
		printf "$status Found use_ddr_auth_token in /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml set to true. Please change to false. \n"
	else
		status="SUCCESS";
		printf "\n$status App check did not detect issue with use_ddr_auth_token setting. \n";
	fi
	
	
	# If any checks finished with an ALERT variable email results
	if [ $status = "ALERT" ]; then
		email_subject_var="Important: Avamar app monitor ALERT"
		email_func
	fi
elif [ $openvar_var = "dpa" ]; then
	printf "dpa monitoring not yet implemented - add the code here";
else
	printf "application argument not typed correctly or is not supported - use lower case";
fi
}

function retire_client_func(){
printf "\nRunning retire_client_func \n";	

##check to see if full client name has been passed from -x if not get full client name (like domain/client.td.afg)
if [ $openvar_var ]; then
	clientname_var=$openvar_var;
else
	#get full client name, may invoke user interaction
	if psql -p 5555 mcdb -c "select group_name,full_client_name from v_group_members" | egrep -v Default | grep -i $clientname_var; then
		nunber_of_lines_found_var=$(psql -p 5555 mcdb -c "select group_name,full_client_name from v_group_members" | egrep -v Default | grep -i $clientname_var | wc -l);
		echo "Number of items found: $nunber_of_lines_found_var"
		
		#Read command output line by line into array ${lines [@]} --- the output is the group and full client information (including domain)
		IFS=$'\n' read -d '' -ra lines < <( psql -p 5555 mcdb -c "select group_name,full_client_name from v_group_members" | egrep -v Default | grep -i $clientname_var ); # Bash 4.x: use the following instead: readarray -t lines < <(command here)
		
		#Check if more than one thing was found in the psql command, if more than one lines exist then make user choose  
		if [ "$nunber_of_lines_found_var" -gt 1 ]; then
			
			# check if script is being ran via automation
			if [ "$automation" == "true" ]; then
				echo "script is being ran from automation and has detected more than one entry. Aborting script.";
				false;
				error_exit_func;
			fi
			
			echo "Please confirm the client to retire from Avamar:"; # Prompt the user to select one of the lines.
			#This is what the user selects and prints out to the read command (which updates the clientname_var variable )
			select choice in "${lines[@]}"; do
				[[ -n $choice ]] || { echo "Invalid choice. Please try again." >&2; continue; };
				break; # valid choice was made; exit prompt.
			done
		else
			echo "Only one client found in search string, moving on with the following.";
			choice=${lines[@]};
		fi
				
		#This read command is what sets the updated variables like clientname_var that will later get passed back into the script via -x switch
		read -r group unused_element clientname_var <<<"$choice"; # Split the chosen line into group and clientname_var.
		echo "Group: $group; Client: $clientname_var";
	
		#nohup nice "$0" "-x $clientname_var" "--retire_client" & disown
		nice "$0" "-x $clientname_var" "--retire_client";
		sleep 1;
		exit;
	else
		echo "No clients found. Verify hostname is in Avamar backup and spelled correctly."
		sleep 1;
		exit 1;
	fi
fi

domain=$( psql -p 5555 mcdb -c "select full_client_name from v_group_members" | grep "$clientname_var" | sed 's,/*[^/]\+/*$,,' | uniq );
clientname_var=$( psql -p 5555 mcdb -c "select client_name,full_client_name from v_group_members" | grep "$clientname_var" | uniq |awk '{print $1}' ); #This chops off the domain from the full clientname

##Check for dataset overrides and if found print
test_dataset_override_id=$(psql -p 5555 mcdb -c "select client_name,full_client_name,ds_id from v_group_members" | grep "$clientname_var" |awk '{print $5}');
if [ $test_dataset_override_id ]; then
	dataset_name=$(psql -p 5555 mcdb -c "select * from v_datasets" | grep $test_dataset_override_id | cut -d " " -f2);
	echo "$clientname_var DOES have a dataset override.  Printing dataset details.";
	echo "ds_id: $test_dataset_override_id  ds_name: $dataset_name";
	mccli dataset show --name=$dataset_name;
fi

##check and show existing group membership
echo "Printing Group Info"
psql -p 5555 mcdb -c "select group_name,full_client_name from v_group_members" | egrep -v Default | grep $clientname_var;

##check for active backup
if avmaint sessions --ava |grep $clientname_var; then
	echo "Backup of $clientname_var in progress. Please kill its backup.";
	break;
	exit 1;
fi

##check for running gc/cp
maint_wait_func;

##Retire client - Retry every 10 Minutes till it succeeds
echo "Attempting retire now.";
until mccli client retire --name=$clientname_var --domain=$domain; do
    sleep 600;
done;
error_exit_func;

##If dataset override exists attempt to delete 
if [ $dataset_name ]; then
	echo "Attempting to remove $dataset_name.  This will fail if any other clients are attached to this dataset.";
	mccli dataset delete --name=$dataset_name;
fi

##email log
email_subject_var="Avamar Retire Log: $clientname_var ";
email_func;

}

function kill_old_avaworker_procs_2hr_func(){
printf "\nRunning kill_old_avaworker_procs_2hr_func \n";	
killall --older-than 2h /home/admin/scripts/avaworker.sh

##email log
email_subject_var="avaworker.sh kill_old_avaworker_procs_2hr";
email_func;
}


#####################################Start Script
# getops Variables
clientname_var=""
domain_var=""
policy_var=""
openvar_var=""
vcenter_var=""
# start options parse - Don't forget to add your switches here
while getopts c:d:f:p:a:x:v:-: optionName; do
case "$optionName" in
	# --> Use short options for variables ONLY 
c)	clientname_var="$OPTARG";;
d)	domain_var="$OPTARG";;
p)	policy_var="$OPTARG";; 
x)	openvar_var="$OPTARG";;
v)	vcenter_var="$OPTARG";;
a)	automation="$OPTARG";;

-)  # --> Use long options for functions ONLY.  Variables will not work.
	case "${OPTARG}" in

	add_client)  # Example syntax add: $avaworker -c $clientname_var -p $policy_var -v $vcenter_var -d $domain_var --add_client
		# -p is optional
		# -v is optional and determines if it will be added as a VM client 
		email_subject_var="Avamar Automation Log: $clientname_var"
		
		#Check to see if more that 7 avaworker --add_client procs are running - if they are wait a random amount of time, within 300 seconds, and move on.
		if (( $(ps -ef | grep add_client |wc -l) > 7 )); then  
			printf "\nMore than 7 add_client processes running. Sleeping a random amount of time. \n"; 
			sleep $((RANDOM % 300)); 
		fi ###CHANGE5
		
		maint_wait_func
		
		if [ $vcenter_var ]; then
			domain_var="$vcenter_var/$domain_var";
		fi
		printf "domain_var SET TO: $domain_var \n\n";

		if [[ $policy_var = "" ]]; then
			if [ $(printf $domain_var | egrep -i "Sin|Hong|Mex") ] ; then
				pick_group_remote_sites_func;
			else
				policy_var=$(pick_group_func);
			fi
		fi
		printf "policy_var SET TO: $policy_var \n";

		if [ $vcenter_var ]; then
			add_vmclient_func;
		else
			add_agentclient_func;
		fi

		#Add Client to group
		add_group_func;

		#at this point all functions should have passed the error check
		EMAIL=$AUDITEMAIL
		email_func;
	;;

	runbackup) # Example syntax add: $avaworker -c $clientname_var --runbackup
		runbackup_func
	;;
	
	run_backup) # This is just to help with user error - same as "runbackup"
		runbackup_func
	;;
	
	client_vmcache_resync)  # Example syntax add: $avaworker -c $clientname_var --client_vmcache_resync
		client_vmcache_resync_func
	;;
	
	monitor_app_state)  # Example syntax add: $avaworker -x avamar --monitor_app_state
		monitor_app_state_func
	;;
	
	retire_client)  # Example  syntax add: $avaworker -c $clientname_var --retire_client
					# Example2 syntax add (automation ): $avaworker -a true -c $clientname_var --retire_client
		#function_timeout_func "retire_client_func" 999  ##Not used because this timeut check caused the choice code to not work.
		retire_client_func
	;;
	
	# This function isn't working properly - Can probably be removed or retooled to be helpful.
	#kill_old_avaworker_procs_2hr)  # Example syntax add: $avaworker --kill_old_avaworker_procs_2hr
	#	kill_old_avaworker_procs_2hr_func
	#;;

	esac;;

*) 
	if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
		printf "Non-option argument: '-${OPTARG}'" >&2
	fi
;;
esac
done

clean_logfile_func
