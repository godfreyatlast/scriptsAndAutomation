scripting notes



________________________________________________________________________

________________________________________________________________________

________________________________________________________________________

________________________________________________________________________

# When dealing with spaces in $FILEPATH remember to modify IFS

OLD_IFS=$IFS
IFS=$'\n'
	for i in $(cat $FILEPATH); do
	echo "Adding  $i  to Backup Selection" 
	bpplinclude $POLICY -add "$i"
	done;
IFS=$OLD_IFS
________________________________________________________________________
http://www.uniforum.chi.il.us/slides/bash1.pdf

sub strings
declare MyStr="The quick brown fox"
echo "${MyStr:0:3}" # The
echo "${MyStr:4:5}" # quick
echo "${MyStr: -9:5}" # brown
echo "${MyStr: -3:3}" # fox
echo "${MyStr: -9}" # brown fox

•set -o noclobber
•used to avoid overlaying files
•set -o errexit
•used to exit upon error, avoiding cascading errors
• set -o pipefail
– unveils hidden failures
• set -o errexit
– can exit silently
• trap command ERR
– corrects silent exits
• $LINENO
– enhances error reporting
•set -o nounset
•exposes unset variables
________________________________________________________________________

Make things with _b no matter what

echo test |sed 's/_b//' |sed 's/$/_b/'
________________________________________________________________________
Variables
date_formatted=$(date +%m_%d_%y-%H.%M.%S)

________________________________________________________________________

for i in `nbstl -b|grep isilon`; do
> x=`nbstl $i -l | awk '$1==1 {print $6}'`
> echo .$i, retention: $x : Backup -> Isilon SLP.
> nbstl $i -modify -uf 0 -residence nbumedia_alpisilon -managed 0 -rl $x
> done

for i in `nbstl -b|grep isilon`; do
x=`nbstl $i -l | awk '$1==0 {print $6}'`
echo “$i, retention: $x : Backup -> DD -> Isilon SLP”
nbstl $i -modify -uf 0,1 -residence nbumedia-06_alpdd,nbumedia_alpisilon -managed 2,0 -rl 0,$x -as __NA__,alpnbumstr1_b
done

________________________________________________________________________


Godfrey, James (GE, Corporate, consultant):  
I think I found something online 1:25 PM 
#!/bin/ksh
for shuttle in $(cat  spaceshuttles.txt)
do
       print "Current Space Shuttle : $shuttle"
done  1:25 PM 
lemme adjust  1:25 PM 
hell yeah  1:26 PM 
[nw99qdt@ghnbutest01]/# for i in $(cat /usr/openv/netbackup/db/shared_scripts/imageextendtemp); do echo $i; done
test
test2
  1:26 PM 
thank you  1:26 PM 
League, Mark (GE Corporate):  
worked fine for me 1:28 PM 
[sysml4t@ghnbutest01]/#  for i in `cat /usr/openv/netbackup/db/shared_scripts/imageextendtemp`
> do
> echo $i
> done
test
test2
  1:28 PM 
Yours really look like single-quotes  1:28 PM 
but looks like you got a way.  1:28 PM 
Godfrey, James (GE, Corporate, consultant):  
Ohh - I see the difference now 1:29 PM 
Mine were single quote not backticks like I thought  1:29 PM 
League, Mark (GE Corporate):  
lol 1:30 PM 
yeah backticks in many languages are the execute operator  1:30 PM 

________________________________________________________________________

Clean up ghost jobs in nbu

for i in `cat /tmp/err50`; do
/usr/openv/netbackup/bin/bpjobd -r $i
done

________________________________________________________________________

for i in `cat /tmp/incomplete_list.txt`; 
do 
	if /usr/openv/netbackup/bin/admincmd/bpgetconfig -M $i |egrep interchk.chk; then
		/usr/openv/netbackup/bin/admincmd/bpgetconfig -M $i |egrep "CLIENT_NAME|CLUSTER_NAME|^Exclude = "|grep -v TRUST_; 
		echo "-----";
	fi
done

________________________________________________________________________
OLD
#yes or no function

yes_no(){
while true
do
read confirm
if [[ $confirm = y ]]; then
	CONFIRMED = 1
	break
elif [[ $confirm = n ]]; then
	CONFIRMED = -1
	exit
	$rmall
else
	echo "y and n are the only options"
fi
	done
if [[ $CONFIRMED -eq -1 ]]; then
	$rmall
	exit
fi
}

NEW

#simple yes or no function
yes_no(){
while true; do
    read yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
}

________________________________________________________________________

Different way to invoke function

function ndmplog
{
echo "[`date +%m/%d/%Y\" \"%H:%M:%S`]" $1 >> $LOG
}

________________________________________________________________________

Pull user id 

user=`id | awk '{print $1}' | sed 's=.*(\(.*\))=\1='`

[nw99qdt@acslsgh1]/# ^D
$ id | awk '{print $1}'
uid=12257(nw99qdt)
$ id | awk '{print $1}' | sed 's=.*(\(.*\))=\1='
nw99qdt


________________________________________________________________________

EXAMPLE:
/user/test.sh -c

while getopts :cp: opt; do
  case $opt in
    c)
      echo "client"

      if [[ $OPTARG = -* ]]; then
        ((OPTIND--))
        continue
      fi

      echo "(c) argument $OPTARG"
    ;;
	 p)
      echo "policy"
    ;;
    \?)
      echo "WTF!"
      exit 1
    ;;
  esac
done


________________________________________________________________________

Steve Bourne (the creator of the Bourne Shell) suggests in The UNIX system to use the unique process identifier (PID) of the shell script as part of the file name. Since the process id of the script is always available via the environment variable $$, we could rewrite the script as follows:

# $$
9117: not found
#


________________________________________________________________________


# viman - start "vi" with a manual page

Tmp="${TMPDIR:=/tmp}/vm$$"

# Assure the file is removed at program termination
# or after we received a signal:
trap 'rm -f "$Tmp" >/dev/null 2>&1' 0
trap "exit 2" 1 2 3 13 15

EXINIT="set ignorecase nowrapscan readonly"
export EXINIT

man "$@" | col -b | uniq > "$Tmp" || exit

[ -s "$Tmp" ] || exit 0		# file is empty
head -1 < "$Tmp" |
    grep 'No.*entry' && exit 0 # no manual page

${EDITOR:-vi} "$Tmp"
________________________________________________________________________

Use $* instead of "$@"

You probably know the difference between "$@" and $*. Both stand for "all arguments specified on the command line". "$@" does preserve whitespace, while $* does not. 

________________________________________________________________________

##Code written by James to take user input and add to a text file until null

#!/usr/bin/bash
TMPDIR="/usr/openv/netbackup/logs/useradhoc";
FILELIST=$TMPDIR/$CLIENTNAME.`date +"%m%d%y%H%M%S"`;
echo "Press Enter at blank line when done."
echo "_____________________";
while true; do
		read LINE;
		echo $LINE >> $FILELIST;
	if [ -z "$LINE" ]; then # -z mean if its null
			break;
	fi
done
cat $FILELIST
________________________________________________________________________

set -o verbose
diff -s -U0 $HOSTS $HOSTSMOD|egrep -v "@@"
--- /etc/hosts.testing  Thu Jun 28 14:10:45 2012
+++ /usr/openv/netbackup/logs/hostmod/hosts.8034        Thu Jun 28 14:51:06 2012
-3.32.199.12    emcecch02
+234234234      test:wq!
+:wq!
set +o verbose

________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________


________________________________________________________________________
