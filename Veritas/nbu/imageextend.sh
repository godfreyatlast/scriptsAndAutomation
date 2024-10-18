#!/bin/bash
#  /usr/openv/netbackup/db/shared_scripts/imageextend.ba.sh
#-------------------------------------------------------------------------------
# CHANGE	DATE		WHO					COMMENTS
# 0		11/07/11	James Godfrey		Initial Rev
# 1		06/01/12	James Godfrey		added fields to report
# 1		04/17/15	James Godfrey		making work at GAI

PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/home/jgodfrey/bin:/usr/openv/netbackup/bin/goodies::/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/scripts"

#Variables   
updated="4/17/15"
tmpdir="/usr/openv/scripts/resources/logs/imageextend"
imageextendtemp="$tmpdir/imageextendtemp.`date +"%m%d%y%H%M%S"`"
imageextendbefore="$tmpdir/imageextendbefore.`date +"%m%d%y%H%M%S"`"
imageextendafter="$tmpdir/imageextendafter.`date +"%m%d%y%H%M%S"`"
mailreport="$tmpdir/mailreport.`date +"%m%d%y%H%M%S"`"
epochperl="$tmpdir/epochperl.pl"
TO="jgodfrey@gaig.com"
#TO="james.godfrey@ge.com"
master=`bpclntcmd -pn|awk {'print $1'}`

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
rm $imageextendtemp &> /dev/null ;
rm $imageextendafter &> /dev/null ; 
rm $imageextendbefore &> /dev/null ; 
rm $mailreport &> /dev/null ;
}

#Function:	
dynamic(){  # add x amount of day to exsisting exp time
clear
echo "Enter days you'd like to extend"
echo "Example: 35"
echo "______________________________________________"
read retention	#var
	echo "" #get user username
	echo ""
	echo "Enter username"
	echo "______________________________________________"
	read username  #var
	echo ""
	echo "Please Wait..."
		#Change expiration dates 
		for i in `cat $imageextendtemp | grep "_[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"  |awk {'print $1'}`  #< this garners the image id
		do
				epochexpbase=`bpimagelist -backupid $i | grep IMAGE | awk '{print $16}'`
				epochplusretention=`expr $retention \* 86400 + $epochexpbase`
				epochfinal=`$epochperl $epochplusretention`
			bpexpdate -recalculate -backupid $i -d $epochfinal -force
			bpimagelist -L -backupid $i| egrep 'Client:       |Sched Label:| Expiration Time|Backup ID|Schedule Type:|Policy:       |Backup Time:'|uniq|sed -e 's/^[ \t]*//' >> $imageextendafter
			echo "-------------------" >> $imageextendafter
		done
}

#Function:	
static(){ # Hard set all images to xx/xx/xx date
clear
echo "Enter date you would to keep images. Format = MM/DD/YY"
echo "Example: `date +"%m/%d/%y"`"
echo "______________________________________________"
read retention	#var
	echo "" #get user username and email
	echo ""
	echo "Enter username"
	echo "______________________________________________"
	read username  #var
	echo ""
	echo "Enter email"
	echo "A report will be sent to you"
	echo "______________________________________________"
	read TO  #var
	echo ""	
	echo "Please Wait..."
		#Change expiration dates
		for i in `cat $imageextendtemp | grep "_[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"  |awk {'print $1'}`
		do
			bpexpdate -recalculate -backupid $i -d $retention -force
			bpimagelist -L -backupid $i| egrep 'Client:       |Sched Label:| Expiration Time|Backup ID|Schedule Type:|Policy:       |Backup Time:'|uniq|sed -e 's/^[ \t]*//' >> $imageextendafter
			echo "-------------------" >> $imageextendafter
		done
}

