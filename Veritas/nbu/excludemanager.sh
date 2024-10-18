#!/bin/bash
#==============================================================================
#  SCRIPT.........:  /usr/openv/scripts/excludemanager.sh
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  
#  CHANGE.........:  2
#  CREATED........:  12/21/11
#  DESCRIPTION....:  To Be used by a backup admin to push/pull netbackup exclude lists
#  NOTES..........:  
#==============================================================================
# CHANGE	DATE		WHO					Email						COMMENTS
# 0		12/21/11	James Godfrey									Initial Rev
# 1		01/17/12	James Godfrey									Corrected if operator for bpgp not making tmp file when EXCLUDE doesnt exsist. 
#																	Added trap for ctrl c (SIGINT).  Added command line argument for CLIENTNAME variable.
# 2		03/23/12	James Godfrey									Changed NBUWORKER location
# 2		04/08/15	James Godfrey				Updated to work on AFG netbackup
DATE_UPDATED="04/08/15"; # <-- Please update date when making revisions  
#==============================================================================
PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/home/jgodfrey/bin:/usr/openv/netbackup/bin/goodies::/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/scripts"


#Variables
NBUWORKER=/usr/openv/scripts/resources/nbuworker
TMPDIR="/usr/openv/scripts/resources/logs/excludemanager"
MAILREPORT="$TMPDIR/mailreport.`date +"%m%d%y%H%M%S"`"
INFO="$TMPDIR/info.`date +"%m%d%y%H%M%S"`"
EXCLUDE="$TMPDIR/exclude.`date +"%m%d%y%H%M%S"`"
TO="jgodfrey@gaig.com"
CLIENTNAME=("$@")


#Function:	simple yes or no 
yes_no(){
while true; do
    read yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) tmpcleanup;exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
}

#Function:	Cleanup tmp files  
tmpcleanup(){
rm $MAILREPORT &> /dev/null;
rm $INFO &> /dev/null;
rm $EXCLUDE* &> /dev/null;
exit
}

#Prerequisites:
if [[ ! -e $TMPDIR ]]; then
mkdir $TMPDIR
fi

trap tmpcleanup SIGINT

####START SCRIPT####

#gather the server name from user
clear
echo "Script last modified on $DATE_UPDATED"
echo ""
#check to see if CLIENTNAME was passed via command line argument
if [ -n "${1}" ] ; then
		echo "Checking $CLIENTNAME"
	else
		echo "Enter name of client"
		echo "EXAMPLE: cvgwqbisql22.aag.gfrinc.net"
		echo "_________________________"
		read CLIENTNAME  #var
fi	
echo ""

#check netbackup connectivity and get information about client
if $NBUWORKER -c $CLIENTNAME --connectiontest &> /dev/null; then
		echo "Connection successfully established with $CLIENTNAME"
		mediaserver=`$NBUWORKER -c $CLIENTNAME --mediaserver`
		echo "Is $CLIENTNAME a Media Server?: $mediaserver" >> $INFO
		oscheck=`$NBUWORKER -c $CLIENTNAME --os`
		echo "Operating System is: $oscheck" >> $INFO
		cat $INFO
	else
		echo "ERROR:  Please check that the hostname was entered correctly and validate netbackup connectivity."
		tmpcleanup
fi

#Pull EXCLUDE list
if `grep -i Window $INFO &> /dev/null` ; then
		# if windows
		$NBUWORKER -c $CLIENTNAME --excludepullwin > $EXCLUDE
			if grep -i EXCLUDE $EXCLUDE &> /dev/null ; then
					echo "_________________________"
					cat $EXCLUDE
					echo "_________________________"
					echo "Found the above Excludes on $CLIENTNAME"
				else
					echo "Did not find any Excludes in place"
			fi
		echo "Please use Netbackup Java console to modify Excludes if needed"
		tmpcleanup

	else

		# if unix
		# get EXCLUDE list
		$NBUWORKER -c $CLIENTNAME -f $EXCLUDE --version --excludepullux
		echo "_________________________"
			if [ ! -f $EXCLUDE ] || [[ `wc -l $EXCLUDE | awk '{print $1}' | grep 0` == 0 ]] ; then
					echo "Script did not detect Excludes on $CLIENTNAME"
				else
					cat $EXCLUDE;
					echo "_________________________";
					echo "Above is the current EXCLUDE list for $CLIENTNAME"; 
			fi
		echo "Would you like to add/modify the EXCLUDE List? (y/n)";
		yes_no
		cp  $EXCLUDE $EXCLUDE.original;
		vi $EXCLUDE;
		clear;
		echo "The following Excludes will be sent to $CLIENTNAME"; 
		echo "_________________________";
		cat $EXCLUDE | sed 's/[ ]*$//' > $EXCLUDE.cleaned; #clean up trailing spaces
		mv $EXCLUDE.cleaned $EXCLUDE; 
		cat $EXCLUDE;  #Verify Excludes before send
		echo "_________________________"
		echo "Verify Excludes are correct. Any trailing spaces have been removed."; 
		echo "Does everything look correct before you send (y/n)"
		yes_no
		echo ""; #Gather SSO and RFC
		echo "Enter SSO"  #get user SSO
		echo "_________________________"
		read sso; 
		echo ""
		echo "Enter Ticket/Change#"  #get rfc
		echo "_________________________"
		read change #var
		
		# pull EXCLUDE again to make sure it wasn't modified while we were changing it
		$NBUWORKER -c $CLIENTNAME -f $EXCLUDE.verifybeforesend --version --excludepullux
			if [[ $(cat $EXCLUDE.original) == $(cat $EXCLUDE.verifybeforesend) ]]; then
					echo "Presend check Successful. Sending Now."
				else
					echo "Excludes on client have changed while you were modifying. Excludes NOT SENT."
					echo "Please Try Again..."
					tmpcleanup
			fi

		# send EXCLUDE
		$NBUWORKER -c $CLIENTNAME -f $EXCLUDE --version --excludesendux

		# verification of send
		$NBUWORKER -c $CLIENTNAME -f $EXCLUDE.verifyaftersend --version --excludepullux
			if [[ $(cat $EXCLUDE.verifyaftersend) == $(cat $EXCLUDE) ]]; then
					echo "Performed sanity check of Excludes sent.  Verification Successful."
					verificationreport="Successful"
				else
					echo "Verification *FAILED*  Report will still be sent."
					echo "Manually verify Excludes NOW..."
					verificationreport="UNSUCCESSFUL"
			fi
fi

#Create report and cleanup tmp files
echo "User: $sso" >> $MAILREPORT
echo "Ticket: $change" >> $MAILREPORT
echo "Client: $CLIENTNAME" >> $MAILREPORT
echo "Verification = `echo $verificationreport`" >> $MAILREPORT
date >> $MAILREPORT
echo "" >> $MAILREPORT;	
echo "Before:" >> $MAILREPORT;
echo "_________________________" >> $MAILREPORT;
cat $EXCLUDE.original  >> $MAILREPORT;
echo "---------------------" >> $MAILREPORT
echo "" >> $MAILREPORT
echo "After:" >> $MAILREPORT
echo "_________________________" >> $MAILREPORT
cat $EXCLUDE.verifyaftersend >> $MAILREPORT
mailx -s"Exclude List changed on $CLIENTNAME `date +"%m-%d-%y"`" $TO < $MAILREPORT

	echo ""
	echo "A report of the changes has been sent to the shared mailbox."
	tmpcleanup
