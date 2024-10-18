#!/bin/bash
#==============================================================================
#  SCRIPT.........:  /usr/openv/scripts/resources/nbuworker
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  
#  CREATED........:  12/21/11
#  DESCRIPTION....:  To Be used as an API like interface with front end scripts
#  NOTES..........:  See options from example syntax
#==============================================================================
DATE_UPDATED="06-07-12"; # <-- Please update date when making revisions  
# CHANGE	DATE		Email/Name						COMMENTS
# 0			12-21-11				Initial Rev
# 1			02-29-12									Updated version option use -AL. Updated --os to specifically check for windows and unix
# 2			03-15-12									Added functions/options for remote user backup script.
# 3			06-07-12									Added/fixed --excludesendux for bpgp policy support
# 4			04-17-15									updated $PATH to work on RHEL
#==============================================================================
PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/home/jgodfrey/bin:/usr/openv/netbackup/bin/goodies::/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/scripts"
set -o pipefail


#Variables
CLIENTNAME=""
POLICY=""
FILEPATH=""
OPENVAR=""


#start options parse
while getopts c:s:p:f:x:-: optionName; do
case "$optionName" in
	# --> Use short options for variables
c)	CLIENTNAME="$OPTARG";;
f)	FILEPATH="$OPTARG";;
p)	POLICY="$OPTARG";;
s)	SCHEDULE="$OPTARG";;
x)	OPENVAR="$OPTARG";;