#Prerequisites:
#check to see if logging dir is created
if [[ ! -e $tmpdir ]]; then
mkdir $tmpdir
fi
#check to see if epochperl convertion pearl is there and if not create it
if [ ! -e "$epochperl" ] ; then
echo '#!/usr/bin/perl' >> $epochperl
echo '$num_args = $#ARGV + 1; die "Usage: this-program epochperl (something like '1219822177')" if' >> $epochperl
echo '($num_args != 1); $epoch_time = $ARGV[0]; ($sec,$min,$hour,$day,$month,$year) = localtime($epoch_time); ' >> $epochperl
echo '$year = 1900 + $year; $month++; printf "%02d/%02d/%02d\n", $month, $day, $year;' >> $epochperl
chmod u+x $epochperl
chmod 755 $epochperl
fi

####START SCRIPT####

####
#ask for users understanding
clear
echo "Script last modified on $updated"
echo ""
echo "Place the ImagesID's within vi and save"
echo ""
echo "Example:"
echo "cvgwd00102.ga.afginc.com_1424855005"
echo "cvgwd00102.ga.afginc.com_1424855161"
echo ""
echo "IMPORTANT: As soon as vi opens hit 'i' - otherwise it won't be in insert mode! Also, Don't forget to wq!"
echo "Tip: You can copy and paste whole lines straight from the catalog into this script "
echo ""
echo "Do you understand? (y/n)"
echo "______________________________________________"
yes_no #Function:   simple yes or no 
#start text editor to get imagesIDs from user
vi $imageextendtemp
####	
	#gather imagesIDs info for user to verify
	for i in `cat $imageextendtemp | grep "_[0-9][0-9][0-9][0-9][0-9][0-9][0-9]"  |awk {'print $1'}`
	do
		bpimagelist -L -backupid $i| egrep 'Client:       |Sched Label:| Expiration Time|Backup ID|Schedule Type:|Policy:       |Backup Time:'|uniq|sed -e 's/^[ \t]*//' >> $imageextendbefore
		echo "-------------------" >> $imageextendbefore
	done
	clear
	#print info
	cat $imageextendbefore
	echo ""
	echo "Above are the image(s) that will be modified."
	#Ask user if things look good
	echo "Do you have all the ImagesID's? Do they look correct?"
	echo ""
	echo "Ready to proceed? (y/n)"
	echo "______________________________________________"
	yes_no #Function:   simple yes or no 	
####
		# choose hard date to extend all images uniform 
		# or days to add/append to (i.e. add 35 days to each backup)
		clear
		echo "Choose Image Extention logic"
		echo ""
		echo "1. Dynamically add days to each image expiration"
		echo "	- This option will add as may days as you"
		echo "	specify to an ImageIDs existing expiration date"
		echo "2. Statically set all images to single date"
		echo "	- Be careful using this option as it"
		echo "	could potentially shorten long term retention backups"
		echo "______________________________________________"
		echo "Press any other key and/or enter to EXIT"
		read -p "Enter choice [ 1 - 2] " choice
		case $choice in
			1) dynamic ;;
			2) static ;;
			*) exit 0 ;;
		esac
####
			#Print 
			clear
			echo "NOTES"
			echo "______________________________________________"
			cat $imageextendafter
####
				#Create Report to be mailed
				echo "The Following Images have been extended by $username on $master" >> $mailreport; 
				echo "" >> $mailreport;
				echo "______________________________________________" >> $mailreport; 
				echo "" >> $mailreport;
				echo "Before Image Extention" >> $mailreport;
				echo "" >> $mailreport;
				cat $imageextendbefore | sed 's/^[ \t]*//;s/[ \t]*$//' >> $mailreport;
				echo "______________________________________________" >> $mailreport; 
				echo "" >> $mailreport;
				echo "After Image Extention" >> $mailreport;
				echo "" >> $mailreport;
				cat $imageextendafter | sed 's/^[ \t]*//;s/[ \t]*$//' >> $mailreport;
				#Email Report
				mailx -s"Image Extention Report - $master - `date +"%m-%d-%y"`" $TO < $mailreport
####					
					#Cleanup
					tmpcleanup
