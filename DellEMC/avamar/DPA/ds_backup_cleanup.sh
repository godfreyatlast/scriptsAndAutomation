#! /bin/sh
#==============================================================================
#  SCRIPT.........:  
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  ;
#  CHANGE.........:  0
#  CREATED........:  10-01-13
#  DESCRIPTION....:  1) Clean up old datastore DB backups 2) Dump flat file export 
#  NOTES..........:  
#==============================================================================
DATE_UPDATED="10-01-13"; # <-- Please update date when making revisions
# CHANGE		DATE			Email/Name											COMMENTS
# 1             12-20-2017                                        Updated to deleted folders & Email when it is not able to delete files.
#==============================================================================
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/sbin:/usr/sbin:/root/bin:/app/opt/emc/dpa/services/bin:/usr/bin:/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/volmgr/bin:/usr/openv/netbackup/bin/goodies:/usr/sbin:/opt/VRTS/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/netbackup/:/app/opt/emc/dpa/scripts/:/app/opt/emc/dpa/services/bin/:/usr/local/avamar/bin/:"
# Simple directory trimming tool to handle housekeeping
# Scans a directory and deletes all but the N newest files
#
# Usage: <script> <dir> <number of files to keep>

EMAIL=
BIN="/app/opt/emc/dpa/services/bin";

if [ $# -ne 2 ]; then
	echo 1>&2 "Usage: $0 <dir> <number of files to keep>";
	exit 1;
fi

# Create export in location set by $1 
echo "Sending export to $1."
$BIN/dpa.sh ds export $1

cd $1;
FILES_IN_DIR=`ls | wc -l`
FILES_TO_DELETE=`expr $FILES_IN_DIR - $2`
if [ $FILES_TO_DELETE -gt 0 ]; then
	ls -t | tail -n $FILES_TO_DELETE | xargs rm -rf
	if [ $? -ne 0 ]; then
		ALERT="An error occurred deleting the files, check to make sure user has permissions"
		echo $ALERT
		echo $ALERT | mailx -s "$HOSTNAME - DPA database script had an issue deleting files" $EMAIL
		exit 1
	else
		echo "$FILES_TO_DELETE file(s) deleted."
	fi
else
	echo "nothing to delete!"

fi