-)  # --> Use long options for functions.  Variables will not work.
	case "${OPTARG}" in
	bpplclients_add)
		# Example syntax add: $nbuworker -c $CLIENTNAME -p $POLICY --bpplclients_add
		if bpplclients -allunique |grep $CLIENTNAME &> /dev/null; then
				bpplclients $POLICY -add $CLIENTNAME $(bpplclients -allunique -noheader |egrep $CLIENTNAME |awk '{print $1}') $(bpplclients -allunique -noheader |egrep $CLIENTNAME |awk '{print $2}')
			else
				echo "Client is NOT currently in a nightly backup POLICY"
				echo "Verify you are in the correct environment and have the correct server name"
				exit
		fi
	;;


	bppllist_show_sched)
		# Example syntax remove: $NBUWORKER -p $POLICY --bppllist_show_sched;
		bppllist $POLICY |egrep "SCHED " |awk '{print $2}'
	;;


	bppllist_summary_of_all_policies)
		# Example syntax remove: $NBUWORKER --bppllist_summary_of_all_policies;
		bppllist -allpolicies -L | perl -lne 'if (/^Policy Name:\s*(\S+)/){$pol=$1;} elsif(/^Client.HW.OS.Pri:\s*(\S+\s+\S+\s+\S+)/){print "$pol $1";}'
	;;


	bpplclients_delete)
		# Example syntax remove: $NBUWORKER -p $POLICY -c $CLIENTNAME --bpplclients_delete
		bpplclients $POLICY -delete $CLIENTNAME
	;;
	
	
	bpplinclude_add)
		# Example syntax add: $NBUWORKER -p $POLICY -f $FILELIST --bpplinclude_add;
		OLD_IFS=$IFS
		IFS=$'\n'
		for i in $(cat $FILEPATH); do
		echo "Adding  $i  to Backup Selection" 
		bpplinclude $POLICY -add "$i"
		done;
		IFS=$OLD_IFS
	;;
	
	
	bpplinclude_delete)
		# Example syntax add: $NBUWORKER -p $POLICY -x $FILELIST --bpplinclude_delete;
		OLD_IFS=$IFS
		IFS=$'\n'
		for i in `cat $FILEPATH`; do
		bpplinclude $POLICY -delete "$i"
		done;
		IFS=$OLD_IFS
	;;
		
		
	bpbackup_start)
		# Example syntax: $nbuworker -c $CLIENTNAME -p $POLICY -s $SCHEDULE --bpbackup_start
		bpbackup -p $POLICY -s $SCHEDULE -i -h $CLIENTNAME 
	;;
	
	
	bpplinfo_modify_keyword)
		# Example syntax: $NBUWORKER -p $POLICY -x "$KEYWORD" --bpplinfo_modify_keyword
		bpplinfo $POLICY -modify -keyword "$OPENVAR"; 
	;;

	
	bpplinfo_modify_pt)
		# Example syntax: $NBUWORKER -p $POLICY -x "$KEYWORD" --bpplinfo_set_keyword
		bpplinfo $POLICY -modify -pt $OPENVAR
	;;
	
	
	bperror_check_job_start)
		# Example syntax: $NBUWORKER -c $CLIENTNAME --bperror_check_job_start;
		DATE=$(date +"%m/%d/%y/ %H:%M:%S");
		until bperror -client $CLIENTNAME -d $DATE |awk '{print $7}' &> /dev/null |uniq; do 
				echo "Waiting for Job to be queued - Do not exit script";
				sleep 5;
		done
		echo ""; echo "Job has been queued. **Job ID is below**";
		bperror -client $CLIENTNAME -d $DATE |awk '{print $7}' |uniq;
	;;
	
	
	bpplclients_client_verify)
		# Example syntax remove: $NBUWORKER -c $CLIENTNAME --bpplclients_client_verify
		bpplclients -allunique -noheader |egrep $CLIENTNAME |awk '{print $3}';
	;;
		
		
	connectiontest)
		bpgetconfig -g $CLIENTNAME;
	;;
		
		
	excludepullwin)
		# Example syntax: $nbuworker -c $CLIENTNAME --excludepullwin
		bpgetconfig -M $CLIENTNAME Exclude;
	;;

	
	excludesendwin)
		# Example syntax: $NBUWORKER -c $CLIENTNAME -x $CONF
		bpsetconfig -h $CLIENTNAME $OPENVAR;
	;;

	
	excludepullux)
		if echo $nbuver | grep "[6].[5].[3-9]" &> /dev/null || echo $nbuver | grep "[7-9].[0-9].[0-9]" &> /dev/null; then
				bpgetconfig -e $FILEPATH $CLIENTNAME 2> /dev/null;
			else
				bpgp from $CLIENTNAME /usr/openv/netbackup/exclude_list $FILEPATH 2> /dev/null;
		fi
	;;
	
	
	excludesendux)
		if [[ -z $POLICY ]]; then  #If $POLICY is null then
				# Example syntax: $nbuworker -c $CLIENTNAME -f $exclude --excludesendux
				if echo $nbuver | grep "[6].[5].[3-9]" &> /dev/null || echo $nbuver | grep "[7-9].[0-9].[0-9]" &> /dev/null; then
						bpsetconfig -e $FILEPATH -h $CLIENTNAME 2> /dev/null;
					else
						bpgp to $CLIENTNAME $FILEPATH /usr/openv/netbackup/exclude_list 2> /dev/null;
				fi
			else
				# For use only when needing to set a POLICY specific exclude list
				# Example syntax: $nbuworker -c $CLIENTNAME -f $exclude -p $POLICY --excludesendux
				if echo $nbuver | grep "[6].[5].[3-9]" &> /dev/null || echo $nbuver | grep "[7-9].[0-9].[0-9]" &> /dev/null; then
						bpsetconfig -e $OPENVAR -h $CLIENTNAME -c $POLICY; # Set file exclude_list.$POLICY which will be blank
					else
						bpgp to $CLIENTNAME $OPENVAR /usr/openv/netbackup/exclude_list.$POLICY 2> /dev/null; # Set file exclude_list.$POLICY which will be blank
				fi
		fi
	;;
	
	
	mediaserver)
		if cat /usr/openv/netbackup/bp.conf | grep $CLIENTNAME &> /dev/null ; then
				echo "YES"
				mediaserver=Y
			else
				echo "NO"
				mediaserver=N
		fi
	;;
		
		
	os)
		# Example syntax: $nbuworker -c $CLIENTNAME --os
		if bpgetconfig -M $CLIENTNAME VERSIONINFO|grep -i Window &> /dev/null; then
				echo "Windows"
				os=windows
			elif bpgetconfig -M $CLIENTNAME VERSIONINFO| egrep "SunOS|Solaris" &> /dev/null; then
				echo "SunOS Solaris"
				os=Solaris
			elif bpgetconfig -M $CLIENTNAME VERSIONINFO| egrep "Linux" &> /dev/null; then
				echo "Linux"
				os=Linux
			elif bpgetconfig -M $CLIENTNAME VERSIONINFO| egrep "AIX" &> /dev/null; then
				echo "AIX"
				os=AIX
			elif bpgetconfig -M $CLIENTNAME VERSIONINFO| egrep "HP-UX" &> /dev/null; then
				echo "HP-UX"
				os=HP-UX
			else
				echo "OS not supported"
				exit 2
		fi
	;;
		
		
	version)
			nbuver=`bpgetconfig -g $CLIENTNAME -AL |grep "Patch Level" |awk '{print $4}'`
	;;
		
	esac;;
	

*) 
	if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
		echo "Non-option argument: '-${OPTARG}'" >&2
	fi
;;
esac
done
