#!/bin/bash
#==============================================================================
#  SCRIPT.........:  
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  james.david.godfrey@gmail.com; james.godfrey@sungardas.com
#  CREATED........:  11/15/22
#  DESCRIPTION....:  
#  NOTES..........:  See options from example syntax
#  LOCATION.......:  Avamar utility node: # /home/admin/scripts/avaworker.sh
#==============================================================================
# Please note all changes including changes lines.  See example "CHANGE1"
# CHANGE	DATE		Email/Name						COMMENTS
# 1			11-15-22	james.godfrey@sungardas.com		Inital Rev
# 2			01-10-23	james.godfrey@sungardas.com		Inital Rev

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
EMAIL=james.godfrey@sungardas.com
AUDITEMAIL=james.godfrey@sungardas.com

#Functions (functions should always go up top so they are loaded into memory by the time they are invoked):	

function clean_logfile_func() {
		rm -f $logfile_var;
}

function print_dump_root_hashes_vro(){ #Print to screen the formatted output of dump_root_hashes_cache.rb for processing by vRO


dump_root_hashes_cache=/tmp/dump_root_hashes_cache
dump_root_hashes_path=/home/admin/scripts/dump_root_hashes.rb
function create_dump_root_hashes_cache_func() # Function within print_dump_root_hashes_vro to run and monitor the command
{
	## Build cache - if the command doesnt finish in 25 minutes (10 times * 60Sec) kill the task and retry one time
	cmd() {
	ruby $dump_root_hashes_path --quiet --showcid --compression=none --presence=src,dst,both --replicate=include --no-showbackuptype --outfile=$dump_root_hashes_cache.tmp &> /dev/null & PID=$! ;
	}
	cmd
	for run in {1..25};	do
		if [[ $(ps -ef | grep $PID | grep "dump_root_hashes.rb") && $run = 25 ]] ; then
			echo "Aborting dump_root_hashes_cache build - command has not finished in 25 minutes";
			kill -HUP $PID;
			echo "Retrying dump_root_hashes_cache build one more time - waiting 2 minutes";
			cmd
			sleep 120;
			if ps -ef | grep $PID | grep "dump_root_hashes.rb"; then
				echo "second attempt seems to be unsuccessful - aborting cache rebuild";
				kill -HUP $PID;	
			else
				echo "second attempt seems to be successful";
			fi
		elif ps -ef | grep $PID | grep "dump_root_hashes.rb"; then
			echo "dump_root_hashes_cache still building";
			sleep 60;
		else
			echo "finished building dump_root_hashes_cache"
			break;
		fi
	done
	mv $dump_root_hashes_cache.tmp $dump_root_hashes_cache;	
}

#Checking to see if another script is creating a new cache file, if so wait 25 minutes.
echo "Checking to see if another script is creating a new cache file, if so wait 25 minutes.";
if [ -e "$dump_root_hashes_cache.tmp" ]; then
    echo "$dump_root_hashes_cache.tmp exists - waiting.";
	sleep 1500;
else
	echo "$dump_root_hashes_cache.tmp DOES NOT exsist - moving on";
fi

#Check to see if cache exists at all and create if it doesnt.
echo "Checking to see if cache exists at all and creating if it doesn't."
if [ -e $dump_root_hashes_cache ]; then
    echo "$dump_root_hashes_cache exists - moving on";
else
    echo "Running create_dump_root_hashes_cache_func";
	create_dump_root_hashes_cache_func
fi

#Check to see if cache is older than 1,320 minutes, if it is recreate.
echo "Checking to see if vCenter cache is older than 1,320 minutes, if it is it will be recreated."
if test `find "$dump_root_hashes_cache" -mmin +1320`
then
	echo "$dump_root_hashes_cache is older than 1,320 minutes or does not exists - recreating now.";
	create_dump_root_hashes_cache_func;
else
	echo "$dump_root_hashes_cache is newer than 1,320 minutes, script will use cache.  If cache needs rebuilt delete $dump_root_hashes_cache and rerun.";
fi

## Format and print to screen so vRO can gather output
echo "--------------";
cat $dump_root_hashes_cache | egrep -v "/vCD/|/VirtualMachines|/clients|piddesc|/MC_SYSTEM" | sed 's/".*"//' | awk -F',' '{printf $4 "," $2 "," $3 "," $14 "\n" }' | sort | uniq;
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

	print_dump_root_hashes_vro)  # Example syntax add: $avaworker --print_dump_root_hashes_vro
		print_dump_root_hashes_vro
			# Addthe following (uncommented) to the admin crontab of the avamar utility node to run once a day at 12:30
			## # <<< BEGIN 11:11 custom scripts >>>
			## 30 12 * * * /home/admin/scripts/avaworker.sh --print_dump_root_hashes_vro
			## # <<< END 11:11 custom scripts >>>

		
	;;

	esac;;

*) 
	if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
		#printf "Non-option argument: '-${OPTARG}'" >&2
		printf "Non-option argument: '-${OPTARG}'"
	fi
;;
esac
done

clean_logfile_func