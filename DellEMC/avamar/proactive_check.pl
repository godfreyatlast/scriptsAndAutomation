#!/usr/bin/perl
#
#use warnings;
#use strict;
#  $Id: //AV/main/pss/support/proactive_check.pl#90 $
# $Revision$ 
#
# Performs the following:
#
# Change Log:
# 3.00 10/7/2013: fixed dellblk skipping firmware update if hybrid gen2/3 grid. added option to --preupgrade flag to specify version. updated ESG's to KB's. added last CP to lasthfs, rewrote to use lscp instead of cplist. added time stamp to last hfs, last cp for --preupgrade. added run date timestamp to screen output. added check for xfs bug kernel. fix dellblk not printing node. added metadatacapacity check for preupgrade.
# 3.01 10/07/13: fixed susekernel not skipping suse nodes and err messages not printing. changed xfs but to error for single node, info for multi node. fixed ave always identifying as ave-4.
# 3.02 10/07/13: fixed not skipping metadata check for pre v7.
# 3.03 10/17/13: changed stripecount from nodelist to ping.
# 3.04 10/21/13: fixed susekernel not working for nodes over 10.
# 3.05 12/04/13: fixed dell 32851 w/bad kernel not working for nodes over 10. added gen2 err for v7 upgrade. added % to metadata >100. only run pool check for --preup. fixed bad h/w id for gen1/2 1TB and Gen1 1TB.
# 3.06 12/18/13: changed 6.1.1-98 mcs to 57178. added mcs 57597 for 612-47
# 3.07 1/7/14: changed bad node type to print to screen. added 7.0.1-56. added EOSL check for preup. added gen=0 nodelist check. incl xfs bug for --preup. eliminate false positive for swtich config. check for bad files for mc flush. check hostnames are resolvable. dellblk 53723 to 55276
# 3.08 2/6/14: removed dellblk 32851 and badkernel checks dellblk 55276 works fine. added check for cust h/w for preup. added 701-61. added mcs hotfix 58025. replaced mcs hotfix 48263 with 50844. added check to lasthfs to make sure failed hfshchecks have been cleared. fixed repl partners printing same partner from multiple repl cfgs. changed gsan settings for AER. Print security update level. add flags to hc_results. changed dell om tools from 110486 to KB95326.
# 3.081 2/6/14 fix security update print awk if no secupd.
# 3.082 2/6/14 fix partno testing look for z00 instead of 100
# 3.083 2/19/14 fix vmware printing no generation and unknown supplier
# 3.09 2/?/14 changed 58025 to 59131, added mcs 701-61 58932, changed metadata capacity check to incl cpoverhead
# 3.091 4/1/14 added ddver check for 7.0. changed av.dd.remediation to dpadbrc. changed disclaimer to always print. changed unknown h/w to kb 182356. added green a, green b to metadata. changed cpoverhead calc.
# 3.092 4/2/14 removed testing code allowing non-DD to go thru metadata check
# 3.10 4/14/14: added gen3 3.3tb metadata check stuff. changed mcs 57892 to 60601
# 3.11 5/12/2014: added gsan 59538. added DD SN to output. added status.dpn look for WARNING (like warning cp suspended). check gen4s h/w. dd repl avtar bugs 57063, 57064, 53090, 188345. moved node_count to nodexref from getavamarver. check mcversion for newer hotfix than known.  replace mcspatch 60601 with 186594. added warning for addnode and <611 for gen4s h/w. added rpt if EAR. check to print rest api info. added ATO to ADM(e) 4.0.b check. added --preupgrade target version output. added MAN/AER IP.
# 3.111 5/12/2014: fixed checkutilnode output for dir not writable.  
# 3.112 5/13 fixed checkutilnode output for dir not exist. 
# 3.113 5/13 removed 51534 gen4s firmware. skip 56915 gen4s for preupgrade. changed mcs 701 bug 186594 to 187880
# 3.114 5/14 emc fw 56915 is 0d00 not 0c00.
# 3.115 5/16 update sles dell firmware to know about newer 12.10.4-0001.
# 3.12 6/2 changed mcs 57178 to 190410. added 7.0.2-43 7.1.0-302. added hardening info. ignore brocade switches. new dell hardware routines. support enable ftp for v7.1+. ddv5.4 reqd for v7.1.  added upgrade path logic. mcs 187880 with 190109 on 7.0.1-61, 188249 with 188969 on 7.0.0-427. added autoupdate. added getinstalledversion. 
# 3.13  7/14 added virtual drive check for emc hardware. look for extra kernel RPMs. avhardening consistent rpms on each node. secupd consistent on each node. fix ssh/cat mapall for 7.x
# 3.131 7/23 kernelcnt printing wrong node & not the count. added 7.0.2-47
# 3.132 7/24 kernelcnt skip non-suse nodes. changed BRDC contact to RCM SME & AppEng
# 3.14 8/20 added paritysolvercheck and paritysolver. completely removed badkernel and 32581 replace with dellblk 55276. changed susereporefresh to ignore nfs package. sendemail allow parameter to specify subject and contents. change mcs bugs 701-61 192748, 700-427 194587. rearragned log opening. added checkopenfiles. 
# 3.141 8/25 fixed checkswap looking at util node
# 3.142 8/25 update mcs 190410 to 194399. add mcs 195510.
# 3.142 8/27 remove running gsan checkopenfiles, only run on 7x.
# 3.143 9/15 no controller check fix. paritysolver warn=2 change. swap space 16gb to 12gb ddr nodes only. ddrmaint read-ddr-info fix stderr debug
# 3.144 9/15 use version not on RHEL - fix ddr version check.
# 3.145 9/18 added 7.1.0-370.  fixed gsanpatches not identifying when a grid was actually patched
# 3.146 9/18 fixed gsanpatch check
# 3.147 9/22 fixed suserepo refresh only check for SLES.
# 3.2 10/9 changed metadata to print green b config changes. tla updates.  added networker not compatible with 7.1.0
# 3.21 10/20 changed green b to yellow a+
# 3.3 10/23 added --metadata flag. allow /var/log/messages to be group admin. fix dell noctl.
# 3.4 12/3  add kb to hardware id fail. add check for shell != bash.  add check for ifcfg-*.* to checketh. new check for shellshock RCM RP2014-0004 in oscheck. test mapall working. for preup check repo empty. look for arp cache overflow. fixed emailhome insert escape ' failing since 3.1. added ear and 7.1.0 upgrade warn. incl most recent capacity.sh. ddos 5411 req for 7.1 upgd
# 3.41 12/3 fixed getconfiginfo being called twice. moved disk fw kb121506 to dell block update.
# 3.42 12/4 added .noftp creation when no ftp. update paritysolver to 1.2
# 3.421 12/5 fixed rptsecupd
# 3.422 12/8 changed 7.0.2-43 mcs hf to 197922. fixed mcspatches to remove HF from hotfix for comparison.
# 3.5 1/19 added 7.1.1-41. added hf195191. fix checkncq for mixed emc/dell
# 3.51 1/19 oops
# 3.52 moved cold pwrsupply to not run with preup. removed vba version for @supported
# 3.521 moved cold pwrsupply to run with preup target of 7.1.1
# 3.522 syntax error
# 3.523 bad check for cold power "01 00" s/b handling " 01 00"
# 3.524 bad check for cold power "01 00" s/b handling " 01 00"
# 3.6 3/2 change cold power to point to KB194024 . fix checkopenfiles not clearing $e. fixed --help. added ndmp 223295/223292. added shellshock for all runs. changed checketh extra ifcfg iface to allow bond\d.\d
# 3.61 3/2 chkproxy always failed
# 3.7 4/29 added log timing. added new vba vers. added new vba bugs. changed chage to check all users. require version on --preupgrade=x.x.x.  fixed vba config settings and gripes. 
# 3.71 4/29 fixed mcs patch 228585 for all runs from testing code left in.
# 3.72 5/27 leap second hf229168
# 3.73 5/27 leap second hf229168
# 3.74 6/18 leap second check for patched kernel version. Added AVE check for memory requirements. Added VBA version 1.1.1-50, NetWorker connectivity check, NetWorker version compatibility, Data Domain version compatibility,  consistent proxy versions, /clients/iragent enabled and CID match,  hotfixes  to latest available. Fixed AVE size recognition. Added VBA nsrexecd running, nsrexecd version
# 3.741 6/19. fixed config changes erroneously printing (moved version printing using $msg variable).
# 3.75 6/19. Added --servicemode flag.
# 3.76 7/2? added 7.1.2-21. require --preupgrade to specify version. removed EMS/dtlt for 720 added EMT/avi. v7.2 and ddos req. 7.2 and upgrade path. 7.2 gen3. 
# 3.77 10/7. added intel block update but disabled. added megaraid_sas bug and megalodon drive check. added bug 235341 and related for dtlt security. fixed suserepo for new kickstars. added all vba verisons. changed checkperms messages to rw-r.- from rw-rw-.  for preupgrade check jakarta tomcat directory. fixed repoempty using wrong array. 
# 3.771 10/9 fixed new perms on secupd run as root. fixed repoempty has to run on utility node with --all+. fixed dtltsec md5 for 7.1.1.  updated mcs patches to latest 235648,228585,234040,225423,235000. ndmp 229389. 


use DBI;
use Time::Local;
use POSIX;
use Switch;
use XML::Parser;
use HTML::Entities;
use File::Copy;
use MIME::Base64;
use Net::SMTP;
use List::Util 'max';
use File::Copy;
#use version;
use Data::Dumper;


# Program name and version
$PROG = "proactive_check.pl";
$PROGVER='3.771';
chomp($logdate = `date +%Y%m%d-%H%m%S`);
$TMPFILE = "/tmp/proactive_check-$logdate.tmp";

# "globals"
my ($NODE_COUNT, $AVAMARVER, $DATANODEVERSION, $MCSERVER_VERSION, $EMSERVER_VERSION,$MCDBOPEN, $VERSNUM, %PARTLIST, $GOTCONFIGINFO,
    $OS, $MANUFACTURER, $RACADM, $HOSTNAME, %CONFIG, %NODELIST, @NODES, @OMREPORT_STORAGE, $NODETYPE,
    $DDCNT, @DD_INDEX, %DD, %NODE_INFO, $AVMGR_VERSION, $VMWARE_CLIENT, $MAINT_RUNNING, %CMDTOOLSUMMARY, %xmltree, %NODE_XREF ,
    $METADATA_CAPACITY, $VBA, $VBA_RPM, $AVAMARHF, $VBA_VERSION);

$|=1;
$SUCCESS=`echo -en "\\033[1;32m"`;
$FAILURE=`echo -en "\\033[1;31m"`;
$WARNING=`echo -en "\\033[1;33m"`;
$NORMAL=`echo -en "\\033[0;39m"`;
$INFO=`echo -en "\\033[0;36m"`;
$ALL = -r '/usr/local/avamar/var/probe.xml' ? '--all+' : '--all';
$VERBOSE=1;  # change default behavior to be verbose

########### Define known versions  ##########
@v36x=qw(3.6.0-106 3.6.1-56);
@v37x=qw(3.7.0-135 3.7.1-80 3.7.1-93 3.7.1-100 3.7.2-137 3.7.2-57 3.7.3-13);
@v3x=(@v36x,@v37x);
@v40x=qw(4.0.1-30 4.0.2-27 4.0.3-18 4.0.3-24 4.0.4-59);
@v41x=qw(4.1.0-1470 4.1.1-340 4.1.1-400 4.1.2-33 4.1.2-34);
@v4x=(@v40x,@v41x);
@v5x=qw(5.0.0-407 5.0.0-409 5.0.0-410 5.0.1-32 5.0.1-400 5.0.1-401 5.0.2-41 5.0.3-29 5.0.4-29 5.0.4-30);
@v60x=qw(6.0.0-580 6.0.0-592 6.0.1-63 6.0.1-65 6.0.1-66 6.0.2-150 6.0.2-153 6.0.2-156);
@v61x=qw(6.1.0-276 6.1.0-280 6.1.0-333 6.1.0-402 6.1.0-9056 6.1.1-81 6.1.1-87 6.1.2-46 6.1.2-47);
@v6x=(@v60x,@v61x);
@v7x=qw(7.0.0-355 7.0.0-374 7.0.0-396 7.0.0-423 7.0.0-427 7.0.1-56 7.0.1-61 7.0.2-42 7.0.2-43 7.0.2-47 7.0.3-32 7.1.0-302 7.1.0-370 7.1.1-141 7.1.1-145 7.2.0-390 7.1.2-21 7.2.0-401);
########### VBA version
@vba=qw(7.0.60-11 7.0.61-5 7.0.62-10 7.0.63-8 7.1.60-4 7.1.60-12 7.1.61-6 7.1.61-10); 

@supportedversions=(@v3x,@v4x,@v5x,@v6x,@v7x,@vba);


###
### START MAIN
###
  chomp($HOSTNAME = `hostname -f`);
  setuplog();                    # Turn on logging 
  getargs();                     # Get args/values passed in from command line
  setuphclog();			 # Setup hc_results.txt log
  getUser();                     # Ensure script is being run by user admin
  checkutilnode();		 # Check that we are on the utility node
  openmcdb();
  nodexref();
  if ($RUN) {
     #print "Running $RUN only\n";
     if ($EVAL) {
       eval $EVAL;
     }
     &$RUN();
     exit 0;
  }
  shownotes();
  open(SETTINGS,">hc_settings.txt") if ($DO_HEALTHCHECK) ;
  getinstalledversion();	 # Get version of Avamar installed
  check_script_version();
  getuserdata() if ($LOGOFF);             # Get user input if logging off
  msg("Avamar Hostname",$HOSTNAME);
  msg("Target Upgrade Version",$UPGRADE_VERSION) if ($PREUPGRADE);
  my $msg=($AVAMARHF) ? "$AVAMARVER with $AVAMARHF" : $AVAMARVER;
  msg("Avamar Server Version",$msg,"");
  getavamarver();                 # Get Avamar gsan & rpm versions other routines depend on this running early
  getconfiginfo();                # get %CONFIG, %NODELIST, %SCHED

  msg("System ID", $NODELIST{'/nodestatuslist/nodestatus/0.0/systemid'});
###
### PROACTIVE SPECIFIC CHECKS
###
if (!$SKIP_PROACTIVE) {
# Mostly Informational
  servicemode();		 # See if service mode enabled
  gethardware();                 # Identify hardware
  getopersys();                  # Identify operating system
  getnodetype();                 # Get node type (deep or shallow)
  getdatadomain();		 # Get Data domain info
  getvba();			 # Get VBA Info/Versions
  upgdpath();			 # Upgrade Path
  getear();			 # Get ear encryption at rest status
  metadatacapacity();		 # Check meta data capacity
  aerplugin();		    	 # Check for AER plugin
  replpartners();		 # Check for replication source/target
  rptsecupdvers();		 # Report on Security Update version
  #security_updates();		 # Check for latest redhat security updates
  plugin_catalog();              # Print Plugin Catalog version
  checkversion();                # Check if version supported
  lastflush();                   # Check MCS & EMS last flushes
  lasthfs();			 # Check for last HFS time
  checketh();                    # Make sure ethernets are gb, autoneg, full duplex
  checktime();                   # Check avmaint time settings
  dpnctl_status();               # Check dpnctl status output
  status_dpn();                  # Check status.dpn output
  bug13216();                    # Check bug 13216 mcs flush cant be restored
  duplicateip() ;                # Check for duplicate IP's
  license();			 # Check for license file and unexpired
  checkclients();		 # Check specific client plugins
  adtcheck();			 # Check for ADT existence
  atocheck();			 # Check for ATO existence
  ddvers();			 # Check for minimum datadomain version
  rotatesecure();		 # Rotate secure bug 38834
  etcprofile(); 		 # Check for /etc/profile wrong
  ipmi(); 			 # check IPMI status
  switchconf();			 # Check switch configuration
  susekernel();		 	 # Check if SUSE has been up and may run into 208 day bug.
  etchosts();			 # Check for name resolution
  kernelcnt();			 # Check for Kernel RPM count
  avhardening();		 # Check for avhardening installed
  oscheck();			 # Check O/S things
# SKIP FOR UPGRADES
  if (!$PREUPGRADE and !$ADDNODE){ 
    bondconf();                  # Check Bonding config
    vm_dd_bug39571();		 # Check for bug 39571, vm + dd hfs fails msg_err_ddr
    ddgcoob();			 # Data Domain gcoob.pl installed
    auditd();                    # Check suse for auditd running
    checkascd();                 # Check ascd status
    cronrunning();               # Check cron
    checkconfig();               # Check avmaint config settings
    checkswap();                 # Verify swap is turned on and consistent
    fileperms();		 # Check file permissions (/var/log/messages)
    checkpointxmlperms();        # Check checkpoint.xml owner/perms
    bug13252();                  # Check bug 13252 applied
    suseksv25();		 # Check if SUSE kickstart v25 was used
    susereporefresh();		 # Check for SUSE repository refresh
    hfschecktime();              # Check hfscheck run time
    check_repl();                # Check replication cron config
    sitename();                  # Make sure ConnectEMC name is <32 bug19066
    fullhfscheck();              # replaces --useschedule with --full
    bug10449();                  # Check for bug 10449 clean_emdb
    noderestart();               # Check for individual nodes restarted
    checkperftriallimit();       # Check perftriallimit setting
    gccountcheck();              # Check deep nodes for gccount flags
    nousehistory();              # Check nousehistory on gc_cron
    mandatoryupgrade();          # Check if any mandatory upgrades
    gsanpatches();               # Check if GSAN needs to be patched
    mcspatches();		 # Check if MCS needs to be patches
    replavtar();                 # Check bug 13914 applied (labels>48 chars fail)
    qadir();			 # Check for leftover QA directories
    checkopenfiles();		 # Check for open files parameters nodefile, file-max
    checkmessages();		 # Check /var/log/messages
    dtltsecurity();		 # Check for bug 235341 dtlt vulnerability
  }  

# ONLY RUN FOR UPGRADES
  if ($PREUPGRADE) {
#    checkgsanpct();		 # Check gsan % for --preupgrade
    repoempty();		 # Check if /data01/repo dirs are empty
    tomcatdir();		 # Check if jakarta tomcat dir exist
    upgradepath();		 # Check upgrade path
    getrestapi();		 # Get REST API version if installed
    lastemail();		 # Check connectemc last email date
    chage();			 # Check expired logins
    replforceaddr();		 # Check for replication settings (forceaddr)
    stunnelvers();		 # Check for stunnel version bug 45983
    ldapauth();			 # Check for existing ldap auth esc 4320
    adsinfo();			 # Check for ADS - Downloader service.
    greenvillehotfix();		 # Check for Greenville Hotfix applied
  }

# ONLY RUN FOR ADDNODE
  if ($ADDNODE) {
    bug13252();                    # Check O/S reserved (also done when not preguprade)
    stunnelvers();		 # Check for stunnel version bug 45983
    gen4sver(); 		 # Warn if vers <6.1 to not add gen4s
  }

# ONLY RUN FOR VBA
  if ($VBA) {
    chkspace();			# Check /space
    chkproxy()			# Check if proxies are running
  }

###
### DELL SPECIFIC CHECKS
###
if ($MANUFACTURER =~ "dell") {
  checkostools();			# Check OS Tools are installed
  virtualmedia() if (!$PREUPGRADE);     # Ensure that virtual media device is not enabled (Dell nodes ONLY)
  dellomlogs() if (!$PREUPGRADE);       # Check for Dell OM logrotate bug 10783
  checkncq();             # Check for NCQ / interposers
  getdellstorage();	    # Get Dell status
  checkdellstorage();      # Check Dell Status
 # checkstorage();         # Check storage subsystem, controllers, virt disks, phys disks
 # omchassis() ;           # Check all h/w, fans, memory, disks, cpu, etc.
}

###
### EMC/Intel specific checks
###
if ($MANUFACTURER =~ "emc") {
  getcmdtool();
  checkemcstorage();
}

# END PROACTIVE CHECK
paritysolvercheck(); # Run before end because it starts up background process that uses same debug log.
sendemail();
}

###
### HEALTHCHECK SPECIFIC CHECKS
###
if ($DO_HEALTHCHECK) {

  print "\n";
  get_backup_info();         # Get logs of any failed, completed w/exceptions, and 5 highest capacity, time, change rate clients
  get_repl_info();         # Get replication report and configuration
  sched();            # Get schedule information

# Get capacity and garbage collection info

  print("HEALTHCHECK:  Creating hc_capacity.txt\n");
  print LOG "\n\n\n### ".localtime()." ### Starting capacity_info\n";
  open(OUTPUT,">hc_capacity.txt");
  $capacity_days=30;
  capacity_info();
  $capacity_days=60;
  capacity_info();
  $capacity_days=90;
  capacity_info();
  close OUTPUT;

  print("HEALTHCHECK:  Creating hc_settings.txt\n");
  get_errlog();
  get_esmlog();
  get_maintlogs();

  # FINISH HEALTHCHECK

  $dbh->disconnect;
}

###
### LOGOFF SPECIFIC CHECKS
###
if ($LOGOFF) {
  backup_config();
  test_flush();
  check_capacity();
  logoff_report();
}

if ($DO_HEALTHCHECK) {
  printboth("All logs have been included in hc-${HOSTNAME}.tgz\n");
  print LOG `tar czf hc-${HOSTNAME}.tgz hc_*`;
}

close(LOG);
close (MAPALL);
unlink($TMPFILE);

$results=`echo -e "\n\n\n\n" >> hc_history.log; cat hc_results.txt >> hc_history.log`;
print "\nSee detailed ERROR information in hc_results.txt\n";
print "\nFINISHED\n";
exit 0;
########## End Main ##########


############### Start sub getargs() ###############
# Check for valid command line arguments.
sub getargs {

  my $invalid = 0;
  print LOG "ARGS: ";
  foreach(@ARGV) {
    if($_ !~ /^--([^=]+)=?(.*)$/) {
      print "Invalid command line argument: $_\n";
    exit;
    }
    my $arg = $1;
    my $value = $2;
    print LOG "$arg='$value'  ";

    if (grep /--cap/, @ARGV) {
      #*OUTPUT=*STDOUT;
      capacity_info(); exit;
    }

    switch ($arg) {
      case "help"  { doHelp(1); exit 0;}
      case "version"     { print "$PROG: Version $PROGVER\n"; exit 0; }
      case "debug"     { $DEBUG="YES"; }
      case "run"     { $RUN=$2; }
      case "eval"     { $EVAL=$2; }
      case "hc"          { $DO_HEALTHCHECK=1 }
      case "hco"         { $DO_HEALTHCHECK=1; $SKIP_PROACTIVE=1;  }
      case "nopc"         { $SKIP_PROACTIVE=1;  }
      case "logoff"      { $LOGOFF =1; }
      case "verbose"      { $VERBOSE=0; }
      case "sched"      { $sched=1; }
      case "force"      { $FORCE=1; }
      case "capacity"      { $capacity=1; }
      case "replrpt"      { $replrpt=1; }
      case "days"      { $IN_DAYS=$value; }
      case "wide"      { $WIDE=1; }
      case "update"      { unlink "/home/admin/.noftp"; }
      case "preupgrade"      { $PREUPGRADE=1; $UPGRADE_VERSION=$value }
      case /client/   { $CLIENT_VERSION_CHECK=1; $RUN=checkclients; $UPGRADE_VERSION=($value);}
      case "addnode"      { $ADDNODE=1; }
      case "darksite"      { $DARKSITE=1; }
      case "text"      { $SUCCESS="";$NORMAL="";$FAILURE="";$WARNING=""; $INFO=""}
      case "cpoverhead"      { $CPOVERHEAD=$value;}
      case "retention"      { $METADATA_RETENTION=$value;}
      case "override"      { $OVERRIDE=$value;}
      case "paritysolver"      { paritysolver(); exit;}
      case "metadata"      { $METADATA_CAPACITY=1; $RUN="metadatacapacity";}
      case "servicemode"      { if ($value) {servicemode($value); exit;} 
                      else {print "Invalid option. Format is --servicemode=<hours>  NOTE: Only 3 hours is currently supported\n\n";exit } }
      else            { print "Invalid Command line: --$arg\nTry --help\n"; exit; }
    }
  }
  print LOG "\n";
  if ($UPGRADE_VERSION !~ /\d\.\d\.\d/ and $PREUPGRADE)  {
     print "ERROR:  Version must be included with --preupgrade=n.n.n flag.  Example: --preupgrade=7.0.0-395 or --preupgrade-7.0.0\n";
     exit 1;
  }
  if ($sched) { sched(); exit; }
  if ($replrpt) {  get_repl_info(); exit; }

  print LOG "\n\n\n### Exit getargs\n";
}
############### End sub getargs() ###############


########## Start sub doHelp() ##########
# Help/Usage sub routine
sub doHelp {
    print <<"xxEndHelpxx";

$PROG $PROGVER

With no command line options summary info will be printed to the screen and detailed errors
will go to the file hc_results.txt.  With the --hc flag healthcheck information will be
gathered into various hc_ files and tar'd into a single file with the name of the server.

The --logoff option will run a few extra checks to make sure the grid has been placed
in a healthy operating state.  

--addnode    	  Run special add node checks and skip unnecessary checks.
--capacity	  Print capacity info to screen (like capacity.sh). Use --capacity --help for additional commands to use with --capacity
--darksite	  Removes latest script version check and sending results to Avalanche
                  (Only need to run it once with this flag)
--days		  Number of days to include in sched, capacity, replrpt
--force		  Force Critical checks to pass for --logoff
--hc		  Perform Grid Health Checks
--help		  Display the help screen
--logoff	  Check grid health and settings before logging off
--replrpt	  Print replication info to screen (like replrpt.sh)
--sched		  Print schedule info to screen (like sched.sh)
--text		  Removes ANSI color codes from output
--update	  Allows FTP check once again (but does not remove darksite flag)
--version	  Display the program version
--wide		  Print sched with more data points
--clientvers[=X]  Check Client Versions. Current GSAN Version is used unless you send in the version
                  Example:  --clientvers=7.0.0-123
--preupgrade[=X]  Run special pre-upgrade checks and skip unnecessary checks. Most recent version assumed
                  Override like:  --preupgrade=7.0.0-423
--cpoverhead=N    Provide an estimated daily checkpoint overhead percent to metadata capacity check
--retention=N     Provide the typical backup retention in days
--servicemode=N	  Enable service mode for N hours.  Prevents CLM from creating new service requests.  Currently only 3 hours is supported.

If there are any problems with the script please get the hc_proactive_check.log.
Every command and check run is appended to the log file.

xxEndHelpxx
}

########## End of sub doHelp() ##########


########## Start setuplog ##########
sub setuplog {
 
  $DEBUG=grep(/--debug/i,@ARGV);

  $logfile = "./hc_proactive_check.log";
  if ($logfile) {
#    print "Logging to $logfile\n";
    if ($DEBUG) {
      open (LOG, ">" . "$logfile") || die "Unable to open logfile ($logfile) for writing: $!";;
    } else {
      open (LOG, ">>" . "$logfile") || die "Unable to open logfile ($logfile) for writing: $!";;
    }
  }
  print LOG "\n\n\n###################################################################################################\n";
  print LOG "###   STARTING $PROG $PROGVER $logdate\n";
  print LOG "###################################################################################################\n";
}
########## End autoLog ##########

########## Start setuphclog ##########
sub setuphclog {
  print LOG "### ".localtime()." ### Starting setuphclog\n";
  open(RESULTS,">hc_results.txt");
  print RESULTS "========================================================================\n";
  print RESULTS "Run Date: ".localtime()."  Version $PROGVER\n";
  print RESULTS "========================================================================\n";
  print RESULTS "command line: @ARGV\n";
  printboth("\nDISCLAIMER: The results from this script are intended for the exclusive use of EMC Support & Development Engineers to diagnose potential problems so that they can use their trained skills to see exactly how the issues might or might not affect an individual server's performance\n\n");
}
########## End setuphclog ##########


########## Start sub getUser() ##########
# Get the name of the user executing the script.
# If the user is not admin or dpn, exit
sub getUser {
  print LOG "### ".localtime()." ### Starting getuser\n";
  my $curuser = `whoami`;
  chomp ($curuser);
  if (($curuser ne "admin") && ($curuser ne "dpn")){
    print "Please log in as user admin or dpn, and re-run the script.\n";
    exit;
}
}
########## End sub getUser() ##########

########## Start sub checkutilnode ##########
sub checkutilnode {
  print LOG "\n\n\n### ".localtime()." ### Starting checkutilnode\n";
  if ( ! -e "/usr/local/avamar/var/mc/" ) {
    print "\nERROR:  This program must be run on the Utility node.\n\n";
    exit;
  }
  if (!-w ".") {
    print "\nERROR:  This program must be run in a directory that you have write permissions\n\n";
    exit ;
  }
  for(<0.*>){
    if(!-w $_) {
      print "\nERROR: This program needs to write to $_ but does not have write permissions\n\n";
      exit;
    }
  } 

  my $result=`/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; mapall $ALL --noerror '[ -d tmp -a ! -w tmp ] && echo NotWritable || echo OkWritable'" 2>&1 `;
  my $e="";
  my %nodeok;
  for(split(/\n/,$result)) {
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/){
      $node=$1;
      $nodeok{$node}=1;
      print LOG "add node $node\n";
    }
    if (/^NotWritable/) {
      printboth("\nCRITICAL ERROR: Node $node /home/admin/tmp is not writable" );
      print("\nCRITICAL ERROR: Node $node /home/admin/tmp is not writable" );
      $e=1;
    }
    if (/^OkWritable/) {
       delete $nodeok{$node};
       print LOG "delete node $node\n";
    }
  }
  if ($e) {
    printboth("\nRESOLUTION: Check/Fix permissions on /home/admin/tmp directories\n" );
    print("\nRESOLUTION: Check/Fix permissions on /home/admin/tmp directories\n\n" );
    exit 1;
  }
  if (%nodeok ) {
    for (sort keys %nodeok) {
      print ("ERROR:  Node $_ did not respond properly to mapall command\n");
    }
    print("RESOLUTION: Fix ssh keys.  Test by loading keys as admin:\nssh-agent bash\nssh-add ~/.ssh/dpnid\n");
    print("            \nThen try these commands:\nmapall date\nmapall --user=root date\nmapall $ALL date\nmapall $ALL --user=root date\n\n");
    exit 1;
  }
}
########## End sub checkutilnode ##########



########## Start msg ##########
sub msg {
if ($VERBOSE eq 1) {
  my $col="";
  my $p=" ".$_[1];
  if ($_[1] eq "INFO") { $col=$INFO}
  if ($_[1] eq "PASSED") { $col=$SUCCESS}
  if ($_[1] eq "FAILED") { $col=$FAILURE; $p="*FAILED*"}
  if ($_[1] eq "WARNING") { $col=$WARNING}
  my $norm=($col) ? $NORMAL : "";
  my $msg2=($_[2]) ? $_[2] : "";

  my $line=sprintf("%-30s %s%s%s %s\n",$_[0],$col,$p,$norm,$msg2);
  print $line ;
  my $line=sprintf("%-30s %s%s%s %s\n",$_[0],"",$p,"",$msg2);
  print RESULTS "# --> $line";
  print LOG "\n" if ($_[1] eq "FAILED");
  printf LOG $line ;
}
}
########## End msg  ##########

########## Start printboth ##########
# Output to both screen and LOG and results file
sub printboth {
  print LOG "@_";
  print RESULTS "@_";
  return if ($VERBOSE eq 1 and !$DEBUG );
#  print "@_";
}
########## End printboth ##########

########### Start max ##########
#sub max {
#    splice(@_, ($_[0] > $_[1]) ? 1 : 0, 1);
#    return ($#_ == 0) ? $_[0] : max(@_);
#}
########## End max ##########

########## Start mapall ##########
# $1 = flags (--all)  $2=command to copy to nodes and run $3=1=dont error process
sub mapall {
  my $mapalltime=time;
  $TMPMAPALL = "proactive_check-$logdate.mapall";
  open (MAPALL, ">/tmp/".$TMPMAPALL);
  print MAPALL "$_[1]\n";
  close (MAPALL);
  print LOG "mapall: $_[0] $_[1]\n";
  my $usekey=qq[ /usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null ];
  my $result=`$usekey; mapall --parallel $_[0] copy /tmp/$TMPMAPALL >$TMPFILE 2>&1 "`;
  if ($? != 0 ){
    printboth("ERROR: mapall copy command failed.  Review log file or $TMPFILE\n\n");
    print "CRITICAL ERROR: mapall copy command failed.  Review log file or $TMPFILE\n\n";
    open(CMD_PIPE,$TMPFILE);
    while (<CMD_PIPE>) {
      chomp;
      print LOG "$_\n";
    }
    close(CMD_PIPE);
    exit 1;
  }
  $cmd=qq[ $usekey; mapall  --parallel --capture --noerror --givestatus $_[0] '(sh ./tmp/$TMPMAPALL; rm -f ./tmp/$TMPMAPALL) 2>&1 ' 2>&1 | 
sed -e '/^Using .usr.local.avamar.var.probe\\|^(0\\..*) ssh /d' -e 's/^(0.\\(\\S*\\))\\s*cat\\s*/(0.\\1) ssh /' >$TMPFILE " ];
  $result=`$cmd`;
  if ($? != 0 ) {
    printboth("ERROR: mapall command failed.  Review log file or $TMPFILE\n\n");
    print "CRITICAL ERROR: mapall command failed.  Review log file or $TMPFILE\n\n";
    open(CMD_PIPE,$TMPFILE);
    while (<CMD_PIPE>) {
      print LOG "$_";
    }
    close(CMD_PIPE);
    if ($3==1) { return 1; }
    exit 1;  
  }
  print LOG ("mapalltime: ". (time-$mapalltime) ."\n");
  unlink "/tmp/$TMPMAPALL";
  return 0;
}
########## End mapall ##########

########## Start getinstalledversion ########
# Just get installed version from rpm
sub getinstalledversion {
  print LOG "\n\n\n### ".localtime()." ### Starting getinstalledversion\n";
  open(FILE,"rpm -qa | grep dpnserver | sort|");
  while(<FILE>){ chomp;
    print LOG "$_\n";
    $AVAMARHF.=", " if ($AVAMARHF);
    ($AVAMARHF .= $_ ) =~ s/dpnserver-// if ($AVAMARVER);
    ($AVAMARVER = $_ ) =~ s/dpnserver-// if (!$AVAMARVER);
  }
  if (!$AVAMARVER){
    printboth("ERROR: Unable to determine the Avamar version.\n");
    printboth("  Check that the Avamar RPM's are installed with command 'rpm -qa | grep dpnserver'\n\n");
    exit 1;
  }else{
    msg("Target Upgrade Version",$UPGRADE_VERSION) if ($PREUPGRADE);
    my $msg=$AVAMARVER;
    $msg.=" with $AVAMARHF" if ($AVAMARHF);
    msg("Avamar Server Version",$msg,"");
    $VERSNUM = $AVAMARVER;
    $VERSNUM =~ s/\.//g;
    $VERSNUM =~ s/-/./;
    print LOG "VERSNUM=$VERSNUM\n";
  }
}
########## End getinstalledversion ########

########## Start getavamarver ##########
# Determine the versions of all components
sub getavamarver {
  print LOG "\n\n\n### ".localtime()." ### Starting getavamarver\n";
  my ($lastversion,$e);

    # Get versions for each node 
    $cmd=qq[  /home/admin/gsan --version; md5sum /home/admin/gsan ];
    mapall("",$cmd);
    open(CMD_PIPE,$TMPFILE);
    while (<CMD_PIPE>) { chomp;
      print LOG "$_\n";
      if (/node (.*?) (.*?) .*not responding, removing/) {
        printboth("ERROR: Node $1 ($2) Not responding. All checks may not be correct\n");
        msg("All Nodes Responding","FAILED");
        print "\n$_\nprogram exiting.\n\n";
        exit 1;
      }
      if ( $_ =~ /^ .version/ ) {
        my ($foo, $version)=split(' ', $_ , 2);
        print LOG "--> found node with $version\n";
        if (!($version eq $lastversion) && (defined($lastversion)) ) {
          printboth( "ERROR: GSAN versions do not match on data nodes\n");
          printboth( "       Found $lastversion and $version\n\n");
          $e="yes";
        }
          $lastversion=$version;
      }
  # Get md5sums for each node
     if ( $_ =~ /  gsan$/ ) {
      ($GSAN_MD5SUM, $foo)=split(' ', $_ , 2);
      print LOG "--> found node with md5sum $GSAN_MD5SUM\n";
      if (!($GSAN_MD5SUM eq $last_md5sum) && (defined($last_md5sum)) ) {
        printboth( "ERROR: GSAN versions do not match on data nodes\n");
        printboth( "       Found $last_md5sum md5sum and $GSAN_MD5SUM\n\n");
          $e="yes";
      }
        $last_md5sum=$GSAN_MD5SUM;
     }
    }
    my $results=`/usr/local/avamar/bin/gsan --version | grep "^ .version:" `;
    my ($foo1,$bingsan)=split(" ",$results,2);
    chomp($bingsan);
    print LOG "/usr/local/avamar/bin/gsan version: $bingsan\n";
    if ($bingsan ne $lastversion) {
      printboth( "ERROR: Data node GSAN version $lastversion does not match /usr/local/avamar/bin/gsan version $bingsan\n");
      printboth( "RESOLUTION:  See KB187478\n\n");
          $e="yes";
    }

    if ( -e "/home/admin/gsan" ) {
      $results=`/home/admin/gsan --version | grep "^ .version:" `;
      my ($foo2,$homegsan)=split(" ",$results);
      chomp($homegsan);
      print LOG "/usr/local/avamar/bin/gsan version: $homegsan\n";
      if ($homegsan ne $lastversion) {
        printboth( "ERROR: Data node GSAN version $lastversion does not match /home/admin/gsan version $homegsan\n");
        printboth( "RESOLUTION:  See KB199426\n\n");
          $e="yes";
      }
    }

    $DATANODEVERSION=$lastversion;
    if ($e) {
      msg("GSAN Version","FAILED");
    } else {
      msg("GSAN Version",$DATANODEVERSION);
    }

  chomp( $MCSERVER_VERSION=`mcserver.sh --version | head -1` );
  chomp( $MCSERVER_MD5SUM=`md5sum /usr/local/avamar/lib/mcserver.jar | awk '{print \$1}'`);
  $MCSERVER_VERSION =~ s/\s*version:\s*[v]*//;
  msg("MCS Version ",$MCSERVER_VERSION,"($MCSERVER_MD5SUM)");
  print LOG "MCS Version..: $AVAMARVER  md5sum $MCSERVER_MD5SUM\n";
  chomp(my $javarunning=`ps -aef | grep -c java`);
  printboth("# --> Java processes ($javarunning)\n");

  chomp( $EMSERVER_VERSION=`emserver.sh --version 2>&1| head -1` );
  chomp( $EMSERVER_MD5SUM=`md5sum /usr/local/avamar/lib/emserver.jar | awk '{print \$1}'`);
  $EMSERVER_VERSION =~ s/\s*version:\s*[v]*//;
  print LOG "EMS Version..: $AVAMARVER  md5sum $EMSERVER_MD5SUM\n";
#  msg("EMS Version ",$MCSERVER_VERSION);

  chomp( $AVMAINT_VERSION=`rununtil 60 avmaint --version | grep '^[ ]*version'`);
  if (!$AVMAINT_VERSION) {
    printboth("ERROR:  avmaint command does not appear to be working. Script cannot continue\n");
    print ("ERROR:  avmaint command does not appear to be working. Script cannot continue\n");
    exit 1;
  }
  $AVMAINT_VERSION =~ s/\s*version:\s*//;
  print LOG "AVMAINT Version: $AVMAINT_VERSION\n";

  chomp( $AVTAR_VERSION=`rununtil 60 avtar --version | grep '^[ ]*version'`);
  $AVTAR_VERSION =~ s/\s*version:\s*//;
  print LOG "AVTAR Version: $AVTAR_VERSION\n";

  chomp ($AVMGR_VERSION=`avmgr --version | grep '^[ ]*version:'`);

  $VBA=1 if (grep /$DATANODEVERSION/, @vba);
  
}
########## End getavamarver ##########

########## Start mcdb ##########
# OPEN MCS DATABASE
sub openmcdb {
  print LOG "### ".localtime()." ### Starting openmcdb\n";
  $dbh = DBI->connect("dbi:Pg:dbname=mcdb;port=5555", "admin", "" );
  if ($dbh) {
    $MCDBOPEN="yes";
  } else {
    printboth("ERROR:  Could not connect to MCS database. Some checks will be skipped\n");
    printboth("RESOLUTION:  Determine why MCS is not running\n\n");
  }
}
########## End openmcdb ##########

########## Start gethardware #########
# Get the hardware type
sub gethardware {
  print LOG "\n\n\n### ".localtime()." ### Starting gethardware\n";
  nodexref() if (!$NODE_COUNT);
  $MANUFACTURER = "";
  my $node_manu;
  my $cmd = qq[ /usr/sbin/dmidecode | grep -A2 'DMI type 1' | awk -F":" '/Manufacturer/ {print $2}' ];
  mapall("--user=root ".$ALL,"$cmd");
  open(CMD_PIPE,$TMPFILE);
  while(<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/) {
      $node=$1;
      next;
    }
    switch ($_) {
      case /Dell/i { $node_manu="dell" }
#      case /Intel/i { $node_manu="intel" }
      case /Intel/i { $node_manu="emc" }
      case /EMC/i { $node_manu="emc" }
      case /VMware/i { $node_manu="vmware" }
      else { $node_manu="other" }
    }
    if ($MANUFACTURER !~ /$node_manu/) {
      $MANUFACTURER.=", " if ($MANUFACTURER);
      $MANUFACTURER.="$node_manu";
    }
    $NODE_INFO{$node}{manufacturer}=$node_manu ;
    $NODE_INFO{"(0.s)"}{manufacturer}=$node_manu if ($NODE_COUNT==1 and $node eq "(0.0)" ) ;
    print LOG "Hardware: Node $node $node_manu ($NODE_INFO{$node}{manufacturer})\n";
  }
  msg("Hardware Manufacturer",$MANUFACTURER);
}
########## End gethardware ##########

########## Start getopersys #########
# Get the operating system
sub getopersys {
  print LOG "\n\n\n### ".localtime()." ### Starting getopersys\n";
  nodexref() if (!$NODE_COUNT);
  $cmd=q[ cd /etc;ls  *release | head -1 ];
  mapall($ALL,$cmd,1);
  open(CMD_PIPE,$TMPFILE);
  ($OS,$node)=("")x2;
  my $e="";
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/) {
      $node=$1 ;
      next;
    }
    next if (!$node);
    s/-release.*//;
    $_=lc($_);
    if (!/redhat|suse/) {
      printboth("ERROR:  Node $node Unknown Operating System ($_)\n");
      $_="unknown";
      $e="yes";
    }
    $NODE_INFO{$node}{os}=$_;
    $NODE_INFO{"(0.s)"}{os}=$_ if ($NODE_COUNT==1) ;
    print LOG "node $node o/s $_\n";
    if(index($OS,$_)<0){
      $OS.="," if ($OS);
      $OS.=$_;
    }
  }
  if ($e) {
    printboth("RESOLUTION:  Check if operating system is supported. Look at 'ls /etc/*-release'\n\n");
    msg("Operating System","FAILED");
  }
  msg("Operating System",$OS);
}
########## END getopersys #########

########## Start checkostools ##########
# Check OS Tools are installed
sub checkostools {
  print LOG "\n\n\n### ".localtime()." ### Starting checkostools\n";
  $RAN_OMREPORT="yes";
  gethardware() if (!$MANUFACTURER);
  if ($MANUFACTURER =~ /dell/){
    my $nodes=getnodes_hw("dell");
    if (!$nodes) {
      print LOG "no dell nodes found\n";
      return;
    }
    my $e="";
    $cmd=q[ which omconfig; which omreport; which racadm ];
    mapall("--nodes=$nodes --user=root",$cmd,1);
    open(CMD_PIPE,$TMPFILE);
    $OMCONFIG=1;
    $OMREPORT=1;
    $RACADM=1;
    while (<CMD_PIPE>) { chomp;
      print LOG "$_\n";
      $node=$1 if (/(\(0\..*\)) ssh/);
      if ( $NODE_INFO{$node}{manufacturer} !~ /dell/ ) {
        print LOG "Skipping node $node not dell: $NODE_INFO{$node}{manufacturer}\n";
        next;
      }
      if ( $_ =~ /no omconfig/  ) {
        $OMCONFIG=0;
        $e="yes";
        printboth("ERROR: Node $node does not have 'omconfig' command.  Some checks will be skipped\n");
      }
      if ( $_ =~ /no racadm in/  ) {
        $RACADM=0;
        printboth("\nERROR: Node $node does not have 'racadm' command\n");
      }
      if (/no omreport in/){
        $OMREPORT=0;
        printboth("\nERROR: Node $node does not have 'omreport' command.  Some checks will be skipped\n");
      }

    }
    if ($OMCONFIG eq 0 or $OMREPORT eq 0 or $RACADM eq 0 ){
      msg("Dell Open Manage Tools","FAILED");
      printboth("ERROR: Unable to find Dell Open Manager Tools (omconfig,omreport or racadm). Some checks will be skipped.\n");
      printboth("       See KB95326 for instructions to install Dell OM Tools.\n");
    } else {
      print LOG "found omconfig,omreport,racadm on all nodes\n";
       msg("Dell Open Manage Tools","PASSED");
    }
  }
}
########## End checkostools ##########

########## Start getomreport ##########
sub getomreport {
  print LOG "\n\n\n### ".localtime()." ### Starting getomreport\n";
  gethardware() if (!$MANUFACTURER);
  if ($MANUFACTURER !~ /dell/) {
    print LOG "Skipping. No Dell nodes\n";
    return;
  }
  my $nodes=getnodes_hw("dell");
  if (!$nodes) {
    print LOG "no dell nodes found\n";
    return;
  }
  checkostools() if (!$RAN_OMREPORT);
  if ($OMREPORT) {
    $cmd=q[ omreport storage controller controller=0];
    mapall("--nodes=$nodes",$cmd);
    open(CMD_PIPE,$TMPFILE);
    while(<CMD_PIPE>) { chomp;
      print LOG "omreport: $_\n";
      push(@OMREPORT_STORAGE,$_);
    }
  } else {
    print LOG "Skipping. No OMREPORT found\n";
  }
}
########## End getomreport ##########


########## Start virtualmedia ##########
# Check that virtual media is not mounted
sub virtualmedia {
  print LOG "\n\n\n### ".localtime()." ### Starting virtualmedia\n";
  gethardware() if (!$MANUFACTURER);
  if ($MANUFACTURER !~ /dell/) {
    print LOG "Skipping. No Dell nodes\n";
    return;
  }
  my $nodes=getnodes_hw("dell");
  if (!$nodes) {
    print LOG "no dell nodes found\n";
    return;
  }
  if ($RACADM) {
    $cmd=q[ racadm getconfig -g cfgracvirtual -o cfgvirmediaattached ];
    mapall("--nodes=$nodes --user=root",$cmd);
    open(CMD_PIPE,$TMPFILE);
    my $virtenabled=0;
    while (<CMD_PIPE>) {
      chomp;
      print LOG "$_\n";
      $node=$1 if (/(\(0\..*\)) ssh/);
      if ( $NODE_INFO{$node}{manufacturer} !~ /dell/ ) {
        print LOG "Skipping node $node not dell: $NODE_INFO{$node}{manufacturer}\n";
      }
      if ( $_ =~ /^1$/  ) {
        $virtenabled++;
        if ($virtenabled eq 1) {printboth("\n"); }
        printboth("ERROR: Node $node has virtual media enabled\n");
      }
    }
    if ($virtenabled>0) {
      printboth("  Disable virtual media on all nodes with the following command:\n");
      printboth("  mapall --nodes=$nodes --noerror --user=root 'racadm config -g cfgracvirtual -o cfgvirmediaattached 0'\n\n");
      msg("Dell Virtual Media Disabled","FAILED");
    } else {
      print LOG "Virtual media disabled\n";
      msg("Dell Virtual Media Disabled","PASSED");
    }
  } else {
    msg("Dell Virtual Media Disabled","WARNING");
    print LOG "WARNING: Virtual Media not checked.  'racadm' not installed\n";
  }
}
########## End virtualmedia ##########


########## Start checkperftriallimit ##########
sub checkperftriallimit {
  print LOG "\n\n\n### ".localtime()." ### Starting checkperftriallimit\n";

  my $perftriallimit=$CONFIG{'/gsanconfig/perftriallimit'};
  print LOG "perftriallimit is set to $perftriallimit\n";

  # Bug 13093-causes corruption during hfscheck
  if ($AVAMARVER eq "4.1.0-1470") {
    if ($perftriallimit!=0){
      printboth("ERROR: See bug 13093. Perftriallimit must be set to 0 on this version\n");
      printboth("RESOLUTION: Set it to 0 with this command: avmaint config --ava perftriallimit=0\n\n");
      msg("perftriallimit disabled","FAILED");
    } else {
      msg("perftriallimit disabled","PASSED");
    }
    return;
  }

# Check that perftriallimit is set to 3
  if ($perftriallimit<3 ){
    printboth("ERROR: perftriallimit should be set to 3 or higher. See KB116674\n");
    printboth("RESOLUTION:  Use the command: avmaint config --ava perftriallimit=3\n\n");
    msg("perftriallimit setting","FAILED");
  } else {
    msg("perftriallimit setting","PASSED");
  }
}
########## End checkperftriallimit ##########

########## Start checkswap #########
# Check that swap is enabled
sub checkswap {
   print LOG "\n\n\n### ".localtime()." ### Starting checkswap\n";
   getopersys() if (!$OS);
   getdatadomain() if (!$DDRMAINT_VERSION) ;
   $cmd=q[ /sbin/sysctl vm.swappiness; /usr/bin/free ];
   mapall("--all",$cmd);
   open(CMD_PIPE,$TMPFILE);
   my $susemsg="";
   my (%swappiness,%nodeused,%nodeswap);
   while (<CMD_PIPE>) {
     chomp;
     print LOG "$_\n";
     our $node=$1 if (/(\(0\..*\)) ssh/);
     $swappiness{$node}=$1 if (/vm.swappiness\s*=\s*(\d+)/);
     if ( $_ =~ /Swap/  ) {
       my ($f1,$swap,$used,$f2)=split();
       $nodeswap{$node}+=int($swap/1000/1000);
       $nodeused{$node}+=int($used/1000/1000);
     }
   }

   my ($noswap,$moreswap,$swapping)=""x3;
   for my $node (sort keys %nodeswap) {
     print LOG "node:$node used:$nodeused{$node} swap:$nodeswap{$node} os:$NODE_INFO{$node}{os}\n";
     $noswap.="ERROR: Node $node has no swap\n" if ($nodeswap{$node}==0);
     $moreswap.="ERROR: Node $node has $nodeswap{$node}GB of swap which is less than 12GB to 16GB required\n" if ($nodeswap{$node}<12 and $node ne "(0.s)" and $DDCNT>=1 and !$VBA);
     if ($nodeused{$node}>=2) { #2gb or more used
       if ($NODE_INFO{$node}{os} =~ /suse/i){ 
         $swapping.="ERROR: Node $node has used $nodeused{$node}GB of swap space. Swappiness is $swappiness{$node}\n";
         $susemsg=1;
       } else {
         $swapping.="ERROR: Node $node has used $nodeused{$node}GB of swap space\n";
       }
     }
   }

   my $swap="PASSED";
   if ($noswap) {
     printboth("${noswap}RESOLUTION: No swap is probably because /etc/fstab swap entry does not match partition table.\n");
     printboth("            Compare /etc/fstab to disk drives partition table (fdisk -l <device>)\n");
     printboth("            Any swap being used needs to be investigated\n\n");
     $swap="FAILED";
   } 
   if ($swapping) {
     if ($susemsg) {
       printboth("${swapping}RESOLUTION:  See KB122192 for more info to set swappiness on SuSE\n");
       printboth("             Changing swappiness takes a few days to free up swap used\n\n");
     } else { 
       printboth("${swapping}RESOLUTION:  Determine what is causing the swapping.  \n\n");
     }
     $swap="FAILED";
   }
   if ($moreswap and !$VBA ) {
     printboth("${moreswap}RESOLUTION:  See KB 191126 to correct swap\n\n");
     $swap="FAILED";
   } 
   msg("Swap Space",$swap);
}
########## End checkswap ##########


########## Start bug13216 ##########
# Check that emserver.jar & mcserver.jar patches applied
sub bug13216 {
  print LOG "\n\n\n### ".localtime()." ### Starting bug13216\n";

  if (!grep $_ eq $AVAMARVER, (@v3x,@v40x,"4.1.0-1470") ){
    print LOG "Version $AVAMARVER not affected\n";
    return;
  }

  ########## Start file md5sum hashes ##########
  # Define md5sums for mcserver.jar, emserver.jar for specific checks.  Add to master list at end.
  my %bug13216ems=("0ef25cf1cac0e9f7b239eacfcb2e3cb6" => "3.7.1-80.bug13216",
          "b615bddd0d96b3de6b339858f702ac4c" => "3.7.1-100.bug13216",
          "4e58449b1b9c1595bddc93659a587a15" => "3.7.2-137.bug13216",
          "537f1c3d3e850ab13a6757d4af46161d" => "3.7.3-13.bug13216",
          "fc8dd96015871513e9195c4241f26edb" => "4.0.3-18.bug13216",
          "212fec833239941697a4459f31965797" => "4.0.3-24.bug13216",
          "7220d66c49b75025aaf7e12fc4710625" => "4.1.0-1470.bug13216"
                  );

  my %bug13216mcs=("87c6e74b6114715466ea3c7ba43bee33" => "3.7.1-80.bug13216",
          "28cc3476c39b94421e4de7492d95dee4" => "3.7.1-100.bug13216",
          "f09f8eae9e093754207cbdae8e83efd0" => "3.7.2-137.bug13216",
          "d42aed36fb0b31387b0767c0f160e506" => "3.7.3-13.bug13216",
          "1d50b05a84550558945921abf9afd261" => "4.0.3-18.bug13216",
          "377d1f35c4182aad99cc6a721615fac2" => "4.0.3-24.bug13216",
          "d83557ca6e18c77839db7a4b02dd0036" => "4.1.0-1470.bug13216"
                  );
  ######### End file md5sum hashes ##########

  my $need13216patch=0;
# EMS
  my $emsmd5=`md5sum /usr/local/avamar/lib/emserver.jar | awk '{print \$1}'`;
  chomp($emsmd5);
  print LOG "emserver.jar md5sum is $emsmd5\n";
  if (defined $emserverjar{$emsmd5}) {
    print LOG "emserver.jar version is ". $emserverjar{$emsmd5} ."\n";
  } else {
    print LOG "emserver.jar version is unknown\n";
  }

  if (defined $bug13216ems{$emsmd5}) {
    print LOG "found in bug13216 md5sum list\n";
    msg("Bug 13216 EM Patch","PASSED");
  } else {
    printboth("ERROR: emserver.jar is not patched for EMS bug 13216\n");
    $need13216patch=1;
    msg("Bug 13216 EM Patch","FAILED");
  }
# MCS
  $mcsmd5=`md5sum /usr/local/avamar/lib/mcserver.jar | awk '{print \$1}'`;
  chomp($mcsmd5);
  print LOG "mcserver.jar md5sum is $mcsmd5\n";
  if (defined $mcserverjar{$mcsmd5}) {
    print LOG "mcserver.jar version is ". $mcserverjar{$mcsmd5} ."\n";
  } else {
    print LOG "mcserver.jar version is unknown\n";
  }
  if (defined $bug13216mcs{$mcsmd5}) {
    print LOG "found in bug13216 md5sum list\n";
  } else {
    $need13216patch=1;
    printboth("ERROR: mcserver.jar is not patched for MCS bug 13216\n");
  }
  if ($need13216patch) {
    msg("Bug 13216 MC Patch","FAILED");
    printboth("  This MUST be fixed prior to an upgrade\n");
    printboth("  See bug 13216.  Patch may be available at FTP /ugprep/13216_<version>\n\n");
  } else {
    msg("Bug 13216 MC Patch","PASSED");
  }
}
########## End bug13216 ##########


########## Start bug10449 ##########
# Check for clean_emdb.pl patched
sub bug10449 {
  print LOG "\n\n\n### ".localtime()." ### Starting bug10449\n";
  if ($AVAMARVER ne "3.7.1-100") {
    print LOG "Skipped for version $AVAMARVER\n";
    return;
  }
  my $md5=`md5sum /usr/local/avamar/bin/clean_emdb.pl | awk '{print \$1}'`;
  chomp($md5);
  print LOG "clean_emdb.pl md5sum is $md5\n";
  if ( $md5 eq "5066286c0326303a9df2e4a516aea1a5" ) {
    print LOG "md5sum matches bug 10449 clean_emdb.pl patch\n";
    $result=`crontab -l | grep -c clean_emdb.pl`;
    if ($result==0) {
      printboth("ERROR: server is patched for bug 10449 but admin crontab is missing\n");
      printboth("  The crontab entry should look like this:\n  0 18 * * * /usr/local/avamar/bin/clean_emdb.pl >> /usr/local/avamar/var/cron/clean_emdb.log\n\n");
      msg("Bug 10449 clean_emdb.pl patch","FAILED");
    } else {
      msg("Bug 10449 clean_emdb.pl patch","PASSED");
    }
  } else {
    printboth("ERROR: server does not have patch for EMS bug 10449\n");
    printboth("  Bug 10449 instructions and patch available on the FTP site\n");
    printboth("  Instructions: /software/v3 7 1 100-bug10449-patch-3 README.doc\n");
    printboth("  Patch: /software/clean_emdb.pl.3.7.1-100-bug10449_patch_3\n\n");
    msg("Bug 10449 clean_emdb.pl patch","FAILED");
  }
}
########## End bug10449 ##########


########## Start replavtar ##########
# Check that avtar.bin patched for replication
sub replavtar{

  print LOG "\n\n\n### ".localtime()." ### Starting replavtar\n";

  if (! -e "/usr/local/avamar/etc/repl_cron.cfg"){
    print LOG "Replication not configured\n";
    return;
  }

  getavamarver() if (!$AVTAR_VERSION);

  # Look for DD repl avtar issues
  if (%DD) {
    my %replavtar;
    $replavtar{"6.0.101-66"} = { bug=>36954, dd=>1, res=>"RESOLUTION: See KB92907 for more information"};
    $replavtar{"6.0.102-156"}= { bug=>53090, dd=>1 };
    $replavtar{"6.1.101-87"} = { bug=>57063, dd=>1 };
    $replavtar{"6.1.102-47"} = { bug=>57064, dd=>1 };
    $replavtar{"7.0.101-56"} = { bug=>188345, dd=>1 };
    $replavtar{"7.0.101-61"} = { bug=>188345, dd=>1 };

    if ($replavtar{$AVTAR_VERSION}{dd} ) {
      printboth("ERROR: avtar.bin is not patched for data domain replication bug $replavtar{$AVTAR_VERSION}{bug}\n");
      $res=($replavtar{$AVTAR_VERSION}{res}) ? $res=$replavtar{$AVTAR_VERSION}{msg} : "See hotfix $replavtar{$AVTAR_VERSION}{bug}";
      printboth("RESOLUTION:  $res");
      msg("Replication avtar binary","FAILED");
      return;
    }
  }
  #  Check for avtar's with hotfixes available
  my $hf="";
  $hf.="WARNING:  Hotfix 234581 is available for avtar version $AVTAR_VERSION.\n" if ($AVTAR_VERSION eq "7.1.101-145") ;
  $hf.="WARNING:  Hotfix 228382 is available for avtar version $AVTAR_VERSION.\n" if ($AVTAR_VERSION eq "7.1.100-370") ;
  $hf.="WARNING:  Hotfix 202260 is available for avtar version $AVTAR_VERSION.\n" if ($AVTAR_VERSION eq "7.1.101-61") ;
  # check avreplicator.pl

  if ($hf) {
    printboth("${hf}RESOLUTION:  See bug for more information about the bug and if it is required for this grid\n\n");
    msg("Replication avtar binary","FAILED");
    return;
  }

 
  # Check versions
  if ( ! grep $_ eq $AVAMARVER, (@v3x,@v40x,"4.1.0-1470","6.0.0-592","6.0.0-580") ) {
    print LOG "Version $AVAMARVER not affected\n";
    return;
  }

  # get replication target settings
  my($addr,$id,$passwd);
  open(FILE,"/usr/local/avamar/etc/repl_cron.cfg");
  while(<FILE>) { chomp;
    $addr=$1 if (/^\s*--dstaddr\s*=\s*(.*)/);
    $id=$1 if (/^\s*--dstid\s*=\s*(.*)/);
    $passwd=$1 if (/^\s*--dstpassword\s*=\s*(.*)/);
  }

  # Check gsan version on DST server
  $cmd=qq[ rununtil 60 avmaint nodelist --server=$addr --id=$id --password=$passwd |grep 'gsan='|head -1 ];
  $dstgsan=`$cmd`;
  print LOG "cmd: $cmd\nresult: $dstgsan";
  if (!$dstgsan) {
    printboth("ERROR:  Unable to contact replication destination $addr\n");
    printboth("RESOLUTION:  Fix connectivity or response of destination server\n");
    msg("Replication binaries","FAILED");
    return;
  }
  $dstgsan =~ s/[\/">gsan=]//g;
  print LOG "Destination server version $dstgsan\n";
  $md5=`md5sum /usr/local/avamar/bin/avtar.bin | awk '{print \$1}'`;
  chomp($md5);
  print LOG "avtar.bin md5sum is $md5\n";

  # bug13914
  # Only check for updated avtar version, if repl DST is 4.0.4.59 or >=4.1.1.130
  if ($dstgsan =~ /4.0.4-59|4.1.1-340/) {
    if ( $md5 ne "4b079b2d496e7658d4800b2d5a3aa66b" ) {
       print LOG "OK: md5sum matches bug 13914 avtar.bin patch\n";
       msg("Replication binaries","PASSED");
       return;
    } else {
       printboth("ERROR: avtar.bin does not have patch for replication bug 13914.\n");
       printboth("  Instructions and patch on FTP /software/hotfixes/13914\n\n");
       msg("Replication binaries (13914)","FAILED");
    }
    return;
  }

# New bug 30792 for 6.0.0-592 (or 580) to earlier version
  if (grep $_ eq $dstgsan,(@v3x,@v4x,@v5x)) {
    if ($md5 ne "5009593853c5e454d2e2a9ebe3520672" and
        $md5 ne "776176f53b338d1dd5cbb3a2ff2586b9" ) {
       printboth("ERROR: avtar.bin does not have patch for replication bug 30792.\n");
       printboth("  Instructions and patch on FTP /software/hotfixes/30792\n\n");
       msg("Replication binaries (30792)","FAILED");
      return;
    }
  } 
  msg("Replication binaries","PASSED");
}
########## End replavtar ##########


########## Start mandatoryupgrade ##########
# Check if a mandatory upgrade is required
sub mandatoryupgrade
{
  print LOG "\n\n\n### ".localtime()." ### Starting mandatoryupgrade\n";

  my %mandatoryupgrade = (
    "3.7.1-93" => "must be upgraded to 3.7.1-100 or later",
    "4.0.0-321" => "must be upgraded to 4.0.3-28 or later",
    "4.0.1-30" => "must be upgraded to 4.0.3-28 or later",
    "4.0.2-27" => "must be upgraded to 4.0.3-28 or later",
    "4.0.2-35" => "must be upgraded to 4.0.3-28 or later",
    "6.0.0-580" => "must be upgraded to 6.0.1-66 or later",
    "6.0.0-592" => "should schedule an upgrade to 6.0.1-66 or later",
    "7.1.1-141" => "must be upgraded to 7.1.1-145 or later"
  );
  if (%DD) {
    my %mandatoryupgrade = (
      "6.0.1-65"  => "must be upgraded to 6.0.1-66 or later when Data Domain is attached (KB92907)",
      "6.0.0-580" => "must be upgraded to 6.0.1-66 or later when Data Domain is attached (KB92907)",
      "6.0.0-592" => "must be upgraded to 6.0.1-66 or later when Data Domain is attached (KB92907)"
    ) ;
  }
  if ($AVAMARVER eq "6.0.0-592" and !%DD) {
    printboth("WARNING: It is not required but an upgrade should be scheduled to 6.0.1-66 or later\n\n");
    msg("Mandatory Upgrades","WARNING");
    return;
  }
  if ( $mandatoryupgrade{$AVAMARVER}) {     
    printboth("ERROR: Version $AVAMARVER $mandatoryupgrade{$AVAMARVER}\n\n");
    msg("Mandatory Upgrades","FAILED");
  } else {
    print LOG "No mandatory upgrade found\n";
    msg("Mandatory Upgrades","PASSED");
  }
}
########## End mandatoryupgrade ##########


########## Start checkversion  ##########
# Check that valid Avamar version found
sub checkversion {
  print LOG "\n\n\n### ".localtime()." ### Starting checkversion\n";
  if (grep $_ eq $AVAMARVER, @supportedversions) {
    print LOG "Version $AVAMARVER is supported\n";
    msg("Version Supported","PASSED");
  } else {
    printboth("ERROR: Version $AVAMARVER is not known and should be upgraded to a supported version\n\n");
    msg("Version Supported","FAILED");
  }
}
########## End checkVersion  ##########


########## Start gsanpatches ##########
# Check for GSAN requires a patch
sub gsanpatches{
  print LOG "\n\n\n### ".localtime()." ### Starting gsanpatches\n";
  getavamarver() if (!$DATANODEVERSION);
  my ($e);

#    "5.0.4" =>     { sev=>"INFO", desc=>"Schedule an upgrade to a newer version.  Alternativel apply hotfix 30432" },

# Define gsan pathces.  can override default and buglink severity by adding sev=>"FAILED" 
  my %gsanpatches = (
    "5.0.0" =>     { bug=>30432 },
    "5.0.1" =>     { bug=>30432 },
    "5.0.2" =>     { bug=>30432 },
    "5.0.3" =>     { bug=>30432 },
    "5.0.4" =>     { bug=>30432 },
    "6.0.0" =>     { bug=>36424},
    "6.0.1" =>     { bug=>36424}, 
    "6.0.2" =>     { bug=>36424}, 
    "6.1.0" =>     { bug=>51932},
    "6.1.1" =>     { bug=>51932}, 
    "7.0.0" =>     { bug=>200794}, 
    "7.0.1" =>     { bug=>200794}, 
    "7.0.2" =>     { bug=>200794}, 
    );

# Define bug links. Severity defaults to info. can override for entire bug here by adding sev=>"FAILED"
  my %buglinks = (
    30432  => {link=>"ftp://ftp.avamar.com/software/hotfixes/30432/README" },
    36424  => {link=>"ftp://ftp.avamar.com/software/hotfixes/36424/README_HF-36424.htm" }, 
    51932  => {link=>"ftp://ftp.avamar.com/software/hotfixes/51932/README_hf51932.htm" }, 
    200794 => {link=>"ftp://ftp.avamar.com/software/hotfixes/200794/README.htm"}, 
  );

  (my $current_hotfix=$DATANODEVERSION) =~ s/^.*_HF//;
  my ($gsan_maj,$foo)=split("-",$DATANODEVERSION);
  my $bug=$gsanpatches{$gsan_maj}{bug};
  my $sev=$gsanpatches{$gsan_maj}{sev};
  $bug=$gsanpatches{$DATANODEVERSION}{bug} if (defined($gsanpatches{$DATANODEVERSION}{bug})); 
  $sev=$gsanpatches{$DATANODEVERSION}{sev} if (defined($gsanpatches{$DATANODEVERSION}{sev}));
  $bug="" if ($bug == $current_hotfix) ;

# see if last 5.0.4-906 is installed (HF30432 and not HF28864 which has bad avmaint);
  $bug="" if ($DATANODEVERSION eq "5.0.4-906" and $AVMAINT_VERSION ne "5.0.4-906") ;

  print LOG "DATANODEVERSION=$DATANODEVERSION GSANMAJOR=$gsan_maj CurrHF=$current_hotfix\n";

  if ($bug){
    $sev=$buglinks{$bug}{sev} if (!$sev); 
    $sev="INFO" if (!$sev);
    printboth("$sev: Updated GSAN is available.  For changes see readme file $buglinks{$bug}{link}\n");
    printboth("RESOLUTION:  Update GSAN if needed based on readme file\n\n");
    msg("GSAN Patches",$sev);
  } else {
    print LOG "No gsan patches found\n";
    msg("GSAN Patches","PASSED");
  }
}
########## End gsanpatches ##########

########## Start mcspatches ##########
# Check that emserver.jar & mcserver.jar patches applied
sub mcspatches {
  print LOG "\n\n\n### ".localtime()." ### Starting mcspatches\n";
  getinstalledversion() if (!$AVAMARVER);
  getavamarver() if (!$MCSERVER_VERSION); 

  my $msg;
  my ($foo1,$mchotfix,$foo2) = split("_",$MCSERVER_VERSION);
  $mchotfix =~ s/HF//;
  print LOG "AVAMARVER=$AVAMARVER MCS=$MCSERVER_VERSION  HF=$mchotfix\n";

  # Bad MCS version that require an upgrade
  my %badmd5sum=("213b76ca717eaa2e2964488f3e197ab7",
                 "152bcfa79be98942862d977e669178b5",
                 "85f4e8fa4e629a6849d0542af2f2db45" );
  if (defined($badmd5sum{$MCSERVER_MD5SUM})) {
    printboth("ERROR:  MCS Version $MCSERVER_VERSION has serious bugs\n");
    printboth("RESOLUTION:  This version cannot be patched an upgrade is required.  See bug 33101 for more info\n\n");
    msg("MCS Patches","FAILED");
    return;
  } 

  # bug (bug#), patchmd5sum (mcserver.jar sum of patch), KB (used instead of bug if avail)
  # error (print instead of default err msg), resolution (print instead of default resolution)
  $mcspatch->{"5.0.0-410"} = { error=>"MCS Version $MCSERVER_VERSION has serious bugs", 
                               resolution=>"This version cannot be patched an upgrade is required.  See bug 33101 for more info" };
  $mcspatch{"5.0.1-32"} =  { bug=>33101, md5sum=>"679bfe31df12c20d5405e4005ee170f0", esg=>"KB92896" };
  $mcspatch{"5.0.2-41"} =  { bug=>33101, md5sum=>"b4dbd0ebc93b6603729623c3a5dba652", esg=>"KB92896" };
  $mcspatch{"5.0.3-29"} =  { bug=>33101, md5sum=>"7bdecdce6c7cefb51c527b56d1e3e19f", esg=>"KB92896" };
  $mcspatch{"5.0.4-30"} =  { bug=>36971, md5sum=>"0c22b5e86340cf1ac3bbc137fd19693c", esg=>"KB92909" };
  $mcspatch{"6.0.0-592"} = { bug=>36897, md5sum=>"c7d59a7c98e1b02ec082d488e78286d6", esg=>"KB92909" };
  $mcspatch{"6.0.1-66"} =  { bug=>37753, md5sum=>"51ae5e4426435f6648ae50877e3ca8dc", esg=>"KB92909" };
  $mcspatch{"6.0.2-153"}=  { bug=>46907, md5sum=>"b261587b8ea6908372a757969f98bde5"};
  $mcspatch{"6.0.2-156"}=  { bug=>50844, md5sum=>"b90234dadf0b55ff2eb342f7448e1b29"};
  $mcspatch{"6.1.0-276"} = { bug=>49734, md5sum=>"06f180076d5c27c7c4197f481aff7b5b" };
  $mcspatch{"6.1.0-280"} = { bug=>49734, md5sum=>"06f180076d5c27c7c4197f481aff7b5b" };
  $mcspatch{"6.1.0-333"} = { bug=>49734, md5sum=>"06f180076d5c27c7c4197f481aff7b5b" };
  $mcspatch{"6.1.0-402"} = { bug=>49734, md5sum=>"06f180076d5c27c7c4197f481aff7b5b" };
  $mcspatch{"6.1.1-81"} =  { bug=>51416, md5sum=>"d2373e5259362aba5f1287ed06c236f7" };
  $mcspatch{"6.1.1-87"} =  { bug=>200044, md5sum=>"cfbd8589b40b005bf2e504f8c4f99d0d" };
  $mcspatch{"6.1.2-47"} =  { bug=>228097, md5sum=>"2930d658878e5c31723b2266514ac0f5" };
  $mcspatch{"7.0.0-427"} = { bug=>196804, md5sum=>"1ccf5546aede3b0473b0c397e0fe327f" };
  $mcspatch{"7.0.1-61"} =  { bug=>205494,md5sum=>"dce592c7a811c86ee6ee2ab19949cf1a" };
  $mcspatch{"7.0.2-43"} =  { bug=>197922,md5sum=>"818e3baa91e9ebef64e2fdc8b29e8d0f" };
  $mcspatch{"7.0.2-47"} =  { bug=>235648,md5sum=>"08c4c49ec4ea6484be162b477750734e" };
  $mcspatch{"7.0.3-32"} =  { bug=>228585,md5sum=>"" };
  $mcspatch{"7.1.0-370"} =  { bug=>234040,md5sum=>"6c1894413910f5d8bdc7add35fded2ba" };
  $mcspatch{"7.1.1-141"} =  { bug=>225423,md5sum=>"99518dd44fa34ea001760f1122ea56aa" };
  $mcspatch{"7.1.1-145"} =  { bug=>235000,md5sum=>"352073fd737715b98a743c1f25817538" };

  if ($AVAMARVER eq "7.0.3-32") {
    chomp( my $md5=`md5sum /usr/local/avamar/lib/mccli.jar | awk '{print \$1}'`);
    if ($md5 eq "9cce78418849e380a823eff23c985f4b") {
      msg("MCS Patches","PASSED");
      return;
    } else {
      printboth("ERROR: Version $AVAMARVER requires an MCS patch for bug 228585\n");
      printboth("RESOLUTION: See hot fix $bug for more information\n\n");
      msg("MCS Patches","FAILED");
      return;
    }
  }


  if ($mcspatch{$AVAMARVER}) {
    if ($MCSERVER_MD5SUM ne $mcspatch{$AVAMARVER}{"md5sum"} or (!$mcspatch{$AVAMARVER}{"md5sum"} and $mchotfix ne $mcspatch{$AVAMARVER}{"bug"}) ) {   
      my $bug=$mcspatch{$AVAMARVER}{"bug"};
      my $err="Version $AVAMARVER requires an MCS patch for bug $bug";
      if ($VERSNUM>=600) {
        my $err="Schedule an upgrade to a newer version.  Alternatively apply hot fix $bug";
      }
      $err=$t if ($t=$mcspatch{$AVAMARVER}{"error"});
      printboth("ERROR:  $err\n"); 

      # compile all event code 1 for 50070
      if ($mcspatch{$AVAMARVER}{"bug"} == 51416) {
        bug47560();
      }

      if ($bug < $mchotfix and $mchotfix ) { 
        printboth("NOTE:  Current hotfix $mchotfix may be newer than $bug.  Do not overwrite a newer hot fix.\n");
        $msg="Review both hotfixes to determine proper hotfix.";
      } else {
        $msg="See hot fix $bug for more information";
        $msg="See $t article for more information" if ($t=$mcspatch{$AVAMARVER}{esg});
        $msg="$t" if ($t=$mcspatch{$AVAMARVER}{"resolution"});
      }
      printboth("RESOLUTION:  $msg\n\n"); 
      msg("MCS Patches","FAILED");
      return;
    } 
  }
  msg("MCS Patches","PASSED");
}
########## End mcspatches ##########


########## Start bug13252 ##########
# Check O/S reserved space
sub bug13252 {
  print LOG "\n\n\n### ".localtime()." ### Starting bug13252\n";

  if ( $OS !~ /redhat/ ) {
    print LOG "Not checking $OS, only an issue on redhat";
    return;
  }
  $cmd=q[ for i in $(grep /data /etc/fstab | awk '{print $1}')
          do
            device=$(/sbin/findfs $i)
            echo DEVICE: $device
           /sbin/dumpe2fs -h $device | grep Reserved
          done
        ];

  mapall("--all --user=root",$cmd);

  open(CMD_PIPE,$TMPFILE);
  $foundbad=0;
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    next if ($NODE_INFO{$node}{os} !~ /redhat/);
    ($foo,$device)=split(' ', $_ , 2) if ( $_ =~ /DEVICE:/);
    if ( $_ =~ /Reserved block count/  ) {
      ($foo,$foo,$foo,$reservedblocks,$foo)=split(' ',$_,5);
      print LOG "--> $node device $device reserved blocks is set to $reservedblocks\n";
      if ($reservedblocks > 20000) {
        $foundbad++;
        printboth("ERROR: Node $node device $device reserved blocks is too high at $reservedblocks.\n");
      }
    }
  }
  if ($foundbad){
    if ($PREUPGRADE){ 
      printboth("RESOLUTION:  If you are upgrading to 6.x this message can be ignored otherwise follow the the instructions below.\n");
    } 
    printboth("RESOLUTION:  As the root user use the command: /sbin/tune2fs -r 20000 <device>\n\n");
    msg("Bug 13252 O/S reserved space","FAILED");
  } else {
    msg("Bug 13252 O/S reserved space","PASSED");
  }
}
########## End bug13252 ##########


########## Start getnodetype ##########
# Determing deep or shallow node
sub getnodetype {
my %hwconf=("10-32-6" => "100-580-617",
           "5-36-3" =>  "100-580-618",
           "3-24-2" =>  "100-580-619",
           "1-12-1" =>  "100-580-620",
           "1-6-4" =>   "100-580-601",
           "2-18-3" =>  "100-580-602",
           "4-36-1" =>  "100-580-603",
           "2-16-3" =>  "100-580-584",
           "1-4-4" =>   "100-580-585",
           "9-32-5" =>  "100-580-622"
          );
my %emcconf=("10-32-6" => "100-580-642",
            "10-32-1" => "100-580-682",
            "5-32-3" => "100-580-643",
            "2-16-3" => "100-580-644",
            "9-32-5" => "100-580-646"
           );
   %PARTLIST=("100-580-601" => { desc=>"1.0TB Gen3", maxstripe=>15000 },
           "100-580-602" => { desc=>"2.0TB Gen3", maxstripe=>46000 },
           "100-580-603" => { desc=>"3.3TB Gen3", maxstripe=>46000 },
           "100-580-585" => { desc=>"1.0TB Gen2", maxstripe=>15000 },
           "100-580-584" => { desc=>"2.0TB Gen2", maxstripe=>46000 },
           "100-580-575" => { desc=>"1.0TB Gen1", maxstripe=>0 },
           "100-580-620" => { desc=>"1.3TB Gen4", maxstripe=>31000 },
           "100-580-619" => { desc=>"2.6TB Gen4", maxstripe=>62000 },
           "100-580-618" => { desc=>"3.9TB Gen4", maxstripe=>92000 },
           "100-580-617" => { desc=>"7.8TB Gen4", maxstripe=>92000 },
           "100-580-640" => { desc=>"gen4s-Util/Accel", maxstripe=>0 },
           "100-580-641" => { desc=>"gen4s-L-Accel", maxstripe=>0 },
           "100-580-642" => { desc=>"gen4s-M2400", maxstripe=>92000 },
           "100-580-643" => { desc=>"gen4s-M1200", maxstripe=>92000 },
           "100-580-644" => { desc=>"gen4s-M600", maxstripe=>46000 },
           "100-580-646" => { desc=>"gen4s-MAC AER", maxstripe=>0 },
           "100-580-682" => { desc=>"gen4s-S2400", maxstripe=>92000 },
           "100-580-622" => { desc=>"Gen4 AER Media Access Node", maxstripe=>0 },
           "ave-4" => { desc=>"AVE 4TB", maxstripe=>96000, minmem=>36 },
           "ave-2" => { desc=>"AVE 2TB", maxstripe=>48000, minmem=>16 },
           "ave-1" => { desc=>"AVE 1TB", maxstripe=>24000, minmem=>8 },
           "ave-.5" =>{ desc=>"AVE .5TB", maxstripe=>12000, minmem=>6 }
);

  print LOG "\n\n\n### ".localtime()." ### Starting getnodetype\n";
  gethardware() if (!$MANUFACTURER);
  getconfiginfo() if (!$GOTCONFIGINFO);
  $NODETYPE = "";
  my $partno;
  my ($partcnt,$nodesize,$mem,$e,$diske,$nodeerr,$node,$sawdto);
  $origsize="S";
  $cmd=q[ test -d /data01/pool && echo "POOL" || echo "NOPOOL"; /bin/df;free -om; ];
  mapall("",$cmd);
  my ($cape,$poole)="";
  $news="fr";
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/){
       $node=$1 ;
       ($nodetot,$parttot,$memtot,$haspool)=0;
       $partno="";
    }
    next if (!$node);
    $haspool=1 if (/^POOL$/);
    $sawdto=1 if (/\/DTO$/);
    if (/(.*?)\s+(\d*)\s+.*(\/data[0-9]*)/) {
      $partcnt++;
      $nodesize+=$2;
    }
    if ($PREUPGRADE) {
      if (/(.*?)\s+(\d+)\s+(\d+)\s+(\d*)\s+(\d*).*(\/space)/) {
        if ($4/1024/1024 < 20 and  $NODE_INFO{$node}{manufacturer} eq "vmware") { 
          $diske.="ERROR:  $node /space partition has less then 20GB of space available\n";
        }
      }
      if (/(.*?)\s+(\d+)\s+(\d+)\s+(\d*)\s+(\d*).*(\/data01)/) {
        if ($4/1024/1024 < 20 ) { 
          $diske.="ERROR:  $node /data01 partition has less then 20GB of space available\n";
        }
      }
      if (/(.*?)\s+(\d+)\s+(\d+)\s+(\d*)\s+(\d*).*(\/$)/) {
        if ($4/1024/1024 < 1 ) { 
          $diske.="ERROR:  $node / (root) partition has less then 1GB of space available\n";
        }
      }
    }

    if (/^Mem:\s*(\d*) /){
      # +300 to fudge close up and over
      $mem=$1+300;
      $nodetot=int($nodesize/1024/1024/1024);
      if (int($nodetot) != int($lastsize) and $lastsize) {
        $cape="ERROR: Node size mismatch $lastnode is $lastsize, $node is $nodetot\n";
      }
      $lastsize=$nodetot;
      $memtot=int($mem/1000);
      $NODE_INFO{$node}{memory}=$memtot;
      my $nodekey="$nodetot-$memtot-$partcnt";
      print LOG "key = $nodekey\n";
      $ThisNodeType="Unknown $nodetot TB" ;
      if ( $NODE_INFO{$node}{manufacturer} eq "dell" ) {
        $partno=$hwconf{$nodekey};
        $ThisNodeType=$PARTLIST{$partno}{desc}; 
        print LOG "Dell $partno\n";
      } elsif ( $NODE_INFO{$node}{manufacturer} eq "emc" ) {
        $partno=$emcconf{$nodekey};
        $ThisNodeType=$PARTLIST{$partno}{desc}; 
        print LOG "EMC $partno\n";
      }
      if ($ThisNodeType eq "1.0TB Gen2") {
        # if gen1/2 look for perc controller to decide
        getomreport() if (!@OMREPORT_STORAGE);
        foreach (@OMREPORT_STORAGE) {
          $omrptnode=$1 if (/(\(0\..*\)) ssh/);
          next if ($omrptnode ne $node);
          if (/PERC (\d)/) {
            if ($1 ==5) {
              $partno="100-580-575";
              $gen=1;
              $ThisNodeType="1.0TB Gen1";
            }
          }
        }
      }
      ( $nodenum = $node ) =~ s/[)(]//g;
      my $key="/nodestatuslist/nodestatus/$nodenum/hardware-id";
      print LOG "--> hardware-id $NODELIST{$key}\n--> Key: $key\n"; 
      my($serial,$part,$rev,$ip,$ipaddr)=split("_",$NODELIST{$key}); 
      print LOG "--> Part# $part\n";

      if ( $PARTLIST{$part}{desc}) {
        if ($ThisNodeType =~ /Unknown/) {
          $ThisNodeType = $PARTLIST{$part}{desc};
          msg("Node Type","WARNING");
          printboth("WARNING: Node $node was identified by part# $part and not hardware. disk ($nodetot), mem ($memtot), partitions ($partcnt)\n");
          printboth("RESOLUTION: Verify health of the hardware\n\n");
        } else {
          if ($PARTLIST{$part}{desc}  ne $ThisNodeType) {
            $ThisNodeType="unknown" if (!$ThisNodeType);
            printboth("ERROR: Part $part is a $PARTLIST{$part}{desc}  but memory/disks match $ThisNodeType\n");
            $nodeerr="x";
          } 
        }
      }

      if ( $NODE_INFO{$node}{manufacturer} eq "vmware") {
        print LOG "--> Manufacture=VMWare. Changing node type to AVE. nodesize=$nodetot\n";
        if ($nodetot >=4 )  { 
          $partno="ave-4";
        } elsif ($nodetot>=2) {
          $partno="ave-2";
        } elsif ($nodetot>=1) {
          $partno="ave-1";
        } else {
          $partno="ave-.5"; 
        }
        $ThisNodeType=$PARTLIST{$partno}{desc};
        if ( ($UPGRADE_VERSION >= '7' or $VERSNUM>=700) and $memtot < $PARTLIST{$partno}{minmem} ) {
          printboth("ERROR: Node $node installed memory of ${memtot}GB is less than the required $PARTLIST{$partno}{minmem}GB\n");
          printboth("RESOLUTION: Memory requirements changed from v6 to v7. See AVE Installation guide for minimum requirements. \n\n");
          msg("AVE Minimum Requirements","FAILED");
        }
      }
      if ($NODETYPE !~ /$ThisNodeType/) {
        print LOG "Adding: $ThistNodeType to $NODETYPE \n" if ($DEBUG);
        $NODETYPE .= ", " if ($NODETYPE);
        $NODETYPE .= $ThisNodeType;
      }
      $NODE_INFO{$node}{gendesc}=$ThisNodeType;
      print LOG "node $node partno=$partno\n";
      $NODE_INFO{$node}{partno}=$partno;
      print LOG "--> H/W=$ThisNodeType P/N=$PARTLIST{$part}{desc}  size=$nodetot, partitions=$partcnt, memory=$mem\n";
      if ( $ThisNodeType =~/Unknown/) {
        printboth("WARNING:  Node $node Unknown node type based on disk size ($nodetot TB), memory ($memtot GB) and disk partitions ($partcnt)\n");
        $nodeerr="x";
      }
      if ($ThisNodeType eq "3.3TB Gen3" and !$haspool and $PREUPGRADE) { 
        printboth("ERROR: Node $node is missing the file pool\n");
        $poole="yes";
      }
      ($partcnt,$nodesize,$mem)=0;
      $lastnode=$node;
    }
  }
  $origsize.="P";
  if ($poole) {
    if ($PREUPGRADE) {
      printboth("RESOLUTION:  Upgrade will require a work around.  See RCM coach for additional information\n\n");
    } else {
      printboth("RESOLUTION:  Rebuild node onto new hardware or for multiple nodes contact support/engineering\n\n");
    }
    msg("Gen3 3.3TB File Pool","FAILED");
  } 
  $news.="ie";
  if ($cape) {
    printboth($cape);
    printboth("RESOLUTION:  Make sure all nodes have the same capacity\n\n");
    msg("Node Size Consistent","FAILED");
  }

  if ( $nodeerr ) {
    printboth("RESOLUTION: Thoroughly check hardware status, size of partitions, number of partitions and amount of memory\n\n");
    msg("Node Type","FAILED");
  }

  $origsize.="W";
  my $size="1x$NODE_COUNT ";
  $size="Single Node " if ($NODE_COUNT == 1 );
  msg("Node Type",$size.$NODETYPE);

  if ($PREUPGRADE) {
    if ($diske) {
      printboth($diske);
      printboth("RESOLUTION:  Reduce the usage of the partition\n\n");
      msg("Available Disk Space","FAILED");
    } else {
      msg("Available Disk Space","PASSED");
    }
    if ($NODETYPE =~ /Gen2/i and $UPGRADE_VERSION >= '7' or $NODETYPE =~ /Gen1/i) {
      printboth("ERROR: This Server cannot be upgraded because Hardware is End-Of-Service-Life.\n");
      printboth("RESOLUTION: Please contact the Sales Account Team or the DSM to meet with the customer to discuss their best course of action.\n\n");
      msg("Hardware EOSL","FAILED");
    } elsif ($NODETYPE =~ /Gen3/i and $UPGRADE_VERSION >= '7.2.0')  {
      printboth("ERROR: Gen 3 or lower Hardware platforms are not supported in Avamar 7.2\n");
      printboth("RESOLUTION: Please contact the Sales Account Team or the DSM to meet with the customer to discuss their best course of action.\n\n");
      msg("Hardware EOSL","FAILED");
    } else {
      msg("Hardware EOSL","PASSED");
    }
  }
  $$origsize=$news."nd";
  if ($NODETYPE =~ /AER/ ) {
    my $msg="\n# # #  DO NOT INSTALL SECURITY UPDATES ON AER NODE  # # #\n\n";
    printboth($msg);
    print "${WARNING} $msg${NORMAL}";
  }
  if ($MANUFACTURER !~ /vmware/) {
    my $generr="",$nopart="";
    for $node(sort @NODES) {
      if ($PREUPGRADE and $NODELIST{"/nodestatuslist/nodestatus/$node/hardware-id"} !~ /100[-_]5/) {
        $nopart.="ERROR: Node $node does not have an EMC part number in the nodelist output\n";
      }
      if ($NODELIST{"/nodestatuslist/nodestatus/$node/sysconfig/hwcheck/generation"} eq "0" ) {
        $generr.=("ERROR: Node $node The nodelist hardware generation is being identified as '0'\n");
      }
    } 
    if ($generr){
      printboth($generr);
      printboth("RESOLUTION: Find out why hardware is not correctly being identified.  See KB184238\n\n");
      msg("Hardware Generation","FAILED");
    }
    if ($nopart) {
      printboth($nopart);
      printboth("RESOLUTION:  Determine if hardware is EMC or Customer supplied.  See KB 182356 for more info\n");
      printboth("             Customer supplied hardware is no longer supported for upgrades to 6.1 or higher\n\n");
      msg("Hardware Supplier","FAILED");
    }
  }
}
########## End getnodetype ##########


########## Start gccountcheck ##########
# Check for gccount flags in morning cron for deep nodes
sub gccountcheck {
  print LOG "\n\n\n### ".localtime()." ### Starting gccountcheck\n";
  if (!grep $_ eq $AVAMARVER, @v4x) {
    print LOG "Skipped for version $AVAMARVER\n";
    return;
  }
  $foundbad=0;
  if ($NODETYPE !~ /2.0 TB/ ) { return; }
  $gccron=`grep gc_cron /usr/local/avamar/bin/morning_cron_run | grep -v "^#" |\
      grep gccount | head -1 | sed -e 's/.*gccount=//' -e 's/ .*//'`;
  chomp($gccron);
  print LOG "Found gc_cron gccount=$gccron\n";
  if ($gccron != 32 ) {
    printboth("ERROR: gc_cron gccount is set to $gccron.  Recommended value is 32\n");
    $foundbad++;
            msg("gc_cron gccount","FAILED");
  } else {
            msg("gc_cron gccount","PASSED");
          }


  $hfscron=`grep hfscronrunning /usr/local/avamar/bin/morning_cron_run | grep -v "^#" |\
      grep gccount | head -1 | sed -e 's/.*gccount=//' -e 's/ .*//'`;
  chomp($hfscron);
  print LOG "Found hfscronrunning gccount=$hfscron\n";
  if ($hfscron != 64) {
    printboth("\nERROR: hfscronrunning gccount is set to $hfscron.  Recommended value is 64\n");
    $foundbad++;
            msg("hfs_cron gccount","FAILED");
  } else {
            msg("hfs_cron gccount","PASSED");
          }
  if ($foundbad){
    printboth("  Edit morning_cron_run to add or edit --gccount=<value> flag for hfscronrunning and gc_cron\n\n");
  }
}
########## End gccount ##########


########## Start fullhfscheck ##########
# Check for metadata hfschecks configured
sub fullhfscheck {
  print LOG "\n\n\n### ".localtime()." ### Starting fullhfscheck\n";
  if (!grep $_ eq $AVAMARVER, @v4x) {
    print LOG "Skipped for version $AVAMARVER\n";
    return;
  }
  $metadata=`grep -c metadata /usr/local/avamar/etc/hfsscheduleconf.xml`;
  chomp($metadata);
  print LOG "Found $metadata metadata HFS checks in hfsscheduleconf.xml\n";
  if ($metadata ne 0 ) {
    $full=`grep hfscronrunning /usr/local/avamar/bin/morning_cron_run | grep -c full`;
    chomp($full);
    if ($full eq 0 ) {
      printboth("ERROR: Full hfschecks are recommended every day. Partials are currently setup\n");
      printboth("  Edit ~avamar/etc/hfsscheduleconf.xml and change 'metadata' to 'full'\n");
              msg("Partial HFS Checks disabled","FAILED");
    } else { msg("Partial HFS Checks disabled","FAILED"); }
  } else { msg("Partial HFS Checks disabled","PASSED"); }
}
########## End fullhfscheck ##########


########## Start nousehistory ##########
# Check for --nousehistory flag on gc_cron command line
sub nousehistory {
  print LOG "\n\n\n### ".localtime()." ### Starting nousehistory\n";
  if (!grep $_ eq $AVAMARVER, @v41x) {
    print LOG "Skipped for version $AVAMARVER\n";
    return;
  }
  $result=`grep gc_cron /usr/local/avamar/bin/morning_cron_run | grep -v "^#" |\
      head -1 | grep -c 'nousehistory' `;
  chomp($result);
  print LOG "Found $result nousehistory flag in morning_cron_run\n";
  if ($result == 0 ) {
    printboth("ERROR: Recommended to use --nousehistory flag on gc_cron\n");
    printboth("  Edit morning_cron_run and add --nousehistory flag to gc_cron\n");
            msg("GC --nousehistory disabled","FAILED");
  } else {
            msg("GC --nousehistory disabled","PASSED");
          }
}
########## End nousehistory ##########


########## Start lastflush ##########
# Check for number of mcs/ems flushes in past 24 hours
sub lastflush {
  print LOG "\n\n\n### ".localtime()." ### Starting lastflush\n";

  my $currtime=time();
  print LOG "Current time $currtime\n";

  my $results=`avmgr getb --path=/MC_BACKUPS --mr=1 --format=xml`;
  print LOG $results;
  $lastmcs=$1 if ($results =~ /created="(\d*)" /);
  print LOG "Last MCS flush $lastmcs\n";
  if ( ($currtime-$lastmcs) > 86400 ) {
    printboth("ERROR: No MCS flush in past 24 hours. Last one is ".localtime($lastmcs)."\n");
    printboth("RESOLUTION: Try 'mcserver.sh --flush' to see why MCS flushes are failing\n\n");
            msg("MC flush in past 24 hours","FAILED");
  } else {
            msg("MC flush in past 24 hours","PASSED");
          }

  if (!$VBA){ 
    $results=`avmgr getb --path=/EM_BACKUPS --mr=1 --format=xml `;
    print LOG $results;
    $lastems=$1 if ($results =~ /created="(\d*)" /);
    print LOG "Last EMS flush $lastems\n";
    if ( ($currtime-$lastems) > 86400) {
      printboth("ERROR: No EMS flush in past 24 hours. Last one is ".localtime($lastems)."\n");
      printboth("RESOLUTION: Try 'emserver.sh --flush' to see why EMS flushes are failing\n\n");
              msg("EM flush in past 24 hours","FAILED");
    } else {
              msg("EM flush in past 24 hours","PASSED");
    }
  }
}
########## End lastflush ##########

########## Start dellomlogs ##########
# Check that logrotate is configured for Dell logs
sub dellomlogs {
  print LOG "\n\n\n### ".localtime()." ### Starting dellomlogs\n";

  if ($MANUFACTURER !~ /dell/) {
    print LOG "Skipping for manufacturer $MANUFACTURER\n";
    return;
  }

  my $nodes=getnodes_hw("dell");
  if (!$nodes) {
    print LOG "no dell nodes found\n";
    return;
  }
  my $e="";
  $cmd=q[ test -e /etc/logrotate.d/dellomlogs||echo "error" ];
  mapall("--nodes=$nodes",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    if (/error/) {
      printboth("ERROR: Node $node Dell log files are not setup to rotate.\n");
      $e="yes";
    }
  }
  if ($e) {
    printboth("RESOLUTION: See KB120171 for more info to configure log rotation.\n\n");
    msg("Dell log rotate","FAILED");
  } else {
    print LOG "/etc/logrotate.d/dellomlogs found\n";
    msg("Dell log rotate","PASSED");
  }
}
########## End dellomlogs ##########


########## Start get_repl_info ########
sub get_repl_info {
if ($IN_DAYS) {
  $repldate="$IN_DAYS days ago"
} else {
  $repldate="30 days ago";
  $repldate="9999 days ago";
}
$replfile="/usr/local/avamar/var/cron/replicate.log";

print LOG "\n\n\n### ".localtime()." ### Starting get_repl_info\n" if (!$replrpt);
print("HEALTHCHECK:  Creating hc_replrpt.txt\n") if (!$replrpt);
if (!$replrpt) {
  open(OUTPUT,">hc_replrpt.txt")
} else {
  *OUTPUT=*STDOUT;
}

if (! -e $replfile) {
  print OUTPUT "$replfile does not exist\n";
  print LOG "$replfile does not exist\n" if (!$replrpt);
  return;
 }

my $DATE=`date --date="$repldate" '+%s'`;
my $cnt=0;
chomp($DATE);
print LOG "repldate=$repldate\nDATE=$DATE\n" if (!$replrpt);
printf OUTPUT "%16s %-10s %13s %15s %14s %10s\n",
   "DATE","STATUS","REPLICATED","THROUGHPUT","TIME","BACKUPS" ;
printf OUTPUT "%16s %10s %13s %15s %14s %10s\n",
   "================","==========","=============","==============","==============","==========";

open(FILE,$replfile);
while(<FILE>) {
  if (!$starteval) {
    if (/(\d\d\d\d)\/(\d\d)\/(\d\d)-(\d\d):(\d\d):/) {
      my ($yy,$mm,$dd,$hr,$mn)=($1,$2,$3);
      $gmt = timegm(0,$min,$hr,$dd,$mm-1,$yy);
print "gmt $gmt date $DATE\n";
      if ($gmt >= $DATE) { 
        $starteval=1;
      } else {
        next;
      }
    }
  }
  next if (!$starteval);
  if ( $_ =~ /=== Running / ) {
     $currday=substr($_,0,16);
     $status="";
     next;
  }
  if ( $_ =~ /<5675>/ and $_ !~ /client "(MC|EM)_BACKUPS"/) {
    s/^.*Replicated //;
    s/ .*$//;
    $totrepl+=$_;
    $grpl+=$_;
  }
  if ( $_ =~ /<6090>/ ) {
    s/^.*Restored //;
    my ($size,$type,$foo,$mins)=split(" ");
    $size=$size*1024*1024;
    if ($type eq "GB") {$size=$size*1024}
    $totsize+=$size;
    $tottime+=$mins;
    $gsz+=$size;
    $gtm+=$mins
  }
  if ( $_ =~ /<7211>/ ) {
    s/^.*Client "//;
    s/".*$//;
    $clientname=$_;
    chomp($clientname);
  }
  if ( $_ =~ /infomessage/ and !$status ) {
    if ( $_ =~ /failed/ ) { $status="FAILED"};
    if ( $_ =~ /completed/ ) { $status="COMPLETED"};
    if ( $_ =~ /timed/ ) { $status="TIMED OUT"};
  }
  if ( $_ =~ /Warning <|Error <|FATAL|ERROR:/ and $_ !~ /<6618>|<5237>/) {
    if ( $_ =~ /MSG_ERR_CANCEL/ ) { $status="TARGET CANCELED";next }
    chomp;
    print OUTPUT $_ ."(last client=$clientname)\n";
  }
  if ( $_ =~ /=== Finished / ) {
     if ($tottime gt 0) {
       $speed=(($totsize*8)/($tottime*60))/1024;
     } else {
       $speed="N/A";
     }
     printf OUTPUT "%16s %-10s %10d MB %10d Kbps %10d min %10d\n",$currday,
    $status,$totsize/1024/1024,$speed,$tottime,$totrepl;
     $totsize=0;
     $tottime=0;
     $totrepl=0;
     $cnt++;
  }
}
  if ($gtm gt 0) {
    $speed=(($gsz*8)/($gtm*60))/1024;
  } else {
    $speed="N/A";
  }
  printf OUTPUT "%16s %10s %13s %15s %14s %10s\n",
   "================","==========","=============","==============","==============","==========";
  if ($cnt gt 0) {
    printf OUTPUT "%16s %10s %10d MB %10d Kbps %10d min %10d\n","AVERAGES","",
      $gsz/1024/1024/$cnt,$speed,$gtm/$cnt,$grpl/$cnt;
  } else {
    print OUTPUT "No replication records found\n";
  }
if (!$replrpt) {
print("HEALTHCHECK:  Creating hc_repl_cron.cfg\n");
#print("HEALTHCHECK:  Creating hc_replicate.log\n");
$a=`cp /usr/local/avamar/etc/repl_cron.cfg ./hc_repl_cron.cfg 2>/dev/null`;
#$a=`cp /usr/local/avamar/var/cron/replicate.log ./hc_replicate.log 2>/dev/null`;
}
}
########## End get_repl_info ########


########## Start get_backup_info ########
sub get_backup_info {

openmcdb() if (!$dbh);
print LOG "\n\n\n### ".localtime()." ### Starting get_backup_info\n";

# COMMENT OUT TO GET LOGS
if ( 2+2==5) {
  print("HEALTHCHECK:  Creating hc_backup_logs.txt\n");
    open(OUTPUT,">hc_backup_logs.txt");
  $xml = new XML::Parser( Style => 'Tree' );
  print LOG "parsing mccli activity show --verbose --completed --xml\n";
  my $tree=$xml->parsefile("mccli activity show --verbose --completed --xml |");
  bu_XMLTree( $tree);
  
  for $key ( keys %$latest_backup) {
      my ($sec, $min, $hour, $day,$month,$year,$foo) = localtime($latest_backup->{$key});
      print OUTPUT "\n\n=============================================================================\n";
      printf OUTPUT "CLIENT: %s %4d/%02d/%02d %02d:%02d %s\n",$key,$year+1900,$month+1,$day,$hour,$min,"$latest_status->{$key}";
      $cmd="avtar --showlog --path=$key 2>&1";
      $log=`$cmd`;
      print OUTPUT $log;
  }
}

# get high change rate,long running, high new data clients

print("HEALTHCHECK:  Creating hc_backup_clients.txt\n");
  open(OUTPUT2,">hc_backup_clients.txt");
  my $DAYS=30*86400;
  my $sql = qq[
     select domain,client_name,
      avg(bytes_modified_sent),
      max(bytes_modified_sent),
      avg(bytes_scanned),
      avg(num_of_files),
      max(client_os),max(client_ver),
      avg(completed_ts - started_ts),
      max(completed_ts - started_ts)
     from v_activities
     where $DAYS >= (date_part('epoch',current_date) - date_part('epoch',started_ts))
      and (type like '%Snap%' or type like '%Dest%')
     group by domain,client_name
     order by domain,client_name
  ];

  my $sth = $dbh->prepare($sql);
  $sth->execute;

  while ( @row = $sth->fetchrow_array() ) {
    next if ($row[1] =~ /(MC|EM)_BACKUPS/);
    next if ($row[0] =~ /REPLICATE/);
    ($domain,$client,$sent,$maxsent,$scan,$files,$os,$ver,$elap,$maxelap)=@row;
    $client=$domain."/".$client;
    $s_maxelap{$maxelap}=$client;
    $s_elap{$elap}=$client;
    $s_maxsent{$maxsent}=$client;
    $s_sent{$sent}=$client;
    $s_chg{$sent/$scan}=$client if ($scan gt 0);
    $clients->{$client} = [ @row ] ;
  }

    printf OUTPUT2 "%-50s %7s %7s %7s %5s  %7s %7s %7s %13s %s\n",
    "CLIENT","AVG",   "MAX",   "AVG",    "CHG", "ELAP","MAXELAP","NUM OF","CLIENT","OPERATING";
    printf OUTPUT2 "%-50s %7s %7s %7s %5s  %7s %7s %7s %13s %s\n",
    "CLIENT","NEW GB","NEW GB","SCAN GB","RATE","TIME","TIME",   "FILES", "VERSION","SYSTEM";
    printf OUTPUT2 "%50s %7s %7s %7s %5s %7s %7s %7s %13s %s\n",
    "==================================================","=======","=======","=======","======","=======","=======","========","===========","=====";
print_client(%s_maxelap);
print_client(%s_elap);
print_client(%s_sent);
print_client(%s_maxsent);
print_client(%s_chg);

close OUTPUT;
}
sub print_client {
  my %hash = @_;
  $c=0;

foreach $key (sort {$b cmp $a} keys %hash) {
  if (!$printed_client{$hash{$key}}) {
    $printed_client{$hash{$key}} = 1;
    $row = $clients{$hash{$key}};
    ($domain,$client,$sent,$maxsent,$scan,$files,$os,$ver,$elap,$maxelap) = @$row;
    $chgrate=0;
    $chgrate=($sent/$scan)*100 if ($scan gt 0) ;
    printf OUTPUT2 "%-50s %7.1f %7.1f %7.1f %5.2f%% %7s %7s %8d %13s %s\n",
      "$domain/$client",
      $sent/1024/1024/1024,$maxsent/1024/1024/1024,$scan/1024/1024/1024,$chgrate,
      substr($elap,0,5),substr($maxelap,0,5),$files,
      $ver,$os;

    print OUTPUT "\n\n=========================================================================\n";
    printf OUTPUT "CLIENT: $domain/$client PERFORMANCE\n";
    $cmd="avtar --showlog --path=$domain/$client 2>&1";
    $log=`$cmd`;
    print OUTPUT $log;

    $c+=1; last if ($c>4);
  }
}
print LOG "FINISHED\n";
}

#  Begin XMLTree
sub bu_XMLTree{  bu_printElement(@{ shift @_ }); }
sub bu_printElement
{
  my ($tag, $content) = @_;
  if (ref $content) {    # This is a XML element OPEN TAG:
    $in_tag=$tag;
    my $attrHash = $content->[0];
    $in_tag=$tag if ($tag ne "param");
    for (my $i = 1; $i < $#$content; $i += 2) {
      bu_printElement(@$content[$i, $i+1]);
    }
    ### CLOSE TAG
    if ($tag eq "Row" ){
      next if ($backup->{'Status'} eq "Completed") ;
      next if ($backup->{'Status'} =~ "Waiting") ;
      next if ($backup->{'Status'} =~ "Replication") ;
    
      my $started = $backup->{'StartTime'};
      $started =~ s/[-:]/ /g;
      my ($yy,$mm,$dd,$hr,$min) = split(" ",$started);
      $started = timegm(0,$min,$hr,$dd,$mm-1,$yy);
      my $client="$backup->{'Domain'}/$backup->{'Client'}";

      next if ($latest_backup->{$client} > $started);
      $latest_backup->{$client}=$started;
      $latest_status->{$client}=$backup->{'Status'};
     }
  } else {
    ### This is a text pseudo-element:
    my $testcontent = $content;
    $testcontent =~ s/[\t\n ]//g;
    if ( $testcontent ) {
      $backup->{$in_tag}=$content;
    }
  }
} # end printElement
########## End get_backup_info ########

########## Start getconfiginfo ########
sub getconfiginfo {
  $GOTCONFIGINFO=1;
# Get nodelist settings
  $xml = new XML::Parser( Style => 'Tree' );
  print LOG "parse avmaint nodelist\n";
  my $tree=$xml->parsefile("avmaint nodelist|");
  SimpleXMLTree($tree);
  %NODELIST=%xmltree;
# Get config settings
  $xml = new XML::Parser( Style => 'Tree' );
  print LOG "parse avmaint --ava config\n";
  $tree=$xml->parsefile("avmaint --ava config|");
  SimpleXMLTree( $tree);
  %CONFIG=%xmltree;
if ($DO_HEALTHCHECK) {`avmaint --ava config > hc_avmaint_config.txt`;}
# Get sched settings
  if (!grep $_ eq $AVAMARVER, (@v3x,@v4x) ) {
    $xml = new XML::Parser( Style => 'Tree' );
    print LOG "parse avmaint --ava sched status \n";
    $tree=$xml->parsefile("avmaint --ava sched status|");
    SimpleXMLTree($tree);
    %SCHED=%xmltree;
    if ($DO_HEALTHCHECK) {`avmaint --ava sched status > hc_avmaint_sched.txt`;}
  }
#
# HUGE command to collect data in one mapall
#

# --ALL USER=ROOT
  print LOG "Get data where root is required\n";
# NOTE: this section creates dynamically named arrays.  @RPMS and @DATA_SECUPD
  my $cmd=qq[
    rpm -qa | sed -e 's/^/RPMS:/'
    # securityupdates
    ( awk -F'"' '/<package-survey/ {print \$2}' /usr/local/avamar/var/package-survey-*post_errata* |sort|tail -1 )2>&1 | sed -e 's/^/DATA_SECUPD:/'
  ];
  mapall("$ALL --user=root",$cmd );
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) {chomp;
    my($sub,$line)=split(":",$_,2);
    $node=$1 if (/(\(0\..*\)) ssh/);
    push(@$sub,"$node $line");
  }

# USER=ADMIN
##### NOTE: this section creates dynamically named arrays of DATA_* like DATA_SECUPD, DATA_REPO
  $cmd=qq[ 
    # repoempty
    # x="/data01/avamar/repo/packages"; find \$x -type f -exec echo "REPO:\$x" \\; | uniq
    x="/data01/avamar/repo/temp"; find \$x -type f -exec echo "REPO:\$x" \\; | uniq
    sed -n '/Neighbor table overflow/{p;q;}' /var/log/messages | sed -e 's/^/checkmessages:/g'
  ];
  mapall("--all+",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    my($sub,$line)=split(":",$_,2);
    $node=$1 if (/(\(0\..*\)) ssh/);
    $sub="DATA_$sub";
    push(@$sub,"$node $line");
  }

# SET SOME VARIABLES BASED ON STATUS:
  $MAINT_RUNNING="";
  $MAINT_RUNNING="GC" if ($NODELIST{'/nodestatuslist/gcstatus/status'} eq "processing");
  $MAINT_RUNNING="CP" if ($NODELIST{'/nodestatuslist/cpstatus/status'} eq "processing");
  $MAINT_RUNNING="HFS" if ($NODELIST{'/nodestatuslist/hfscheckstatus/status'} eq "waitcgsan");

}
########## End getconfiginfo ########

########## Start checkconfig ########
sub checkconfig {
  print LOG "\n\n\n### ".localtime()." ### Starting checkconfig\n";

  %gsanconfig=(
    "/gsanconfig/disknocreate"     => ["90",""],
    "/gsanconfig/cpmostrecent"     => ["^2",""],
    "/gsanconfig/disknocp"         => ["96",""],
    "/gsanconfig/disknogc"         => ["8[56789]","Can be higher in version 5 but should be less than 90"],
    "/gsanconfig/disknoflush"      => ["94",""],
    "/gsanconfig/cphfschecked"     => ['^1$',""],
    "/gsanconfig/diskreadonly"     => ["65","Settings lower than 65 are usually intentional (AVE, Encrypt at Rest or licensing).  Consult local team before raising."],
    "/gsanconfig/asynccrunching"   => ["true",""]
    );
# Change settings for AER
  if ($NODETYPE =~ /AER/i) {
  %gsanconfig=(
    "/gsanconfig/disknocreate"     => ["93",""],
    "/gsanconfig/disknocp"         => ["95",""],
    "/gsanconfig/disknogc"         => ["92",""],
    "/gsanconfig/diskreadonly"     => ["90",""]
    );
  }

# Dont check balancemin after 6.0
  if ($VERSNUM <610 ) {
    %gsanconfig=(%gsanconfig, "/gsanconfig/balancemin" => ['^0$',""]);
  }

# Add config added after vers4
  if (!grep $_ eq $AVAMARVER, (@v3x,@v4x) ) {
    %gsanconfig=(%gsanconfig, "/gsanconfig/cpdaily" => [2,""]);
    %gsanconfig=(%gsanconfig, "/gsanconfig/indexcacheallowed"=> [1, "Can be set to 0 on 2TB nodes that are swapping.  See KB163397"]) if !$VBA;
  }


# Check for CP settings
  if ($CONFIG{"/gsanconfig/cphfschecked"} eq 1 and $CONFIG{"/gsanconfig/cpmostrecent"} eq 2){
    $CP_RETENTION="PASSED";
    msg("Checkpoint Retention","PASSED");
  } else {
    $CP_RETENTION="FAILED";
    printboth("CRITICAL ERROR:  Checkpoint retention not the default of cpmostrecent=2 and cphfschecked=1\n"); $LOGOFF_ERR++;
    msg("Checkpoint Retention","FAILED");
  }

  my $msg="";
  foreach $key (keys %gsanconfig) {
    ($foo,$foo,$pkey)=split("/",$key);
    printf LOG "%-30s = %-3s Default=%-3s  %s\n",$pkey,
      $CONFIG{$key},$gsanconfig{$key}[0],$gsanconfig{$key}[1];
    $regex=$gsanconfig{$key}[0];
    if ($CONFIG{$key} !~ m/$regex/ ) {
      printf SETTINGS "%-30s = %-3s Default=%-3s  %s\n",$pkey,
        $CONFIG{$key},$gsanconfig{$key}[0],$gsanconfig{$key}[1];
      $msg = $msg.sprintf "   %-20s Default=%-5s %s\n",$pkey."=".
        $CONFIG{$key},$gsanconfig{$key}[0],$gsanconfig{$key}[1];
    }
  }
  if ($msg) {
      printboth("WARNING: Configuration parameters changed from defaults\n");
      printboth($msg);
      printboth("RESOLUTION: Find out why they have been changed.\n\n");
      msg("Config Settings","WARNING");
  } else {
      msg("Config Settings","PASSED");
  }


# Go through sched status settings
   if (!grep $_ eq $AVAMARVER, (@v3x,@v4x) ) {

    if (!grep $_ eq $AVAMARVER, (@v3x,@v4x,@v5x) ) {
     if ($SCHED{'/maintenance-windows/task-param-list/gc/usehistory'} eq "true") {
       printboth("ERROR: Garbage collection use history is set to true.  This may cause GC to prematurely stop\n");
       printboth("RESOLUTION: Set it to false: avmaint --ava sched gc --usehistory=false --permanent\n\n");
       msg("Garbage Collection Use History","FAILED");
     }
     if ($SCHED{'/maintenance-windows/task-param-list/hfscheck/overtime'} ne "true" ){
      printboth("ERROR: HFSCheck overtime is set to false\n");
      printboth("RESOLUTION: See esc 3597 for more info. Set it to true:\n            avmaint --ava sched hfscheck --overtime=true --permanent\n\n");
      msg("HFSCheck overtime allowed","FAILED");
     } else {
       msg("HFSCheck overtime allowed","PASSED");
     }
    }
    if ($DO_HEALTHCHECK) {
      $mytree="/maintenance-windows/window-param-list/window-params/";
      print SETTINGS
      "backup-window/start            = ".$SCHED{$mytree.'backup-window/start'} ."\n".
      "backup-window/duration         = ".$SCHED{$mytree.'backup-window/duration'} ."\n".
      "blackout-window/start          = ".$SCHED{$mytree.'blackout-window/start'} ."\n".
      "blackout-window/duration       = ".$SCHED{$mytree.'blackout-window/duration'} ."\n".
      "maintenance-window/start       = ".$SCHED{$mytree.'maintenance-window/start'} ."\n".
      "maintenance-window/duration    = ".$SCHED{$mytree.'maintenance-window/duration'} ."\n".
      "hfscheck modified              = ".
         $SCHED{'/maintenance-windows/task-param-list/hfscheck/modified'} ."\n";
    }


# Print some of the already gathered data
    printf SETTINGS "%-30s = %-30s\n","systemid",$NODELIST{'/nodestatuslist/nodestatus/0.0/systemid'};
    printf SETTINGS "%-30s = %-30s\n","GSAN md5sum",$GSAN_MD5SUM;
    printf SETTINGS "%-30s = %-30s\n","Avamar RPM Version   ",$AVAMARVER;
    printf SETTINGS "%-30s = %-30s\n","Data Node Version",$DATANODEVERSION;
    printf SETTINGS "%-30s = %-30s\n","MCS Version",$MCSERVER_VERSION;
    printf SETTINGS "%-30s = %-30s\n","EMS Version",$EMSERVER_VERSION;
  }
}
########## End checkininfo ########


########## Start SimpleXMLTree ########
# This flattens out an XML separating the tags with a / and adding node.id and disk.id
# for example <gsanconfig status=good cp=3> will be:  /gsanconfig/status and /gsanconfig/cp
# for example <nodestatus><node id=0.4 status=good><node id=0.5 status=bad> will be
# /nodestatus/node/0.4/status /nodestatus/node/0.4/id  /nodestatus/node/0.5/status etc...
sub SimpleXMLTree{
  %xmltree=();
  $in_tag="";
  SimplePrintElement("",@{ shift @_ });
}

sub SimplePrintElement
{
  my ($in_tag,$tag, $content) = @_;
  if (ref $content) {    # This is a XML element:
    my $attrHash = $content->[0];
    if ($tag eq "param"){
      my $newkey="$in_tag/$attrHash->{'name'}";
      $xmltree{$newkey} = $attrHash->{'value'};
      #print LOG "$newkey = ". $attrHash->{'value'} ."\n" ;
    } else {
      $in_tag = $in_tag."/".$tag;
      if ($tag eq "nodestatus") {
        push(@NODES,$attrHash->{'id'});
        $in_tag = $in_tag."/".$attrHash->{'id'};
      }
      if ($tag eq "disk") {
        $in_tag = $in_tag."/".$attrHash->{'id'};
      }
      if ($tag eq "ddrconfig") {
        push(@DD_INDEX,$attrHash->{'index'});
        $in_tag = $in_tag."/".$attrHash->{'index'};
      }
      if ($tag eq "checkpoint") {
        $in_tag = $in_tag."/".$attrHash->{'tag'};
      }
      for $key (keys %$attrHash) {
        my $newkey=$in_tag."/".$key;
        $xmltree{$newkey} = $attrHash->{$key};
        #print LOG "$newkey = ". $attrHash->{$key} ."\n" ;
      }
    }
    for (my $i = 1; $i < $#$content; $i += 2) {
      SimplePrintElement($in_tag,@$content[$i, $i+1]);
    }
    ### CLOSE TAG
  } else {
    ### This is a text pseudo-element:
    my $testcontent = $content;
    $testcontent =~ s/[\t\n ]//g;
    if ( $testcontent ) {
      $xmltree{$in_tag}=$content;
    }
  }
} # end printElement
########## End SimpleXMLTree ########

########## Start check_repl ########
sub check_repl {

  print LOG "\n\n\n### ".localtime()." ### Starting check_repl\n";

  if (-e "/usr/local/avamar/etc/repl_cron.cfg"){
    print LOG "======================================================\nrepl_cron.cfg\n".
        "======================================================\n".
        `grep -v '^$\|^#' /usr/local/avamar/etc/repl_cron.cfg`;
  }
  print LOG "======================================================\ncrontab -u dpn -l | grep -v '^$\|^#'\n".
            "======================================================\n";
  $cmd = qq[ crontab -u dpn -l ];
  mapall("--nodes=0.s --user=root",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    next if ( $_ =~ /^#/ );
    if ($_ =~ /repl_cron/) {
      my ($min,$hour,$dom,$mon,$dow)=split(" ");
      printf SETTINGS "%-30s %02d:%02d\n","Replication Start",$hour,$min;
      if ($dom ne "*" or $mon ne "*" or $dow ne "*" ) {
        printboth("\nWARNING:  Replication not setup to run every day\n");
        msg("Replication Cron Setup","FAILED");
      } else {
        msg("Replication Cron Setup","PASSED");
      }
    }
  }
}
########## End check_repl ########

########## Start checktime ########
sub checktime {

  print LOG "\n\n\n### ".localtime()." ### Starting checktime\n";

  getavamarver() if (!$AVTAR_VERSION);

  if ($VBA and qx{ps -A | grep ntpd} ) {
    printboth("ERROR:  NTPD time server is running\n");
    printboth("RESOLUTION:  Stop and disable ntpd timer server\n\n");
    msg("Time Server","FAILED");
    return;
  }

  if ($NODE_COUNT == 1) {
    print LOG "Check skipped for single node servers\n";
    return;
  }

  $cmd=q[ echo -e "DATE \c"; date '+%s' ; /usr/sbin/ntpq -pn ];
  mapall("--all",$cmd);
  open(CMD_PIPE,$TMPFILE);
  my ($badtime,$timeserver,$node)="";
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/){
      if ($node and !$primntp) {
        printboth("ERROR:  Node $node Primary time server not found\n");
        $timeserver="yes";
      }
      $node=$1;
    }
    if (/^DATE (.*)/) {
      $lastepoch=$1 if (!$lastepoch);
      if (abs($lastepoch-$1)>8) {
        printboth("ERROR:  Node $node time is out of sync by ". ($lastepoch-$1) ." seconds\n");
        $badtime="yes";
      }
      $lastepoch=$1 ;
    }
    if ( $_ =~ /^\*/ ) {
      my ($ip,$refid,$foo)=split(" ");
      print LOG "--> $node primary is $ip\n";
      $primntp=$ip;
    }
  }
  if (!$timeserver and !$badtime) {
    msg("Time Settings","PASSED");
  } else {
    printboth("RESOLUTION:  Verify nodes are out of time sync. Run asktime if they are.\n\n");
    msg("Time Settings","FAILED");
  }
}
########## End checktime ########

########## Start sched ########
sub sched {

  openmcdb() if (!$dbh);
  print LOG "\n\n\n### ".localtime()." ### Starting sched\n" if !($sched);
$sched_days=30;
if ($IN_DAYS) { $sched_days=$IN_DAYS; }

  print("HEALTHCHECK:  Creating hc_sched.txt\n") if (!$sched);
  if (!$sched) {
    open(OUTPUT,">hc_sched.txt");
  } else {
    *OUTPUT=*STDOUT
  }
  if ($WIDE || !$sched) {
    $interval=4;
    print OUTPUT "                                                   1   1   1   1   1   1   1   1   1   1   2   2   2   2  ".`date '+%Z'`;
    print OUTPUT "           0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5   6   7   8   9   0   1   2   3 \n";
  } else {
    $interval=3;
    print OUTPUT "                                         1  1  1  1  1  1  1  1  1  1  2  2  2  2  ".`date '+%Z'`;
    print OUTPUT "           0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3\n";
}

# GET BACKUPS
  my $SECONDS=$sched_days*86400;
  my $sql = qq[
    select started_ts, completed_ts, status_code, type from v_activities
    where $SECONDS >= (date_part('epoch',current_date) - date_part('epoch',started_ts))
    and status_code <> 30901
    order by type
  ];

  my $sth = $dbh->prepare($sql);
  $sth->execute;

  while ( @row = $sth->fetchrow_array() ) {
    my ($start,$complete,$status,$type)=@row;
    switch ($type) {
      case /Snapup/                  { $type="b" }
      case "Replication Destination" { $type="d" }
      case "Replication Source"      { $type=""  }
      case "Restore"                 { $type="e" }
      else { $type="u" }
    }
    if ($status !~ /30000|30005/) { uc $type }
      $s=sched_toepoch(split(" ",$start));
      $e=sched_toepoch(split(" ",$complete));
      sched_addtype($s, $e, $type ) if ($type);
  }

# Maint routines
  my ($sec, $mn, $hr, $dd, $mm, $yy) = (localtime(time - 86400*$sched_days))[0,1,2,3,4,5,6];
  $mm++; $yy+=1900;
  my $DATE=sprintf("%4d-%02d-%02d",$yy,$mm,$dd);
  $sql = qq[
    select date,time,code
    from v_events
    where date>= '$DATE'
    and code > 4000 and code < 4999
    order by date,time
  ];

  $sth = $dbh->prepare($sql);
  $sth->execute;

  while ( @row = $sth->fetchrow_array() ) {
    my ($date,$time,$code)=@row;
    my $epoch = sched_toepoch($date,$time);

    $startcp=$epoch if ($code eq "4300");
    $starthfs=$epoch if ($code eq "4002");
    $startgc=$epoch if ($code eq "4200");
    $startrepl=$epoch if ($code eq "4600");

    switch($code) {
      case 4002 { $starthfs=$epoch }
      case 4003 { sched_addtype($starthfs,$epoch,"h","") if ($starthfs);$starthfs=undef}
      case 4004 { sched_addtype($starthfs,$epoch,"H","") if ($starthfs);$starthfs=undef}
      case 4200 { $startgc =$epoch }
      case 4201 { sched_addtype($startgc,$epoch,"g","") if ($startgc);$startgc=undef}
      case 4202 { sched_addtype($startgc,$epoch,"G","") if ($startgc);$startgc=undef}
      case 4300 { $startcp =$epoch }
      case 4301 { sched_addtype($startcp,$epoch,"c","")  if ($startcp);$startcp=undef}
      case 4302 { sched_addtype($startcp,$epoch,"C","")  if ($startcp);$startcp=undef}
      case 4600 { $startrepl=$epoch }
      case 4601 { sched_addtype($startrepl,$epoch,"r","") if ($startrepl);$startrepl=undef}
      case 4602 { sched_addtype($startrepl,$epoch,"R","") if ($startrepl);$startrepl=undef}
    }
  }

# Print It
my $lastdate="";
foreach $key (sort keys %daysused) {
  ($date,$line)=split(" ",$key);
  if ($lastdate ne $date and $lastdate) { print OUTPUT "\n"; }
  $lastdate=$date;
  print OUTPUT "$date ";
  for ($hour=0;$hour<=$interval*24;$hour++) {
    if ($daysused{$key}[$hour]) {
      if ( $daysused{$key}[$hour] > 0 ) {
         $daysused{$key}[$hour] = 0+int($daysused{$key}[$hour] / 10);
         $daysused{$key}[$hour] ="b" if ( $daysused{$key}[$hour] > 10 ) ;
      }
      print OUTPUT $daysused{$key}[$hour]
    } else {
      print OUTPUT ".";
    }
  }
  print OUTPUT "\n";
}
  print OUTPUT "\nh=hfs, c=CP, g=GC, r=Repl, d=ReplDest, e=restore, uppercase means failed activity\nA number is how many backups are running, 0=0-9, 1=10-19, b=100 or more backups\n";
  if (!$sched) {
    print LOG "FINISHED\n"
  } else {
    print "\n";
  }

}

sub sched_toepoch {
  my ($yy,$mm,$dd)=split("-",$_[0]);
  my ($hr,$min,$sec)=split(":",$_[1]);
  return timegm(0,$min,$hr,$dd,$mm-1,$yy) ;
}

sub sched_ndx { return sprintf"%d/%02d/%02d %d",$_[0],$_[1],$_[2],$_[3] }

sub sched_addtype {
  my ($start,$complete,$type) = @_;
  my $epoch;
  $line=0;
  if ($type ne "b") {
    $bad=1;
    while ($bad eq 1) {
      $bad=0;
      for ($epoch=$start;$epoch<=$complete;$epoch+=(3600/$interval)) {
        my ($sec, $mn, $hr, $dd, $mm, $yy) = (localtime($epoch))[0,1,2,3,4,5,6];
        $mm++; $yy +=1900;
        $min=int($mn/(60/$interval));
        if ($daysused{sched_ndx($yy,$mm,$dd,$line)}[$hr*$interval+$min]
            and $daysused{sched_ndx($yy,$mm,$dd,$line)}[$hr*$interval+$min] ne $type) {
          $bad=1;
          $line++;
          last;
        }
      }
    }
  }
  for ($epoch=$start;$epoch<=$complete;$epoch+=(3600/$interval)) {
    my ($sec, $mn, $hr, $dd,$mm,$yy) = (localtime($epoch))[0,1,2,3,4,5,6];
    $mm++; $yy +=1900;
    $min=int($mn/(60/$interval));
    if ($type eq "b") {
       $daysused{sched_ndx($yy,$mm,$dd,$line)}[$hr*$interval+$min] +=1;
    } else {
       if ($epoch+(3600/$interval)>=$complete) {
         $daysused{sched_ndx($yy,$mm,$dd,$line)}[$hr*$interval+$min]=$type;
       } else {
         $daysused{sched_ndx($yy,$mm,$dd,$line)}[$hr*$interval+$min]=lc($type);
       }
    }
  }
}
########## End sched ########

########## Start backup_config ########
sub backup_config {

  print LOG "\n\n\n### ".localtime()." ### Starting backupconfig\n";

  open(CMD_PIPE,"/usr/bin/ssh -l root localhost -i ~/.ssh/dpnid '/usr/local/avamar/bin/backup_upgrade_files 2>&1' |");
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    next if ($_ =~ /copying/);
    if ($_ =~ /Completed.  Inspect .root.backup_upgrade_files.(.*).log/){
       my $basename=$1;
       $cmd="/usr/bin/ssh -l root localhost -i ~/.ssh/dpnid  ".
            "'tar czf /tmp/backup_upgrade_files.$basename.tgz /tmp/backups_$basename 2>&1 ".
            " && chmod a+rw /tmp/backup_upgrade_files.$basename.tgz'";
       $results=`$cmd`;
       print LOG "Creating tar file: $cmd\n$results";

       if ($NODE_COUNT>1){
         $cmd="/usr/bin/ssh-agent bash -c '/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; ".
            " cd /tmp; mapall  --nodes=0.0,0.1 copy backup_upgrade_files.$basename.tgz 2>&1' ";
         my $results=`$cmd`;
         if ($? ne 0){
          printboth("ERROR:  Unable to copy backup_upgrade_files to nodes.  Results: $results\n\n");
          msg("backup_upgrade_files","FAILED");
         } else {
          msg("backup_upgrade_files","PASSED");
         }
         print LOG "Copying tar file to nodes:$cmd\n$results";
       } else {
         if (-e "/usr/local/avamar/etc/repl_cron.cfg"){
           my $dstaddr = `grep  dstaddr /usr/local/avamar/etc/repl_cron.cfg | grep  -v "^#"`;
           my ($var1,$addr) = split('=',$dstaddr);
           chomp($addr,);
           my $cmd="cd /tmp; scp -i ~/.ssh/dpnid backup_upgrade_files.$basename.tgz admin@".$addr.":";
           print LOG "scp cmd: $cmd\nResults: $results\n";
           $results=`$cmd`;
           if ($? ne 0) {
             printboth("ERROR:  Unable to copy backup_upgrade_files to replication target.  Results: $results\n\n");
             msg("backup_upgrade_files","FAILED");
           }  else {
             msg("backup_upgrade_files","PASSED");
           }
         } else {
           printboth("WARNING:  File /tmp/backup_upgrade_files.$basename.tgz should be manually copied/saved\n\n");
           msg("backup_upgrade_files run","FAILED");
         }
       }
    } #if completed
  }  #while
} #endsub

########## End backup_config ########


########## Start getuserdata ########
sub getuserdata {

  print LOG "--> showMenu \n";
  unlink("hc_email.txt");
  my $rc = do ("/home/admin/.pac_defaults");

  $input = "";
  while(1)
  {
    print "\n$PROG $PROGVER\n";
    print   "======================\n";
    if ($FORCE) {
      print "0) Force Reason.................$FORCE_reason\n";
    }
    print "1) SR Number....................$srnumber\n";
    print "2) Your Name....................$yourname\n";
    print "3) Customer Contact First Name..$customername\n";
    print "4) SR Description...............$srdesc\n";
    print "5) Create Report\n";
    print "q) Quit\n\n";

    print "Enter your choice: ";
    chomp($input = <STDIN>);
    if($input eq "q") { exit 0; }
    if($input eq "5") {
      if ( (!$srnumber) or (!$yourname) or (!$customername) or (!$srdesc)  or ($FORCE and !$FORCE_reason) ) {
        print "You must enter all information before creating the report\n";
        next;
      } else {
        msg("Logoff Info","","$srnumber|$yourname|$customername|$srdesc|$FORCE|$FORCE_reason");
        last;
      }
    }

    switch ($input) {
      case 1 { print "SR#"; chomp($in=<STDIN>); if ($in) {$srnumber=$in; writedefaults() } }
      case 2 { print "Your Name: ";  chomp($in=<STDIN>); if ($in) { $yourname=$in; writedefaults() } }
      case 3 { print "Customer Name: ";  chomp($in=<STDIN>); if ($in) { $customername=$in; writedefaults() }}
      case 4 { print "SR Description: ";  chomp($in=<STDIN>); if ($in) { $srdesc=$in; writedefaults() }}
      case 0 { print "Force Reason: ";  chomp($in=<STDIN>); if ($in) { $FORCE_reason=$in; writedefaults();
               printboth("Critical Checks forced to pass:  $FORCE_reason\n"); }}
      else { print "Invalid selection\n\n"; }
    }
  }
}
sub writedefaults {
    open(DEFAULTS,">/home/admin/.pac_defaults");
#    print DEFAULTS "\$srnumber='$srnumber';\n\$customername='$customername';\n\$srdesc='$srdesc';\n";
    print DEFAULTS "\$srnumber='$srnumber';\n\$yourname='$yourname';\n\$customername='$customername';\n\$srdesc='$srdesc';\n\$FORCE_reason='$FORCE_reason';\n";
    close(DEFAULTS);
}
########## End getuserdata ########

########## Start logoff_report ########
sub logoff_report {

  print LOG "\n\n\n### ".localtime()." ### Starting logoff_report\n";
  print LOG "logoff_err = $LOGOFF_ERR\n";

  if ($LOGOFF_ERR > 0 and (!$FORCE_reason) ) {
    printboth("\nCRITICAL checks have failed.  Resolve the errors before leaving the grid\n");
    print  "\nCRITICAL checks have failed.  Resolve the errors before leaving the grid\n";
    if ($GSAN_MCS_EMS =~ /PASSED|WARNING/ ) { print "GSAN, MCS or EMS services are down (dpnctl status)\n"; }
    if ($MAINT_SCHED ne "PASSED") { print "Maintenance Scheduler is not enabled or running (dpnctl status)\n";}
    if ($BACKUP_SCHED ne "PASSED") { print "Backup Scheduler is not enabled or running (dpnctl status)\n";}
    if ($CRON_SCHED ne "PASSED") { print "Cron is not running or scheduler not enabled (dpnctl status or ps -ef)\n";}
    if ($MCGUI_STATUS ne "PASSED") { print "Access to MCGUI is not working (mccli server show-prop)\n";}
    if ($BACKUP_DONE =~ /PASSED|WARNING/) { print "Backup to the GSAN failed (mcserver.sh --flush)\n";}
    if ($CP_RETENTION ne "PASSED") { print "Checkpoint retention is not set to defaults (avmaint --ava config | grep cp)\n";}
    return;
  }

  printboth("\nAll CRITICAL checks have passed.  View hc_email.txt for email message\n");
  print "\nAll CRITICAL checks have passed.  View hc_email.txt for email message\n";
  my $email = qq[
SR $srnumber reference Avamar system: $HOSTNAME & issue $srdesc


Dear $customername

The issue $srdesc related to Avamar system $HOSTNAME has been resolved and the Avamar system has been brought up to a fully operational state by TSE $yourname. The current system status is as outlined below.

- This Service Request has been placed in monitor mode pending completion of one cycle of the backup scheduler and the maintenance scheduler.
- As this Avamar System is emailing home, we will confirm this through the email home report and follow-up with a final email to inform and confirm that the SR is being closed as the system had successfully reported in.
- If you run into issues directly related to this SR before closure, please do not hesitate in informing us by updating the service request so that the SR can remain open and the issue worked by an Avamar TSE

Avamar System Status Summary:

 1.      $GSAN_MCS_EMS - GSAN, MCS and EMS services are up and fully operational
 2.      $MAINT_SCHED - Maintenance Scheduler has been checked to ensure it has been enabled and running
 3.      $BACKUP_SCHED - Backup Scheduler has been checked to ensure it has been enabled and running
 4.      $CRON_SCHED - Cron scheduler has been <enabled/disabled> for your version of Avamar and your custom configuration
 5.      $MCGUI_STATUS - Access to MCGUI for MCS and EM for Enterprise Manager has been confirmed
 6.      $BACKUP_DONE - The gsan ability to receive backup data has been confirmed by performing an MCS and EMS Flush
 7.      $CAPACITY_STATUS - The current overall capacity of the system has been confirmed to be healthy
 8.      $CP_RETENTION - Checkpoint retention has been returned to default setting of cpmostrecent="2" and cphfschecked="1"
 9.      The Avamar System has been checked to confirm that it is emailing home to Avalanche & ConnectEMC/SYR. Sample email home report to Avalanche has been included below for reference

];

print LOG "$email";
open(OUTPUT,">hc_email.txt");
print OUTPUT "$email";
close OUTPUT;
}
########## End logoff_report ########


########## Start dpnctl_status ########
sub dpnctl_status {

  my $status;
  print LOG "\n\n\n### ".localtime()." ### Starting dpnctl_status\n";
  getnodetype() if (!%PARTLIST);
  getconfiginfo() if (!$GOTCONFIGINFO);
  nodexref() if (!$NODE_COUNT);

  open(FILE,"dpnctl status 2>&1|");

  while(<FILE>) {
    print LOG $_ ;
      if ($_ =~ /gsan status: (.*)/) { $gsan_status = $1 ; print LOG "GSAN: $1\n"; }
      if ($_ =~ /MCS status: (.*)\./) { $mcs_status = $1 ; print LOG "MCS : $1\n"; }
      if ($_ =~ /EMS status: (.*)\./) { $ems_status = $1 ; print LOG "EMS: $1\n"; }
      if ($_ =~ /emt status: (.*)\./) { $emt_status = $1 ; print LOG "emt: $1\n"; }
      if ($_ =~ /avinstaller status: (.*)\./) { $avi_status = $1 ; print LOG "avi: $1\n"; }
      if ($_ =~ /Backup scheduler status: (.*)\./) { $backupsched_status = $1; print LOG "BACKUP Sched: $1\n";}
      if ($_ =~ /Scheduler status: (.*)\./) { $backupsched_status = $1 ; print LOG "BACKUP Sched: $1\n"; }
      if ($_ =~ /dtlt status: (.*)\./) { $dtlt_status = $1; print LOG "DTLT: $1\n"};
      if ($_ =~ /windows scheduler status: (.*)\./) { $maintsched_status = $1; print LOG "Maint Sched: $1\n";}
      if ($_ =~ /cron jobs status: (.*)\./) { $cronjobs_status = $1; print LOG "Cron: $1\n";}
      if ($_ =~ /Maintenance operations status: (.*)\./) { $cronjobs_status = $1; print LOG "Cron: $1\n";}
      if ($_ =~ /Unattended startup status: (.*)\./) { $unattendedstart_status = $1 ; print LOG "startup: $1\n";}
  }

  $GSAN_MCS_EMS = "PASSED";
  if ($gsan_status ne "ready" and $gsan_status ne "up") {
    if ($MAINT_RUNNING) { 
        printboth("WARNING: GSAN status is $gsan_status because $MAINT_RUNNING is running. Skipping some checks\n");
        msg("GSAN status","WARNING");
    } else {
        printboth("CRITICAL ERROR:  GSAN status is $gsan_status\n"); $LOGOFF_ERR++;
        msg("GSAN status","FAILED");
        $LOGOFF_ERR++;
        $GSAN_MCS_EMS = "FAILED";
    }
  } else {
        msg("GSAN status","PASSED");
  }

  if ($mcs_status ne "up" ) {
        printboth("CRITICAL ERROR:  MCS status is $mcs_status\n");  $LOGOFF_ERR++;
        msg("MCS status","FAILED");
        $LOGOFF_ERR++;
        $GSAN_MCS_EMS = "FAILED";
  } else {
        msg("MCS status","PASSED");
  }

  if (!$VBA and $VERSNUM<720 ){
    if ($ems_status ne "up" ) {
        printboth("ERROR:  EMS status is $ems_status\n");
        msg("EMS status","FAILED");
        $LOGOFF_ERR++;
        $GSAN_MCS_EMS = "FAILED";
    } else {
        msg("EMS status","PASSED");
    }
  }
  if (!$VBA and $avi_status and $avi_status ne "up"){
    printboth("ERROR:  AVI Installer status is $avi_status\n");
    msg("AVI Installer status","FAILED");
  }
  if (!$VBA and $emt_status and $emt_status ne "up"){
    printboth("ERROR:  EMT status is $emt_status\n");
    msg("EMT status","FAILED");
  }

print LOG "NODETYPE is $NODETYPE\n";
  if ($NODETYPE =~ /AER/i) {
    print LOG "Skipping Backup Sched, DTLT, MaintSched for AER $NODETYPE\n";
  } else {
    if ($backupsched_status ne "up" ) {
        printboth("CRITICAL ERROR:  Backup Scheduler Status status is $backupsched_status\n");
        $LOGOFF_ERR++;
        $BACKUP_SCHED="FAILED";
    } else {
        $BACKUP_SCHED="PASSED";
    }
    msg("Backup Scheduler running",$BACKUP_SCHED);

    if ( $VERSNUM>500 and $VERSNUM <720 and !$VBA ) {
      if ($dtlt_status ne "up")  {
        printboth("CRITICAL ERROR:  DTLT status is $dtlt_status\n");
        $LOGOFF_ERR++;
        msg("Desktop/Laptop running","FAILED");
      } else {
        msg("Desktop/Laptop running","PASSED");
      }
    }

    if ($VERSNUM > 500)  {
      if ($maintsched_status ne "enabled" )  {
          printboth("CRITICAL ERROR:  Maintenance windows scheduler status is $maintsched_status\n");
          $LOGOFF_ERR++;
          $MAINT_SCHED="FAILED";
      } else {
          $MAINT_SCHED = "PASSED";
      }
    msg("Maintenance scheduler running",$MAINT_SCHED);
    } else {
      print LOG "Maint Scheduler Skipped for version $AVAMARVER\n";
      $MAINT_SCHED = "PASSED";
    }
  }
  # for vers 6+ cron maint is not printed. check for suspended file only
  if ( -e "/usr/local/avamar/var/cron/suspended") {
    $cronjobs_status="suspended."
  }
  if ( (!grep $_ eq $AVAMARVER, (@v3x,@v4x,@v5x)) and !$cronjobs_status ) {
    $cronjobs_status="enabled"
  }
  if ($cronjobs_status ne "enabled") {
    printboth("CRITICAL ERROR:  Maintenance cron jobs status is $cronjobs_status\n");
    printboth("RESOLUTION:  Determine why they are suspended.  Use 'resume_crons'\n\n");
    $LOGOFF_ERR++;
    $CRON_SCHED="FAILED";
    msg("Cron jobs enabled","FAILED");
  } else {
    $CRON_SCHED="PASSED";
    msg("Cron jobs enabled","PASSED");
  }

  if ($VERSNUM > 600 and $NODE_COUNT > 1 ) {
    print LOG "Unattended startup not checked for v6 multinode: $AVAMARVER with $NODE_COUNT nodes\n";
    msg("Unattended startup","PASSED");
  } else {
    if ( $unattendedstart_status eq "enabled" and ( $NODE_COUNT > 1 or $DD)) { 
      printboth("ERROR:  Unattended startup status is $unattendedstart_status\n");
      printboth("RESOLUTION:  Unattended startup should not be enabled on multi-node servers or if Data Domain is attached\n\n");
      msg("Unattended startup","FAILED");
    } else { 
      msg("Unattended startup","PASSED");
    }
  }

}
########## End dpnctl_status ########


########## Start cronrunning ########
sub cronrunning {

  print LOG "\n\n\n### ".localtime()." ### Starting cronrunning\n";
  if ( $NODE_INFO{"(0.s)"}{os} =~ /suse/ ) {
    $results=`ps -C cron`;
    print LOG "suse - Checking for cron: ps -C cron\n";
    if ($results =~ /cron/ ) { $results="running\n".$results; }
  } else {
    print LOG "checking for crond\n";
    $results=`service crond status`;
  }
    print LOG "RESULTS: $results";
    if ( $results !~ /running/) {
          printboth("CRITICAL ERROR:  cron or crond is not running\n");
          printboth("RESOLUTION:  Check /var/log/messages for cron messages.  Run 'service crond start' as root.\n\n");
          msg("Cron Running","FAILED");
          $LOGOFF_ERR++;
    } else {
          msg("Cron Running","PASSED");
          print LOG "Cron running\n";
    }
}
########## End cronrunning ########

########## Start test_flush ########
sub test_flush {

  print LOG "\n\n\n### ".localtime()." ### Starting test_flush\n";
  if ($gsan_status ne "ready" and $gsan_status ne "up") {
     printboth("\nWARNING: Unable to backup MCS database because GSAN status is $gsan_status\n");
     printboth("RESOLUTION:  Check the gsan status\n");
     $BACKUP_DONE="FAILED";
     msg("Test Backup with MC Flush","WARNING");
     return;
  }
  my $cmd = qq[ rununtil 60 mcserver.sh --flush ];
  my $results = `$cmd`;
  print LOG "Command: $cmd\nResults:\n$results\n";
  if ($results =~ /Administrator Server flushed/) {
        print LOG "--> flush successful\n";
        $BACKUP_DONE="PASSED";
        msg("Test Backup","PASSED");
  } else {
        printboth("CRITICAL ERROR:  Unable to backup MCS database\n");
        printboth("RESOLUTION:  Check /usr/local/avamar/var/mc/server_log/flush.log, GSAN status and $logfile\n\n");
        $LOGOFF_ERR++;
        $BACKUP_DONE="FAILED";
        msg("Test Backup","FAILED");
  }
}
########## End test_flush ########


########## Start  check_capacity ########
sub check_capacity {
  print LOG "\n\n\n### ".localtime()." ### Starting check_capacity\n";

  my $err=1;

  my $cmd = qq[ mccli server show-prop ] ;
  print LOG "Command: $cmd\n";
  open(CMD_PIPE,$cmd."|");
  while (<CMD_PIPE>) { chomp;
  print LOG "$_\n";
  if ( $_ =~ /Server utilization/) {
    my ($foo,$util)=split(" ");
    $util =~ s/\%//g;
    print LOG "Utilization is $util\n";
    if ($1>90) {
      $CAPACITY_STATUS="FAILED";
      print LOG "$CAPACITY_STATUS\n";
      msg("Capacity Level","PASSED");
    } else {
      $CAPACITY_STATUS="PASSED";
      msg("Capacity Level","PASSED");
    }
  }
  }
  if ($err) {
     $MCGUI_STATUS="PASSED";
     msg("MCS Responding","PASSED");
  } else {
     $MCGUI_STATUS="FAILED";
     msg("MCS Responding","FAILED");
  }
}
########## End check_capacity ########

########## Start checkncq ##########
sub checkncq {
  print LOG "\n\n\n### ".localtime()." ### Starting checkncq\n";
  my $nodes=getnodes_os("dell");
  if (!$nodes) {
    print LOG "no suse nodes found\n";
    return;
  }
  if (!$OMCONFIG) {
      printboth("WARNING:  omconfig not installed.  Unable to check for NCQ\n");
      printboth("RESOLUTION: Install Dell OMSA tools\n\n");
      msg("Hitachi Disk NCQ","WARNING");
      return;
  }
    undef %disks;
    undef %nodedisks;
    undef %svctags;
    my $drivecount=0;
    my $failed;
    my $nodedrivecount=0;
    my $sawvendor=0;
    my $lastnode="";
    my $explog = `date +%m%d`;
    chomp($explog);
    $cmd=qq[
      rm -f /var/log/lsi_$explog.log
      omconfig storage controller action=exportlog controller=0
      sed -n '/ Vendor .* Product /,/ BACKPLANE /p' /var/log/lsi_$explog.log
      omreport chassis info  | grep '^Chassis Service Tag'
    ];
    mapall("--user=root --nodes=$nodes ",$cmd);
    my $hitachi=`grep -ic hitachi $TMPFILE`;
    chomp($hitachi);
   if ($hitachi eq 0) {
#        printboth("PASSED NCQ.  No Hitachi drives found\n") if ($_[0] ne "q");
        print LOG "CHECKNCQ PASSED\n";
        msg("Hitachi Disk NCQ","PASSED");
        return;
    }

    open(CMD_PIPE,$TMPFILE);
    while (<CMD_PIPE>) { chomp;
      print LOG "$_\n";
      $lastnode=$node;
      $node=$1 if (/(\(0\..*\)) ssh/);
      if ( $_ =~ /^Chassis Service Tag/) {
        my ($foo,$servicetag)=split(':');
        print LOG "--> Node $node Found Service Tag:  $servicetag\n";
        $svctags{$node}=$servicetag;
      }
      if ($node ne $lastnode ) {
        print LOG "NEW NODE $node.  Last node had $nodedrivecount disks with NCQ=0\n";
        $drivecount=$drivecount + $nodedrivecount;
        @disks{keys %nodedisks}= values %nodedisks;
        undef %nodedisks;
        $nodedrivecount=0;
      }
      @columns=split(/\s+/);
      if ( $_ =~ / Vendor\s+Product /  ) {
        $colnum=0;
        foreach (@columns) {
          if ( $columns[$colnum] =~ /^Vendor$/) {
            if ($node==$lastnode) {
              print LOG "Found Vendor Word $columns[$colnum].  Forgetting previous disk info\n";
              $colnum--;
              undef %nodedisks;
              $nodedrivecount=0;
            }
            if ( $columns[$colnum] != /^N/) {
              print LOG "$node Word=$columns[$colnum]\n";
              print LOG "ERROR: found Vendor word but not NCQ column (1)\n";
              next;
            }
            $sawvendor=1;
            print LOG "NCQ Column = $colnum.  Word is $columns[$colnum]\n";
            last
          }
          $colnum++;
        }
        if ($sawvendor==0) {
          print LOG "$node Word=$columns[$colnum]\n";
          print LOG "ERROR: found Vendor line but not Vendor word (2)\n";
          next;
        }
      }
      if ( $columns[$colnum+2] =~ /HITACHI/i and $_ !~ / C100 /  ) {
        $id=sprintf("%d",$columns[$colnum+7]);
        if ( $columns[$colnum]==0 ){
          print LOG "$node Found NCQ=0 ID=".$id."\n";
          if ( index($nodedisks{$node},$id) lt 0 ) {
            $nodedisks{$node}=$nodedisks{$node}." ".$id;
            $nodedrivecount++;
          }
        }
      }
    }
    print LOG "LAST NODE.  Last node had $nodedrivecount disks with NCQ=0\n";
    $drivecount=$drivecount + $nodedrivecount;
    @disks{keys %nodedisks}= values %nodedisks;
    if (%disks) {
      foreach $key (sort (keys(%disks))) {
        printboth("ERROR:  Node $key Service Tag:$svctags{$key} NCQ=0 For Disk ID's: $disks{$key}\n") if ($_[0] ne "q");
      }
      printboth("ERROR:  NCQ is zero on $drivecount drives\n\n") if ($_[0] ne "q");
      printboth("RESOLUTION:  See KB92871.  Drives were identified to have performance issues.  Contact application engineering.\n\n");
      print LOG "CHECKNCQ FAILED\n";
      $failed="yes";
      msg("Hitachi Disk NCQ","FAILED");
    } else {
        if ($sawvendor==0) {
          printboth("ERROR:  exportlog does not appear to contain disk drive Vendor information\n\n");
          $failed="yes";
          msg("Hitachi Disk NCQ","FAILED");
        } else {
#         printboth("PASSED NCQ.  All drives found have NCQ\n") if ($_[0] ne "q");
          print LOG "CHECKNCQ PASSED\n";
          msg("Hitachi Disk NCQ","PASSED");
        }
    }
}
########## End checkncq ##########

########## Start sitename ##########
# ETA KB92858
sub sitename {
  print LOG "\n\n\n### ".localtime()." ### Starting sitename\n";

  # only for version 5.0.0 and 5.0.1
  if ($AVAMARVER != /^5\.0\.[01]/)  { 
    print LOG "Check not applicable to version $AVAMARVER\n";
    return;
  }

  $curr_site_name=decode_entities(`grep site_name /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml`);
  chomp($curr_site_name);
  $curr_site_name =~ s/.*value="//;
  $curr_site_name =~ s/" .>//;
  chomp($curr_site_name);
  if (length($curr_site_name)<=32) {
    print LOG "\nCurrent ConnectEMC Name '$curr_site_name' is less than 32 characters\n";
    msg("ConnectEMC Name Length","PASSED");
  } else {
    printboth("ERROR:  ConnectEMC Sitename is more than 32 characters: $curr_site_name\n");
    printboth("RESOLUTION: Stop MCS: mcserver.sh --stop\n            As root run /usr/local/avamar/bin/avsetup_connectemc.pl --site_name=\"shorter name\"\n            Start MCS:  mcserver.sh --start\nSee ETA KB92858 for more info\n\n");
    msg("Bug 19066 ConnectEMC Name Length","FAILED");
  }
}
########## End sitename ##########

########## Start checketh #########
sub checketh {
  print LOG "\n\n\n### ".localtime()." ### Starting checketh\n";
  nodexref() if (!$NODE_COUNT);
  my ($speed,$eth,$duplex,$node,$link,$autoneg,$err,$warn) = "";

  $cmd=q[ ls /etc/sysconfig/network/ifcfg-*.* 2>/dev/null | sed -e 's/^/IFCFG:/' ;   
          ls /etc/sysconfig/network-scripts/ifcfg-*.* 2>/dev/null | sed -e 's/^/IFCFG:/' ;   
          ifconfig | grep -v "^ \|^$\|^lo" | awk '{system("ethtool "$1)}' ] ;

  my $iferr="";
  mapall($ALL." --user=root",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    if ( !/bond\d+\.\d+/ and /^IFCFG:(.*)/ ) {
      $iferr.="WARNING: Node $node has extra interface config file $1\n";
      next;
    }
    if ( $_ =~ /^Settings /) {
       ($foo,$foo,$eth)=split(' ');
       $eth =~ s/://;
    }
    if ( $_ =~ /Speed: (\d+)M/ ) { $speed=$1; $speed =~ s/ //g; }
    if ( $_ =~ /Duplex:/) { ($foo,$duplex)=split(":"); $duplex=~ s/ //g;  }
    if ( $_ =~ /Auto-negotiation:/) { ($foo,$autoneg)=split(":"); $autoneg=~ s/ //g; }

    if ( $_ =~ /Link detected: (\w+)/ ) {
      print LOG "---> Node $node port $eth speed $speed duplex $duplex link $1 autoneg $autoneg\n";
      if ($1 eq "yes" and $eth =~ /eth/ ) {
        if ($speed < 1000) {
          if ($NODE_COUNT eq 1 and $speed == 100 ) {
            if (!$PREUPGRADE){ 
              printboth("WARNING:  $node $eth speed is $speed instead of at least 1000Mb/s\n");
              printboth("RESOLUTION:  100Mb/s is allowed on single node but at least 1000Mb/s is recommended\n");
              $warn="yes";
            }
          } else {
            printboth("ERROR:  $node $eth speed is $speed instead of at least 1000Mb/s\n");
            $err="yes";
          }
        }
        if ($duplex ne "Full") {
          printboth("ERROR:  $node $eth duplex is $duplex instead of Full\n");
          $err="yes";
        }
        if ($autoneg ne "on" and $speed < 10000 ) {
          printboth("ERROR:  $node $eth auto negotiation is $autoneg instead of on\n");
          $err="yes";
        }
        ($speed,$autoneg,$duplex,$link)="";
      }
    }
  }
  if ($warn eq "yes") {
    msg("Ethernet Speed Settings","WARNING");
  }
  if ($err eq "yes") {
    printboth("RESOLUTION:  See KB115366 for troubleshooting NIC cards and speeds\n\n");
    msg("Ethernet Settings","FAILED");
  } else {
    msg("Ethernet Settings","PASSED");
  }
  if ($iferr) {
    printboth("${iferr}RESOLUTION:  Extra config files may cause node to not reboot.  Make sure these files are required or rename them before rebooting\n\n");
    msg("Network Interface Config","WARNING");
  }
}
########## End checketh #########

########## Start status_dpn ######
sub status_dpn {
  print LOG "\n\n\n### ".localtime()." ### Starting status_dpn\n";
  my $e="";
  my $sw=""; #sched warn
  open(CMD_PIPE,"status.dpn|");
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if ($_ =~ /^(0\.[0-9A-Z]+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/ ){
      #print "Node $1  IP $2  ver $3  State $4  mode $5 flags $6  dis $7 susp $8 load $9 \n";
      if ($4 ne "ONLINE") {printboth ("ERROR:  Node $1 State is $4 but should be ONLINE\n");$e=1}
      if ($5 ne "fullaccess") {printboth ("ERROR:  Node $1 Runlevel is $5 but should be fullaccess\n");$e=1}
      if ($8 ne "false") {printboth ("ERROR:  Node $1 Suspend is $8 but should be false.  See KB172603\n");$e=1}
    }
    if ($_ =~ /System-Status: (\w+)/) {
      if ($1 ne "ok") {printboth ("ERROR:  System-Status is $1 but should be ok\n");$e=1}
    }
    if (/Access-Status: (\w+)/) {
      my $status=$1;
      if ($status ne "full") {
        getconfiginfo() if (!$GOTCONFIGINFO);
        if ($MAINT_RUNNING) {
          printboth ("WARNING:  Access-Status is $status because $MAINT_RUNNING is running. Skipping some checks\n")
        } else {
          printboth ("ERROR:  Access-Status is $status but should be full\n");
          $e=1;
        }
      }
    }
    if (/WARNING:/) {
      $sw="RESOLUTION: See KB126450 for troubleshooting maintenance scheduler problems.\n\n" if (!sw);
      $sw="ERROR: $_\n$sw";
    }
  }
  if ($e or $sw) {
    printboth($sw) if ($sw);
    printboth("RESOLUTION: Fix problems identified\n\n") if $e;
    msg("Status.dpn","FAILED");
  } else {
    msg("Status.dpn","PASSED");
  }
}
########## End status_dpn ######

########## Start auditd ######
sub auditd {
  print LOG "\n\n\n### ".localtime()." ### Starting auditd\n";

  my $e="";
  if ( $OS !~ /suse/ ) {
    print LOG "Skipping check for O/S $OS only check for suse\n";
    return;
  }
  $cmd=q[ /etc/init.d/auditd status ] ;
  my $nodes=getnodes_os("suse");
  if (!$nodes) {
    print LOG "no suse nodes found\n";
    return;
  }
  mapall("--user=root --nodes=$nodes ",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    next if ($NODE_INFO{$node}{os} !~ /suse/);
    if ($_ =~ /running/ ) {
      printboth("ERROR:  Node $node auditd is running but should be disabled\n");
      $e="yes";
    }
  }
  if ($e) {
    printboth("RESOLUTION: Review KB121691 for manual instructions or bug 28937 to get the hot fix package\n");
    printboth("            See TSE T080311RO in the Avamar Procedure Generator\n\n");
    msg("Bug 28937 auditd offline nodes","FAILED");
  } else {
    msg("Bug 28937 auditd offline nodes","PASSED");
  }
}

########## End auditd ######

########## Start checkascd ######
sub checkascd {
  print LOG "\n\n\n### ".localtime()." ### Starting checkascd\n";

  my $tabfile="";
  $cmd=q[ avmaint datacenterlist --debug 2>&1 ];
  open(CMD_PIPE,$cmd."|");
  while(<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if (/tabfilename = (.*)/) {
      $tabfile=$1 if (/tabfilename = (.*)/);
      print LOG "Moved $1 to /tmp\n";
    }
    if (/Loaded dispatcher table/) {
      move($tabfile,"/tmp/$1");
      print LOG "Moved $1 to /tmp\n";
    }
  }
  $cmd=q[ avmaint datacenterlist --debug 2>&1 ];
  open(CMD_PIPE,$cmd."|");
  while(<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if ($_ =~ /cannot connect to server/ ) {
      printboth("ERROR:  ascd is not responding\n");
      printboth("RESOLUTION: Check the default log at /usr/local/avamar/var/ascd-27000.log\n\n");
      msg("ascd status","FAILED");
      return;
    }
  }
  msg("ascd status","PASSED");
}
########### End checkascd ######

########## Start noderestart ######
sub noderestart {
  print LOG "\n\n\n### ".localtime()." ### Starting noderestart\n";

  if (!grep $_ eq $AVAMARVER, (@v3x,@v4x,@v5x)){
    print LOG "Skipping check for version $AVAMARVER\n";
    return;
  }
  my $e="";
  $cmd=q[ grep "<0017>" /data01/cur/err.log | tail -1 ] ;
  mapall("",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while(<CMD_PIPE>) { chomp;
    $node=$1 if (/(\(0\..*\)) ssh/);
    print LOG "$_\n";
    if (/(\d\d\d\d)\/(\d\d)\/(\d\d)-(\d\d):(\d\d):/) {
      my ($yy,$mm,$dd,$hr,$mn)=($1,$2,$3);
      $gmt = timegm(0,$min,$hr,$dd,$mm-1,$yy);
      print LOG "GMT=$gmt\n";
      if ( abs($lastgmt-$gmt)>600 and $lastgmt ) {
        printboth("ERROR:  Node $node started individually\n");
        $e="yes";
      }
      $lastgmt=$gmt;
    }
  }
  if ($e) {
    printboth("RESOLUTION: Restart GSAN\n\n");
    msg("Node Restarted","FAILED");
  } else {
    msg("Node Restarted","PASSED");
  }
}
########### End noderestart ######

########### Start checkpointxmlperms ######
sub checkpointxmlperms {

  print LOG "\n\n\n### ".localtime()." ### Starting checkpointxmlperms\n";

  if (grep $_ eq $AVAMARVER, (@v3x,@v4x)  ) {
    print LOG "Check not applicable to version $AVAMARVER\n";
    return;
  }
  if (! -e "/usr/local/avamar/var/checkpoints.xml" ) {
    print LOG "Check skipped.  File not found\n"; 
    return;
  }
  my $e="";
  $results=`ls -al /usr/local/avamar/var/checkpoints.xml`;
  print LOG $results;
  chomp($results);
  my ($perms,$foo1,$owner,$group,$foo2)=split(" ",$results);
  print LOG "perms=$perms owner=$owner group=$group\n";
  if ($perms !~ /-r..r..r../ ) {
    printboth("ERROR:  Permissions should be -rw-rw-r-- but is $perms for checkpoints.xml\n");
    $e="yes";
  }
  if ($owner ne "admin") {
    printboth("ERROR:  Owner should be admin but is $owner for checkpoints.xml\n");
    $e="yes";
  }
  if ($group ne "admin"){
    printboth("ERROR:  Group should be admin but is $group for checkpoints.xml\n");
    $e="yes";
  }
  if ($e) {
    printboth("RESOLUTION: Fix permissions, owner or group for /usr/local/avamar/var/checkpoints.xml\n\n");
    msg("Checkpoint.xml Perms","FAILED");
  } else {
    msg("Checkpoint.xml Perms","PASSED");
  }
}
########### End checkpointxmlperms ######

########## Start duplicateip ######
sub duplicateip {
  print LOG "\n\n\n### ".localtime()." ### Starting duplicateip\n";

  nodexref() if (!$NODE_COUNT);
  if ($NODE_COUNT eq 1) {
    print LOG "Check skipped for single node servers\n";
  }
  ($e,$ipaddr,$errors,$iface,$ifmac)="";
  $cmd=q[ /sbin/ifconfig ] ;
  mapall("",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while(<CMD_PIPE>) { chomp;
    push(@ifconfig,$_);
  }
  foreach (@ifconfig) {
    if (/(\(0\..*\)) ssh/) {
      $node=$1;
      $iface="";
      print LOG "\n\n";
    }
    print LOG $_ ."\n" if ($_);
    if (/(.*)\s*Link encap/) {
      $iface=$1;
      ($rx,$ipaddr,$errors,$ifmac)="";
    }
    $rx=$1 if (/RX bytes:(\d*) /);
    $ipaddr=$1 if (/inet addr:(\d+\.\d+\.\d+\.\d+) /);
    $errors=$1 if (/errors:(\d*)/ and $errors==0);
    $ifmac=$1 if (/HWaddr (.*)/);
    if ( $_ eq "" ) {
      $iface =~ s/ //g;
      print LOG "--> Node $node IF=$iface IP=$ipaddr MAC=$ifmac ERR=$errors RX=$rx\n";
      if ($iface and $ipaddr and $rx>0 and $iface =~ /bond0|eth0/ ) {
# 4/1/13 KRM removed info about errors. No help, causing confusion
#       if ($errors) {
#         printboth("ERROR:  network errors seen on node $node, $iface\n");
#       }
        if ($iface =~ /bond/) {
          mapall("--user=root --nodes=0.s","arping -I $iface -c3 $ipaddr");
        } else {
          mapall("--user=root --nodes=0.s","arping -c3 $ipaddr");
        }
        open(CMD_PIPE2,$TMPFILE);
        my $last="";
        while (<CMD_PIPE2>) { chomp;
          print LOG "$_\n";
          if (/^Unicast .*\[(.*)\]/) {
            my $mac=$1;
            if ($last ne $mac and $last) {
              $e="yes";
              printboth("ERROR:  Duplicate IP Address $iface $ipaddr MAC=$mac MAC=$last\n");
              ($errors,$ipaddr,$iface,$ifmac)="";
            }
            $last=$mac;
          }
        }
      } else {
        print LOG "SKIPPING: empty iface, ipaddr, RX bytes=0 or iface<>eth0 or bond0\n\n";
      }
    }
  }
  if ($e) {
    printboth("RESOLUTION: Find duplicate IP addresses and fix. Try 'arping -c3 <ip>'\n\n");
    msg("Duplicate IP","FAILED");
  } else {
    msg("Duplicate IP","PASSED");
  }
}
########## End duplicateip ######

########## Start bondconf ######
sub bondconf {
  print LOG "\n\n\n### ".localtime()." ### Starting bondconf\n";

  my $e="";
  $cmd=qq[ grep "^Bonding Mode:" /proc/net/bonding/bond* ];
  mapall($ALL,$cmd);
  open(CMD_PIPE,$TMPFILE);
  while(<CMD_PIPE>) { chomp;
    $node=$1 if (/(\(0\..*\)) ssh/);
    print LOG "$_\n";
    if (/Bonding Mode:/ and !/active-backup/) {
      printboth("WARNING: Node $node bonding setup is wrong if in a high availability configuration (HA)\n       $_\n");
      $e="yes";
    }
  }
  if ($e) {
    if ($NODETYPE =~ /gen4/i) { 
      printboth("RESOLUTION: Configure bonding to be active-passive if grid is setup for high availability (HA). See KB95492 for Gen4.\n\n");
    }
    if ($NODETYPE =~ /gen3/i) {
      printboth("RESOLUTION: Configure bonding to be active-passive if grid is setup for high availability (HA). See tech note 300-011-174-DualSwtch.pdf or KB163973 for Gen3\n\n");
    }
    msg("Bonding Configuration","WARNING");
  } else {
    msg("Bonding Configuration","PASSED");
  }
}
########## End bondconf ######


########## Start hfschecktime ##########
sub hfschecktime {
  print LOG "\n\n\n### ".localtime()." ### Starting hfschecktime\n";

  if (!$MCDBOPEN) {
    printboth("WARNING:  Unable to open MCS database\n\n");
    msg("HFSCheck run time","WARNING");
    return;
  }
  my $e="";
  my ($sec, $mn, $hr, $dd, $mm, $yy) = (localtime(time - 86400*7))[0,1,2,3,4,5,6];
  $mm++; $yy+=1900;
  my $date=sprintf("%4d-%02d-%02d",$yy,$mm,$dd);
  my $sql = qq[
    select date,time,code
    from v_events
    where date>= '$date'
    and (code=4002 or code=4003)
    order by date,time
  ];

  my $sth = $dbh->prepare($sql);
  $sth->execute;

  my $starthfs="";
  while ( @row = $sth->fetchrow_array() ) {
    my ($date,$time,$code)=@row;
    my $epoch = sched_toepoch($date,$time);
    print LOG "$date $time $code $epoch\n";
    if ($code eq "4002" ) { $starthfs=$epoch; }
    if ($code eq "4003" and $starthfs) {
      $diff=$epoch-$starthfs;
      print LOG "diff=$diff\n";
      if ($diff > (7*3600)) {
        $diffhr=int($diff/3600);
        printboth("WARNING:  HFSCheck took longer than $diffhr hours on $date\n");
        $e="yes";
      }
    }
  }
  if ($e) {
    printboth("RESOLUTION: Look for overlap, modified=2 settings, hardware issues\n\n");
    msg("HFSCheck run time","FAILED");
  } else {
    msg("HFSCheck run time","PASSED");
  }

}
########## End hfschecktime ##########

########## Start omchassis ##########
sub omchassis {
  print LOG "\n\n\n### ".localtime()." ### Starting omchassis\n";
  gethardware() if (!$MANUFACTURER);
  if ($MANUFACTURER !~ /dell/) {
    print LOG "Check not applicable to manufacturer $MANUFACTURER\n";
    return;
  }
  checkostools() if (!$RAN_OMREPORT);
  if (!$OMREPORT) {
    printboth("WARNING: Dell Hardware not checked. 'omreport' not installed\n\n");
    msg("Dell Hardware Status","WARNING");
    return;
  }
  if ($PREUPGRADE) { 
    $cmd=q[ omreport chassis memory; omreport chassis processors ];
  } else {
    $cmd=q[ omreport chassis; omreport chassis memory; omreport chassis processors; omreport chassis pwrsupplies; 
          omreport chassis temps; omreport chassis volts; omreport chassis batteries ];
  }
  my $nodes=getnodes_hw("dell");
  if (!$nodes) {
    print LOG "no dell nodes found\n";
    return;
  }
 mapall("--nodes=$nodes --user=root",$cmd);
 open(CMD_PIPE,$TMPFILE);
  my ($e,$index,%details)="";
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);

    if (/Main System Chassis|^Memory Information|^Processors Information|^Power Supplies Information|^Temperature Probes Information|^Voltage Probes Information|^Batteries|^Details of Memory Array|^Total of Memory Array/) {
      $section=$_;
      $index="";
      undef %details;
      $meminstalled="";
    }
    my ($item,$value)=split(":");
    $item =~ s/^ *| *$//g;
    $details{$item}=$value;
    if ($section eq "Main System Chassis") {
      if (/(\S*)\s*:\s*(.*)/){
        my ($status,$component)=($1,$2);
        print LOG "--> $node $component status is $status\n";
        if ($status !~ /Ok|Learning/ and $component ne "COMPONENT") {
          printboth("ERROR:  Node $node $component status is $status\n");
          $e="yes";
        }
      }
    } else {
     if (!$_ and $index gt "" and $section){
      if (($section =~ /Details of Memory Array/ and $details{"Type"} =~ /Not Occupied/)
        or ($section=~/Processors Information/ and $details{"Processor Brand"}=~/Not Occupied/)
        or ($section=~/Voltage Probes/ and $details{"Status"}=~/Unknown/)
        or ( $details{"Status"} =~ /Ok/i ) ) {
        print LOG "---> $section Index $index passed\n";
      } else {
        printboth("ERROR:  Node $node $section Index $index Health is ".$details{Status}."\n");
        $e="yes";
      }
     }
     if ($section =~ /Total of Memory Array/) {
       if ($item=="Value") {
         if ($lastmem =~ /Total Installed Capacity/ and $lastmem !~ /Available/ ) {
           ($meminstalled,$foo)=split(" ",$value);
           print LOG "Meminstalled=$meminstalled\n";
         }
         if ($lastmem =~ /Total Installed Capacity Available to the OS/) {
           ($available,$foo)=split(" ",$value);
           if ($meminstalled - $available >1023 ) {
             printboth("ERROR: Node $node Memory installed is $meminstalled but only $value is available to the O/S\n");
             $e="yes";
           }
         }
       }
       $lastmem=$value
     }
    }
    $index="$1" if (/Index\s*:\s*(.*)/); 
    $index=~ s/ //g;
  }


  if ($e) {
    printboth("RESOLUTION: Resolve hardware errors detected\n\n");
    msg("Dell Hardware Status","FAILED");
  } else {
    msg("Dell Hardware Status","PASSED");
  }
}
########## End omchassis ##########

########## Start shownotes ##########
sub shownotes {
  my $notefile="notes-proactive_check.pl";
  if ( -e $notefile) {
    open(NOTES,$notefile);
    while (<NOTES>) {
      next if (/\*\*\* PLEASE FOLLOW|mumbledy/);
      print $_;
      printboth("$_");
    }
    printboth("\n");
  }
}
########## End shownotes ##########

########## Start check_script_version ##########
sub check_script_version {

  print LOG "\n\n\n### ".localtime()." ### Starting check_script_version\n";
  print "\n$PROG $PROGVER (".localtime().")\n\n" if(!$LOGOFF);
  if ($DARKSITE) {
    open(FH,">/home/admin/.noftp");
    print FH $logdate."\n";
    close(FH);
    open(FH,">/home/admin/.darksite");
    print FH $logdate."\n";
    close(FH);
  }
  if (-e "/home/admin/.noftp") {
    printboth("ERROR:  FTP not allowed at this site.\n");
    printboth("RESOLUTION:  If FTP is allowed use --update to turn check back on\n\n");
    msg("Latest script version","DISABLED");
    return;
  }
  print "Checking Script Version...";
  if ($PROGVER eq "NNN"){
    printboth("WARNING: TEST MODE.  NO VERSION CHECK\n");
    msg("Latest script version","FAILED");
    return;
  }
  my $port;
  if ($VERSNUM >=710){
    # enable FTP
    print LOG "Enable ftp\n";
    system("sudo /usr/local/avamar/lib/admin/security/ftp_service &");
    my $results=qx{sudo iptables -L | grep -P 'anywhere.*anywhere.*:ftp'};
    print LOG "Results: $results\n";
    if (!$results){
      printboth("WARNING:  Automatic opening of temporary outbound FTP connections appears to have failed. Trying FTP anyway\n");
      printboth("RESOLUTION:  Review Solve-desktop procedures to manually open firewall.\n\n");
    }
    $port="-P `hostname -i`:35000-35010";
  } else { 
    $port="-P -";
  }
  my $curlflags=qq[ --disable-eprt $port --connect-timeout 30 -v --user avamar_ftp:anonymous ]; 
  my $curlcmd=qq[curl $curlflags ftp://ftp.emc.com/software/scripts/proactive_check.version 2>&1 ];
  print LOG "curlcmd: $curlcmd\n";
  $results=qx{$curlcmd/proactive_check.version 2>&1};
  print LOG "Result: $results\n";
  if ($results !~ /PROGVER\s*=\s*"Version (\d*\.\d*)"/) {
    print "FAILED.\n$results\n\nDoes this site allow FTP? ";
    chomp($input = <STDIN>);
    print LOG "--> FTP Allowed input = '$input'\n";
    print "\n";
    if ($input =~ /^n/i) {
      open( my $FH,">/home/admin/.noftp");
      print $FH $logdate."\n";
      close($FH);
      msg("Latest script version","DISABLED");
    } else {
      printboth("Update check skipped due to temporary network errors\n");
      msg("Latest script version","SKIPPED");
    }
  } else {
    $NEWEST=$1;
    if ($NEWEST ne $PROGVER) {
      my $curlcmd=qq[curl $curlflags -O ftp://ftp.emc.com/software/scripts/proactive_check.pl 2>&1 ];
      printboth("ERROR:  Newest version is $NEWEST.  Running $PROGVER.\n");
      printboth("RESOLUTION: Get most recent version.  Run this command\n   $curlcmd\n");
      print "\nERROR:  Newest version is $NEWEST.  Do you want to update now? ";
      chomp($input = <STDIN>);
      print LOG "--> Continue input = '$input'\n";
      if ($input =~ /^y/i) {
        if(!copy("proactive_check.pl", "x-proactive_check.pl")) {
          printboth("ERROR: Unable to backup file: $!\n");
          exit 0;
        }
        print LOG "download:", qx{$curlcmd};
        print LOG "newcmd: ./proactive_check.pl".join(" ",@ARGV)."\n";
        exec "./proactive_check.pl ".join(" ",@ARGV);
      } else {
        printboth("WARNING:  Newer script version available.");
        msg("Latest script version","WARNING");
      }
    } else {
      print "OK\n";
      printboth("Passed\n");
      msg("Latest script version","PASSED");
    }
  }
}
########## End check_script_version ##########

########## Start rptsecupdvers ##########
sub rptsecupdvers  {
  print LOG "\n\n\n### ".localtime()." ### Starting rptsecupdvers\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  my $secupds;
  my $lastitem="x";
  my ($msg,$e)=("")x2;
  for my $node (sort @NODES) {
    my $physnode=$NODE_LXREF{$node};
    my ($line)=grep(/^\($physnode\)/,@DATA_SECUPD);
    my ($nodeid,$item)=split(/\s/,$line);
    print LOG "phys:$physnode logic:$node line:$line\n";
    $item="" if ($line =~ /fatal:/);
    $msg.="   Node $node $item\n";
    $e="yes" if ($item ne $lastitem and $lastitem ne "x") ;
    $lastitem=$item;
  }
  if ($e) {
    printboth("WARNING:  Mismatch of Security Updates installed\n$msg");
    printboth("RESOLUTION:  Review versions of security updates on each node.  They are not required to match but usually do\n\n") ;
    msg("Security Updates","WARNING");
    return;
  }
  $lastitem="NONE FOUND" if ($lastitem eq "x" or !$lastitem);
  msg("Security Updates",$lastitem) ;
}
########## End rptsecupdvers ##########

########## Begin lasthfs ##########
# Check for hfs in past $1 hours
sub lasthfs {
  print LOG "\n\n\n### ".localtime()." ### Starting lasthfs\n";
  if ($NODETYPE =~ /AER/) {
    print LOG "Skipping: $NODETYPE node\n";
    return;
  }
  my $xml = new XML::Parser( Style => 'Tree' );
  my $tree=$xml->parsefile("avmaint lscp|") ;
  SimpleXMLTree($tree);
  my %lscp=%xmltree;

  my ($lastcp,$lasthfs)=(0)x2;
  for (sort keys %xmltree ) {
    next if (!m{/tag});
    my $key="/checkpointlist/checkpoint/$lscp{$_}";
    $lastcp=$lscp{"$key/cpctime"} if ( (!$lastcp or $lastcp<$lscp{"$key/cpctime"}) and $lscp{"$key/isvalid"} eq "true");
    $lasthfs=$lscp{"$key/hfscheck/starttime"} if ( (!$lasthfs or $lasthfs<$lscp{"$key/hfscheck/starttime"}) and $lscp{"$key/hfscheck/validcheck"} eq "true");
    print LOG qq[CP: $key $lscp{"$key/cpctime"}\n];
    print LOG qq[HFS: $key $lscp{"$key/hfscheck/starttime"}\n];
  }

  print LOG "Last HFS $lasthfs\nLast CP  $lastcp\nCur Time  ".time."\n";

  if ( time - $lasthfs > 36 * 3600 ) {
    printboth("ERROR: No HFSCheck in past $hfs_age hours. Last one is ".localtime($lasthfs)."\n");
    printboth("RESOLUTION:  See KB127269 for hfscheck failure troubleshooting.\n\n");
    msg("HFSCheck in past 36 hours","FAILED");
  } else {
    my $info=($PREUPGRADE) ? "(".localtime($lasthfs).")" : "";
    msg("HFSCheck in past 36 hours","PASSED",$info);
    print LOG "LASTHFS PASSED\n";
  }
# Check last CP TIME
  if ( time - $lastcp > 24 * 3600 ) {
    printboth("ERROR: No Checkpoint in past 24 hours.  Last one is ".localtime($lastcp) ."\n");
    printboth("RESOLUTION:  Investigate logs for reason or may be due to grid just restarting\n\n");
    msg("Checkpoint Status","FAILED");
  } else {
    my $info=($PREUPGRADE) ? "(".localtime($lastcp).")" : "";
    msg("Checkpoint Status","PASSED",$info);
  }

# Check that last HFS failure is cleared
  openmcdb() if (!$dbh);
  my $sql = qq[ select resetcode,checkpoint from v_hfscheck_failures where alert=true order by hfscheck_failure_id desc limit 1 ];
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  my ($resetcode,$checkpoint)=$sth->fetchrow_hashref();
  print LOG "hfscheckfailure cp:$checkpoint resetcode:$resetcode\n";
  if (!$resetcode  and $checkpoint) {
    printboth("ERROR:  Event 22426 Data Integrity Alert for a failed HFSCheck has not been cleared\n");
    printboth("RESOLUTION:  See KB 94297 for information to clear the failure\n\n");
    msg("Data Integrity Alert","FAILED");
  }
}
########## End lasthfs ##########

########### Start fileperms ######
sub fileperms {
  print LOG "\n\n\n### ".localtime()." ### Starting fileperms\n";
  my ($e,$fs)="" ;
  $cmd=q[ test ! -s /var/log/messages && echo "ZEROSIZE:" ;ls -al /var/log/messages ];
  mapall("--all --user=root",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    if (/^ZEROSIZE:/) {
      printboth("ERROR:  Nodes $node File size of /var/log/messages is 0.\n");
      $fs="yes";
    }
    next if ( $_ !~ /messages$/) ;
    my ($perms,$foo1,$owner,$group,$foo2)=split(" ");
    print LOG "perms=$perms owner=$owner group=$group\n";
    if ($perms !~ /-rw.r...../) {
      printboth("ERROR:  Permissions should be -rw-r.-r-- but is $perms.  See KB160412 and bug 21573\n");
      $e="yes";
    }
    if ($owner ne "root") {
      printboth("ERROR:  Owner should be root but is $owner.\n");
      $e="yes";
    }
    if ($group ne "root" and $group ne "admin" ){
      printboth("ERROR:  Group should be root but is $group.\n");
      $e="yes";
    }
  }
  my $flushe=0;
  $cmd=qq[ find /usr/local/avamar/var/mc/server_data ! \\( \\( -user admin -perm -u=r \\) -o \\( -group admin -perm -g=r \\) -o \\( ! \\( -user admin -o -group admin \\) -perm -o=r \\) \\) ]; 
  open(my $fh,"$cmd|");
  while(<$fh>) {chomp;
    print LOG "$_\n";
    printboth("ERROR:  File $_ is not readable by admin and will cause flush failures\n");
    $flushe=1;
  }
  if ($e or $fs or $flushe) {
    printboth("RESOLUTION: Change permissions or move files.  See KB 172578 for more information.\n\n") if $flushe;
    printboth("RESOLUTION: For 0 byte files restart syslogd and make sure events get logged to /var/log/messages\n") if ($fs) ;
    printboth("RESOLUTION: Fix permissions, owner or group for /var/log/messages.  See KB160412\n\n") if ($e);
    msg("File Permissions","FAILED");
  } else {
    msg("File Permissions","PASSED");
  }
}
########### End fileperms ######

########### Start license ######
sub license {
  print LOG "\n\n\n### ".localtime()." ### Starting license\n";
  if ($VBA) {
    print LOG "Skipping for VBA\n";
    return;
  }
  my $e="";
  if ( -e "/usr/local/avamar/etc/license.xml") {
    open(FILE,"/usr/local/avamar/etc/license.xml");
    while(<FILE>) { chomp;
      if (/expires="(.*)"/) {
        if ($1 < time and $1 > 0 ) {
          printboth("ERROR:  License has expired.\n");
          $e="FAILED";
        } elsif ($1 != 0 ) {
          printboth("WARNING:  License has an expiration date.\n");
          $e="WARNING";
        }
      }
    }
  } else {
    printboth("ERROR:  There is no license file /usr/local/avamar/etc/license.xml\n");
    $e="FAILED";
  }

  if ($e) {
    printboth("RESOLUTION: Fix any license issues.\n\n");
    msg("License",$e);
  } else {
    msg("License","PASSED");
  }
}
########### End license ######

########### Start susereporefresh ######
sub susereporefresh {
  print LOG "\n\n\n### ".localtime()." ### Starting susereporefresh\n";
  getopersys() if (!$OS);
  if ( $OS !~ /suse/ ) {
    print LOG "Skipping check for O/S $OS only check for suse\n";
    return;
  }
  if ($VBA) {
    print LOG "Skipping for VBA\n";
    return;
  }
  my $e="";
  my $cmd=qq[ zypper -x lr
              test -e /etc/cron.d/novell.com-suse_register  && echo "CRON:" || echo "NOCRON:"
              test -e /var/lib/suseRegister/neverRegisterOnBoot  && echo "REG:" || echo "NOREG:"
            ];
  my $nodes=getnodes_os("suse");
  if (!$nodes) {
    print LOG "no suse nodes found\n";
    return;
  }
  mapall("--nodes=$nodes --user=root",$cmd);
  open(CMD_PIPE,$TMPFILE);
  my ($cron,$boot,$sles)=("")x3;
  my $sawsles=0;
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/) {
      $node=$1 ;
      $sawsles=0;
    }
    next if ($NODE_INFO{$node}{os} !~ /suse/);
    $sles.="ERROR:  Node $node SLES repository refresh is enabled!! see $_\n" if (/autorefresh/ and !/autorefresh="0"/ and /SUSE-Linux-Enterprise-Server/i) ;
    $sawsles=1 if (/SUSE-Linux-Enterprise-Server/i) ;
    $cron.="ERROR:  Node $node SLES repository cron is enabled\n" if (/^CRON:/ and $sawsles);
    $boot.="ERROR:  Node $node SLES repository neverRegisterOnBoot file is missing\n" if (/^NOREG:/ and $sawsles);
  }
  if ($sles or $cron or $boot) {
    printboth("$sles$cron${boot}RESOLUTION: See KB121044 for more info to disable repository refresh\n\n");
    msg("SLES Repository refresh","FAILED");
  } else {
    msg("SLES Repository refresh","PASSED");
  }
}
########### End susereporefresh ######

########### Start susekernel ######
sub susekernel {
  print LOG "\n\n\n### ".localtime()." ### Starting susekernel\n";
  getopersys() if (!$OS);
  getconfiginfo() if (!$GOTCONFIGINFO);
  if ( $OS !~ /suse/ ) {
    print LOG "Skipping check for O/S $OS only check for suse\n";
    return;
  }
  my $e208,$exfs=("")x2;
  for $node(sort @NODES) {
    my $kernel=$NODELIST{"/nodestatuslist/nodestatus/$node/version/kernel"} ;
    print LOG "node $node kernel $kernel\n";
    next if ($kernel !~ /suse/i);
    $e208.="ERROR: Node ($node) requires 208 day uptime patch\n" if ($kernel =~ /2.6.32.12-0.7-default/);
    if ($kernel =~ /2.6.32.[123]/) {
      if ($NODE_COUNT == 1 ) {
        $exfs.="INFO: Node ($node) may be affected by XFS kernel bug\n" if ($kernel =~ /2.6.32.[123]/);
      } else {
        $exfs.="INFO: Node ($node) may be affected by XFS kernel bug\n" if ($kernel =~ /2.6.32.[123]/);
      }
    }
  }
  if (!$PREUPGRADE) {
   if ($e208) {
    printboth($e208);
    printboth("RESOLUTION: See KB169312 to install hot fix\n\n");
    msg("SLES 208 days bug","FAILED");
   } else {
    msg("SLES 208 days bug","PASSED");
   }
  }
  if ($exfs) {
    printboth($exfs);
    printboth("RESOLUTION: See KB165857 for more information\n\n");
    msg("SLES XFS Kernel bug","INFO");
  } else {
    msg("SLES XFS Kernel bug","PASSED");
  }
}
########### End susekernel ######

########### Start checkgsanpct ######
sub checkgsanpct {
  print LOG "\n\n\n### ".localtime()." ### Starting checkgsanpct\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  my $e="";
  foreach $key (keys %NODELIST) {
    if ($key =~ /\/percent-full/) {
      print LOG "$key=".$NODELIST{$key} ."\n";
      if ($NODELIST{$key} > 64 ) {
        $e=$NODELIST{$key};
        last;
      }
    }
  }
  if ($e) {
    printboth("ERROR:  GSAN Capacity is $e%.  Upgrading is not recommended\n");
    printboth("RESOLUTION:  Decrease GSAN capacity or add nodes\n\n");
    msg("GSAN Capacity Level","FAILED");
  } else {
    msg("GSAN Capacity Level","PASSED");
  }
}
########### End checkgsanpct ######

########### Start lastemail ######
sub lastemail {
  print LOG "\n\n\n### ".localtime()." ### Starting lastemail\n";
  openmcdb() if (!$dbh);
  my $sql = qq[ select last_email from ev_cus_prof where epid='INIT_EV_HIGH_PRIORITY'; ];
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  my $lastemail = int ( $sth->fetchrow_array() /1000) ;
  my $diff=time-$lastemail;
  print LOG "last email is   $lastemail\n";
  print LOG "current time is ".time ."\n";
  if ( $diff > 14*86400 ) {
    printboth("ERROR:  Last High Priority Events Email Home date is ". int($diff/86400) ." days ago\n");
    printboth("RESOLUTION:  See hotfix 34788.  Already fixed in 6.0.2 or later\n\n");
    msg("Last Emailhome ","FAILED");
  } else {
    msg("Last Emailhome","PASSED");
  }
}
########### End lastemail ######

########### Start suseksv25 ######
sub suseksv25 {
  print LOG "\n\n\n### ".localtime()." ### Starting suseksv25\n";
  getopersys if (!$OS);
  if ($OS !~ /suse/ ) {
    print LOG "Skipped check for o/s $OS\n";
    return;
  }
  my $cmd=qq[ ls /sles11-SP1-64v25 ];
  my $e="";
  my $nodes=getnodes_os("suse");
  if (!$nodes) {
    print LOG "no suse nodes found\n";
    return;
  }
  mapall("--nodes=$nodes ",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    next if ($NODE_INFO{$node}{os} !~ /suse/);
    next if (/No such file/);
    if (/^\/sles11-SP1-64v25/) {
      printboth("ERROR: Node $node has kickstart /sles11-SP1-64v25\n");
      $e="yes";
    }
  }
  if ( $e ) {
    printboth("RESOLUTION:  See the Avamar Procedure Generator for instructions or hot fix bug 35214\n\n");
    msg("Kickstart Version","FAILED");
  } else {
    msg("Kickstart Version","PASSED");
  }
}
########### End suseksv25 ######

########## Start get_errlog ########
sub get_errlog {
  print LOG "\n\n\n### ".localtime()." ### Starting get_errlog\n";
  print("HEALTHCHECK:  Creating hc_errlog.txt\n");
  open(OUTPUT,">hc_errlog.txt");
  my $cmd=qq[ grep -h "ERROR\\|0642. gsan" /data01/cur/err.log* ];
  mapall("",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) {
    if (/(\(0\..*\)) ssh/){
      print OUTPUT "================================================================\n";
      print OUTPUT "NODE: $1\n";
      print OUTPUT "================================================================\n";
    }
    print OUTPUT $_;
  }
}
########## End get_errlog ########

########## Start get_esmlog ########
sub get_esmlog {
  print LOG "\n\n\n### ".localtime()." ### Starting get_esmlog\n";
  print("HEALTHCHECK:  Creating hc_esmlog.txt\n");
  gethardware() if (!$MANUFACTURER);
  if ($MANUFACTURER !~ /dell/) {
    print LOG "Check not applicable to manufacturer $MANUFACTURER\n";
    return;
  }
  my $nodes=getnodes_hw("dell");
  if (!$nodes) {
    print LOG "no dell nodes found\n";
    return;
  }
  open(OUTPUT,">hc_esmlog.csv");
  print OUTPUT "Node,Severity,Code,Date,Category,Description\n";
  %mon2num = qw( jan 1 feb 2 mar 3 apr 4 may 5 jun 6 jul 7 aug 8 sep 9 oct 10 nov 11 dec 12);
  my $cmd=qq[ omreport system esmlog; omreport system alertlog ];
  mapall("--nodes=$nodes ",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) {chomp;
    $node=$1 if (/(\(0\..*\)) ssh/);
    ($foo,$sev)=split(": ") if (/^Severity/);
    ($foo,$code)=split(": ") if (/^ID/);
    ($foo,$date)=split(": ") if(/^Date/);
    ($foo,$cat)=split(": ") if (/^Category/);
    if (/^Description/) {
      my($foo,$desc)=split(": ",$_,2);
      my($day,$month,$dd,$time,$yy)=split(" ",$date);
      my $mm=$mon2num{lc($month)};
      print OUTPUT "$node,$sev,$code,$yy-$mm-$dd $time,$cat,$desc\n";
    }
  }
}
########## End get_errlog ########

########## Start get_maintlogs ########
sub get_maintlogs {
  print LOG "\n\n\n### ".localtime()." ### Starting maintlogs\n";
  print("HEALTHCHECK:  Creating hc_maintlogs.txt\n");
  $result=`dumpmaintlogs --days=30 >hc_maintlogs.txt`;
  $result=`tail -c 1000000 /usr/local/avamar/var/cron/replicate.log > hc_replicate.log`;
}
########## End get_maintlogs ########

########## Start sendemail ########
sub sendemail {
  print LOG "\n\n\n### ".localtime()." ### Starting sendemail\n";

  # Check for dark site
  if (-e "/home/admin/.darksite") {
    print LOG "Skipping: Darksite\n";
    return ;
  }
  if ($VBA) {
    print LOG "Skipping: VBA\n";
    return;
  }

  # See if a HPE is enabled
  openmcdb() if (!$dbh);
  my $sth = $dbh->prepare(qq[ 
     select count(*) 
     from ev_cus_prof 
     where epid in ( 'INIT_EV_HIGH_CONNECTEMC', 'INIT_EV_LOGS_CONNECTEMC', 'INIT_EV_HIGH_PRIORITY') 
       and (connectemc_notify_enabled or email_notify_enabled)
    ]);
  $sth->execute;
  my $hpe_enabled =  $sth->fetchrow_array();
  if ( $hpe_enabled <= 0 ) {
    print LOG "Skipping.  HPE did not find connectemc or email notify = true.  found '$hpe_enabled'\n";
    return;
  }

  my ($subject,$file_contents)=@_;
  $subject="proactive_check: $HOSTNAME" if (!$subject);
  if (!defined($file_contents) ) {
    open FILE, "<hc_results.txt";
    $file_contents = do { local $/; <FILE> };
  }

  my $to = 'emailhome@avamar.com';
  my $boundary = '_BoUnDaRy_';
  my $result=`grep smtpHost /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml`;
  my ($smtpserver,$from,$smtp)="";
  if ($result =~ /value="(.+)"/) { 
    $smtpserver=$1 ; 
  } else { 
    print LOG "No SMTP server found: $result\n";
    return; 
  }
  $result=`grep admin_mail_sender_address /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml`;
  if ($result =~ /value="(.+)"/) { 
    $from=$1; 
  } else { 
    print LOG "No From address: $result\n"; 
    return; 
  }
  $smtp=Net::SMTP->new($smtpserver);
  if (!$smtp) {
    print LOG "Could not establish connection with SMTP server: $smtpserver\n";
    return; 
  }
  $smtp->mail($from);
  $smtp->recipient($to);
  $smtp->data();
  $smtp->datasend("Subject: $subject\n");
  $smtp->datasend("MIME-Version: 1.0\nContent-type: multipart/mixed;\n  boundary=\"$boundary\"\n");
  $smtp->datasend("\n--$boundary\nContent-type: text/plain\n\n");
  $smtp->datasend("$file_contents\n");
  $smtp->datasend("\n--$boundary--\n"); $smtp->dataend();
  $smtp->quit;
  print LOG "Sent from $from to $to using $smtpserver\nsubj: $subject\n"; 
}
########## End sendemail ########

########## Start checkclients ########
sub checkclients {
  getinstalledversion() if (!$VERSNUM);
  print LOG "\n\n\n### ".localtime()." ### Starting checkclients\n";
  if ($ADDNODE) {
     print LOG "Skipping for addnode\n";
     return;
  }

  $sql = qq[ select clients.descr,cl_plugins.pid_number,cl_plugins.version, cl_plugins.build, 
               trunc(cl_plugins.backed_up_ms::double precision/1000::double precision) AS backed_up_epoch,
               clients.cid, clients.client_type
             from clients,cl_plugins
             where clients.cid = cl_plugins.cid
               and clients.enabled = true
           ];
  
  my $sth = $dbh->prepare($sql);
  $sth->execute;

  my $VMPatch="yes" if (grep(/download-AvamarVmImageProxy-linux-ova-6.0.101-901/,@RPMS)) ;
  my $client_upgrade_needed="";
  my $use_vers=($UPGRADE_VERSION) ? $UPGRADE_VERSION : $DATANODEVERSION;
  (my $upgvers=$use_vers) =~ s/^(\d\.\d).*/$1/;
  print LOG "upgrade version=$upgvers\n";

  my ($sqle,$e,$vme,$ndmp30382,$ndmphf,$anyndmp,$anyvmware,$anynetworker);
  while ( @row = $sth->fetchrow_array() ) {
    my($client,$plugin,$major_version,$build,$backedup,$cid,$client_type)=@row;
    next if ($client =~ /MC_DELETED|MC_RETIRED/);
    my $version="$major_version-$build";
    (my $clvers=$major_version) =~  s/^(\d\.\d).*/$1/;
    (my $hotfix=$build) =~ s/.*_HF//;
 
    print LOG "Client: $client $version pid=$plugin lastbu=$backedup clv=$clvers upv=$upgvers";
    my $lastbu=int((time-$backedup)/86400);
    if ($lastbu>365) {
      print LOG "SKIPPING. Last Backup $lastbu days\n";
      next;
    }
    
    # Check Client Versions for 2 versions prior
    if ( ($PREUPGRADE or $CLIENT_VERSION_CHECK) and ($upgvers-$clvers>=2) ) {
      print LOG "clvers=$clvers upgdvers=$upgvers\n";
      $client_upgrade_needed.="ERROR: Client $client version $version needs to be upgraded for $use_vers\n";
    }

    # Client things for Upgrade to 6.1.0 or running 6.1.0
    # Check for SQL client at least 6.1 on version 6.1+
    if ($plugin == 3006 and $major_version lt "6.1" and ($VERSNUM >= 610 or $PREUPGRADE) ) {
      print LOG "SQL->\n";
      $sqle.="ERROR:  SQL Client $client version $version must be upgraded.\n";
    }

    # Skip rest of checks for preupgrade

    # Check NDMP
    if ($plugin =~ /^[178]003$|14003/ ) {
      if ($PREUPGRADE) {
        $anyndmp=1;
        next;
      }
      print LOG "NDMP->";

      if ($version =~ /6\.0\.10[01]/  and $version ne "6.0.101-66_HF34539" ) {
        print LOG "\n";
        $ndmphf.="ERROR: NDMP Client hotfix 34539 required for $client version $version\n";
      }
      if ($version eq "6.1.101-87") {
        $ndmphf.="WARNING: NDMP Client hotfix 49413 available for $client version $version\n";
      }
      if ($version eq "7.1.101-141") {
        print LOG "\n";
        $ndmphf.="WARNING: NDMP Client hotfix 223295 available for $client version $version\n";
      }
      if ($version eq "7.1.101-145") {
        $ndmphf.="WARNING: NDMP Client hotfix 229389 available for $client version $version\n";
      }
      # Any version 5.0.10x 
      if ($version =~ /^5\.0\.10./ and $version !~ /30382/) {
        if ($version eq "5.0.106-28") {
          print LOG "\n";
          $ndmp30382.="WARNING: Client $client is an NDMP accelerator that might need hot fix 30382 installed\n";
        } else {
          print LOG "\n";
          $ndmp30382.="ERROR: Client $client is an NDMP accelerator that needs hot fix 30382 installed\n";
        }
      }
    }

    # VMWare check 
    if ($plugin =~ /^3016$|^1016$/) {
      if ($PREUPGRADE) {
        $anyvmware=1;
        next;
      }
      print LOG "VMProxy->";
      $VMWARE_CLIENT=1;
      if ($client_type eq "VMACHINE") {
        print LOG "Skipping VM machine";
      } else { 
        if (!$VMPatch and $VERSNUM >= 503 and $VERSNUM <= 601) {
          print LOG "\n";
          $vme.="ERROR: Server version $AVAMARVER is affected by VMware bug 35252.\n";
          $VMPatch="err";
        }
        if ($version =~ /^5|^6.0.10[01]/ and $build != 901)   {
          print LOG "\n";
          $vme.="ERROR: VMware client $client version $version is affected by bug 35252.\n";
        }
      }
      if ($VERSNUM>=600 and $VERSNUM<=601 and $DDCNT>=1 and -e "/usr/local/avamar/etc/repl_cron.cfg"){
        
      }
    }

    # Next client check here
    print LOG "\n";
  }

# Print any found problems
  if ( $PREUPGRADE or $CLIENT_VERSION_CHECK) {
   if ($client_upgrade_needed) {
    printboth($client_upgrade_needed);
    printboth("RESOLUTION:  Upgrade clients to a newer version\n\n");
    msg("Client Version Supported","FAILED");
   } else {
    msg("Client Version Supported","PASSED");
   }
  }
#### PREUPGRADE ONLY - note this if block returns
  if ($PREUPGRADE) {
    if ($sqle) {
      printboth($sqle);
      printboth("RESOLUTION:  If upgrading to 6.1.0 or later all SQL clients to be upgraded at the same time\n\n");
      msg("Pre-upgrade Clients","FAILED");
    } else {
      msg("Pre-upgrade Clients","PASSED");
    }
    chomp($anynetworker=`avmgr getb --path=/NETWORKER 2>/dev/null| grep -c "^\[[]"`);
    msg("Pre-Upgrade Clients","Networker Backups Found") if ($anynetworker) ;
    msg("Pre-Upgrade Clients","VMware Backups Found") if ($anyvmware) ;
    msg("Pre-Upgrade Clients","NDMP Backups Found") if ($anyndmp) ;
    return;
  }
#### END OF PREUPGRADE

  if ($sqle) {
    printboth($sqle);
    printboth("RESOLUTION:  All SQL clients on server version 6.1.0 or later must be upgraded\n\n");
    $e="yes";
  }
  if ($vme) {
    printboth($vme);
    printboth("RESOLUTION:  Install hotfix 35252.  See KB92909 for more info\n\n"); 
    $e="yes";
  }
  if ($ndmp30382) {
    printboth($ndmp30382);
    printboth("NOTE:    You may have to manually check the accelerator node to see if the patch has been applied\n");
    printboth("         The md5sum of avndmp will be 11e03fc123141f9216dd92c1a7bcc2e1 if it has been patched\n");
    printboth("RESOLUTION: Install hotfix 30382.\n\n");
    $e="yes";
  }
  if ($ndmphf) {
    printboth($ndmphf);
    printboth("RESOLUTION: See NDMP hot fix for more info\n\n");
    $e="yes";
  }
  if ($e) {
    printboth("NOTE:  The script cannot detect a client upgrade until a backup is done\n\n");
    msg("Mandatory Client Upgrades","FAILED");
  } else {
    msg("Mandatory Client Upgrades","PASSED");
  }
  
  if ($PREUPGRADE and $anynetworker and $UPGRADE_VERSION =~ /7.1.0/ ) {
    printboth("ERROR:  Networker integration is not supported in Avamar 7.1.0\n");
    printboth("RESOLUTION:  Do not upgrade\n");
    msg("Networker Integration","FAILED");
  }
}
########## End checkclients ########

########## Start qadir ########
sub qadir {
  print LOG "\n\n\n### ".localtime()." ### Starting qadir\n";
  my $cmd=qq[ du -s /data0?/QA ]; 
  mapall($ALL,$cmd);
  open(CMD_PIPE,$TMPFILE);
  my $e="";
  while (<CMD_PIPE>) {chomp;
    $node=$1 if (/(\(0\..*\)) ssh/);
    print LOG "$_\n"; 
    if (/^\d/ ) {
      my($tot,$dir)=split();
      $tot=int($tot/1024/1024);
      if ($tot>0) {
        printboth("ERROR: Node $node has $tot GB of QA data in $dir\n");
        $e="yes";
      }
    }
  }
  if ($e) {
    printboth("RESOLUTION:  Remove the leftover QA test directories with the following command\n");
    printboth("             mapall --parallel --bg --user=root --noerror --all+ '/usr/local/avamar/bin/dtsh --cleanup'\n\n");
    msg("QA Directories","FAILED");
  } 
}
########## End qadir ########

########## Start getdatadomain ########
sub getdatadomain {
  print LOG "\n\n\n### ".localtime()." ### Starting getdatadomain\n";
  getinstalledversion() if (!$VERSNUM);
  $DDCNT=0;
  if ($VERSNUM < 600 ) {
    print LOG "Skipping pre v6: $VERSNUM\n";
    $DDRMAINT_VERSION="x";
    return;
  }
  $_=`ddrmaint read-ddr-info 2>/dev/null`;
  print LOG "ddrmaint:\n$_\n";
  if (/.4774./ or !$_ ) { 
    $DDRMAINT_VERSION="x";
    print LOG "No DD Attached: $_\n";
    return;
  }

  $xml = new XML::Parser( Style => 'Tree' );
  print LOG "parsing ddrmaint read-ddr-info\n";
  my $tree=$xml->parse($_); 
  SimpleXMLTree($tree);
  $DDCNT=$xmltree{"/avamar/datadomain/count"};
  %DD=%xmltree;
  foreach (@DD_INDEX) {
    print LOG "ddr index: $_\n";
    my $base="/avamar/datadomain/ddrconfig/$_";
    my $t= $line=$DD{"$base/hostname"} ."  Vers:". $DD{"$base/ddos-version"} ."  S/N:". $DD{"$base/serialno"} ;
    print LOG "$t\n";
    msg("Datadomain",$t);
  }
  chomp($DDRMAINT_VERSION=`ddrmaint --version 2>&1|grep "^[ ]*version:"`);
  $DDRMAINT_VERSION =~ s/.version:\s*//;
  $DDRMAINT_VERSION =~ s/ //;
  print LOG "DDRMAINT_VERSION = $DDRMAINT_VERSION\n";
  return if ($PREUPGRADE);

  my $e="";
  if ($DDRMAINT_VERSION =~ /^6.0.1-66$|^6.0.0/) {
    printboth("ERROR:  Bug 39953 patches not found for data domain ddrmaint version $DDRMAINT_VERSION.  \n");
    printboth("RESOLUTION: See KB92907 but use bug 39953 instead of 33177\n\n");
    $e="yes";
  } 
  if ($DDRMAINT_VERSION =~ /^6.0.2-153$/) {
    printboth("ERROR:  Bug 40855 patches not found for data domain ddrmaint version $DDRMAINT_VERSION.  \n");
    printboth("RESOLUTION: Apply hot fix bug 40855\n\n");
    $e="yes";
  }
  if ($DDRMAINT_VERSION =~ /^6.1.0-402$/) {
    printboth("ERROR:  Bug 40857 patches not found for data domain ddrmaint version $DDRMAINT_VERSION.  \n");
    printboth("RESOLUTION: Apply hot fix bug 40857\n\n");
    $e="yes";
  }
  if ($DDRMAINT_VERSION eq "7.1.1-141" ) {
    printboth("ERROR:  Bug 226000 patches not found for data domain ddrmaint version $DDRMAINT_VERSION.  \n");
    printboth("RESOLUTION: Apply hot fix bug 226000\n\n");
    $e="yes";
  }

  if ($e) {
    msg("Data Domain Patches","FAILED");
  } else {
    msg("Data Domain Patches","PASSED");
  }
}
########## End getdatadomain ########

########## Start ddgcoob ########
sub ddgcoob {
  print LOG "\n\n\n### ".localtime()." ### Starting ddgcoob\n";
  getdatadomain() if (!$DDRMAINT_VERSION) ;
  if (!%DD) {
    print LOG "Skipping, no data domains\n";
    return;
  }
  if ($VERSNUM >=700 ) {
    print LOG "Skipping, version 7+\n";
    return;
  }
  my $e="";
  if (! -e "/usr/local/avamar/bin/gcoob.pl" ) {
    printboth("ERROR:  Datadomain attached but gcoob.pl is not installed\n");
    $e="yes";
  } else {
    $e2="yes";
    mapall("--user=root --nodes=0.s","crontab -l -u admin");
    open(CMD_PIPE,$TMPFILE);
    while(<CMD_PIPE>) {
      next if (/^\s*#/);
      print LOG $_;
      $e2="" if (/gcoob/);
    }
    if ($e2) {
      printboth("ERROR:  Data Domain attached and gcoob.pl installed but not in admin users crontab\n");
      $e="yes";
    }
  }
  if ($e) {
    printboth("RESOLUTION: Install or configured gcoob.pl.  See KB 92933\n\n");
    msg("Data Domain gcoob.pl","FAILED");
  } else {
    msg("Data Domain gcoob.pl","PASSED");
  }
}
########## End ddgcoob ########

########## Start ddvers ########
sub ddvers {
  print LOG "\n\n\n### ".localtime()." ### Starting ddvers\n";
  getdatadomain() if (!$DDRMAINT_VERSION) ;
  if (!%DD) {
    print LOG "Skipping, no data domains\n";
    return;
  }
  if (!$PREUPGRADE and $VERSNUM < 610 ) {
    print LOG " Skipping: Not upgrading, not version 6.1.0 or later\n";
    return;
  }
  my $e=""; my $er="";
  my (%em,%er);
    my $msg=$AVAMARVER;
  foreach (@DD_INDEX) {
    my $base="/avamar/datadomain/ddrconfig/$_";
    $_=$DD{"$base/ddos-version"};
    $vers=$_;
    print LOG "DDOS VERSION = $_\n";
    s/\.//g;
    s/-.*//;
    if ($_ < 5023 and ($AVAMARVER =~ /^6.1/ or $UPGRADE_VERSION =~ /^6.1/) ) {
      $em{61}.="ERROR:  Data Domain ".$DD{"$base/hostname"}." version $vers is not supported on Avamar 6.1\n";
      $er{61}="RESOLUTION: Upgrade Data Domain to version 5.0.2.3 or later if upgrading to Avamar 6.1 \n\n"
    }
    if ( ($AVAMARVER =~ /^7.0/ or $UPGRADE_VERSION =~ /^7.0/)
         and ( $_<5305 or ($_>5400 and $_<5404) ) ) {
      $em{70}.="ERROR:  Data Domain ".$DD{"$base/hostname"}." version $vers is not supported on Avamar 7.0\n";
      $er{70}="RESOLUTION: Upgrade Data Domain to version 5.3.0.5+ or 5.4.0.4+ if upgrading to Avamar 7.0 \n\n"
    }
    if ( ($AVAMARVER =~ /^7.1/ or $UPGRADE_VERSION =~ /^7.1/) 
         and $_ < 5411 ) {
      $em{71}.="ERROR:  Data Domain ".$DD{"$base/hostname"}." version $vers is not supported on Avamar 7.1\n";
      $er{71}="RESOLUTION: Upgrade Data Domain to version 5.4.1.1 or later if upgrading to Avamar 7.1 \n\n"
    }
    if ( ($AVAMARVER =~ /^7.2/ or $UPGRADE_VERSION =~ /^7.2/) 
         and $_ < 5509 ) {
      $em{71}.="ERROR:  Data Domain ".$DD{"$base/hostname"}." version $vers is not supported on Avamar 7.2\n";
      $er{71}="RESOLUTION: Upgrade Data Domain to version 5.5.0.9 or later if upgrading to Avamar 7.2 \n\n"
    }
  }
    for (sort keys %em) {
      printboth($em{$_}.$er{$_}); 
    }
    if (%em) {
      msg("Data Domain Version","FAILED");
    } else {
      msg("Data Domain Version","PASSED");
    }
}
########## End ddvers ########

########## Start adtcheck ########
sub adtcheck {
  print LOG "\n\n\n### ".localtime()." ### Starting adtcheck\n";
  $cmd=qq[ ps -aef |grep -v grep | grep -c AdaGridService ];
  $results=`$cmd`;
  print LOG "cmd: $cmd\nresults: $results\n";
  if ($results < 2 ){
    print LOG "Skiping. No ADT process found\n";
    return;
  }
  if (!$PREUPGRADE and $VERSNUM < 610 ) {
    print LOG " Skipping: Not upgrading, not version 6.1.0 or later\n";
    return;
  }
  my($ADTMD5SUM,$flnm)=split(" ",`md5sum /opt/EMC/TransportSystemService/lib/grid-service.jar`);
  print LOG "ADT grid-server.jar md5sum: $ADTMD5SUM\n";
  if (    $ADTMD5SUM ne 'c1f0eeb7386475c8ef5b8aaf89b27895'
      and $ADTMD5SUM ne '2ae52cadd9957b35ec8c914a46ee9e52') {
    printboth("ERROR: ADT is attached and must be version 1.0 SP3 version or later on Avamar 6.1 or later\n");
    printboth("RESOLUTION: Upgrade ADT before using it on a 6.1 server.\n");
    msg("ADT Check","FAILED");
  } else {
    msg("ADT Check","PASSED");
  }  
}
########## End adtcheck ########

########## Start atocheck ########
sub atocheck {
  print LOG "\n\n\n### ".localtime()." ### Starting atocheck\n";
  if (! -e "/usr/local/avamar/bin/ato" ) {
    print LOG "Skipping: no ato file found\n";
    return 1;
  }
  if ($VBA) {
    print LOG "Skipping: dont check for VBA\n";
    return;
  }
  if (!$PREUPGRADE and $VERSNUM < 610 ) {
    print LOG " Skipping: Not upgrading, not version 6.1.0 or later\n";
    return;
  }
  $_=`grep "^Version=" /usr/local/avamar/bin/ato`;
  chomp;
  print LOG "Version $_\n";
  my($foo,$vers)=split("=");
  $vers =~ s/Version[-=]//;
  my $save=$vers;
  $vers =~ s/[\."]//g;
  if ($vers lt "411") { 
    printboth("ERROR: ATO version $save needs to be upgraded to ADM(e) Version 4.1.1 or later\n");
    printboth("RESOLUTION: ATO must be upgraded before being used but can be done before or after Avamar is upgraded.\n");
    printboth("            For ADM(e) details see https://community.emc.com/docs/DOC-7910\n\n");
    msg("ATO/ADMe Check","FAILED");
  } else {
  msg("ATO/ADMe Check","PASSED");
  }
}
########## End atocheck ########

########## Start chage ########
sub chage {
  print LOG "\n\n\n### ".localtime()." ### Starting chage\n";
  
  my $cmd=qq[ awk '{system("chage -l $1|sed 's/^/$1:/'")}' /etc/passwd ];
  mapall($ALL." --user=root",$cmd);
  open(CMD_PIPE,$TMPFILE);
  my ($e,$lastmax,$lasterr)="";
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/){
      $node=$1;
      ($max,$warn)=0;
    }
    $max=$1 if (/Maximum:\s*(\d+)/);
    $warn=$1 if (/Warning:\s*(\d+)/);
    if ($max and $max != $lastmax and $lastmax) {
      printboth("ERROR:  Node $node Security hardening is different than last node!\n");
      $e="yes";
    }
    if ($max != 99999 and /Password Expires:\s*(.+)/ and !/Never/) {
      $expdt=$1;
      $expjul=`date --date="$expdt" "+%s"` + $warn * 86400 ;
      print LOG "Expjul: $expjul   Time:".time."\n";
      if ($expjul - $warn*86400 <= time) {
        $user=$1 if (/^(\w*):/);
        printboth("ERROR:  Node $node User $user password expiration is $expdt\n");
        $e="yes"; 
      }
    }
  }
  if ($e) {
    printboth("RESOLUTION: Change password before upgrade to reset expiration date\n");
    msg("Password Expiration","FAILED");
    return;
  }
  if ($lastmax != 99999 ) {
    msg("Password Expiration","PASSED");
  }
}
########## End chage ########

########## Start getnodes_hw ##########
sub getnodes_hw {
  print LOG "-> getnodes_hw $_[0]\n";
  gethardware() if (!$MANUFACTURER);
  my $nodelist;
  foreach (keys %NODE_INFO) {
    $nodeid=$1 if /\((.*)\)/;
    print LOG "$nodeid x $NODE_INFO{$_}{manufacturer}\n" if ($DEBUG);
    if ( $NODE_INFO{$_}{manufacturer} =~ /$_[0]/ ) {
      $nodelist.="," if ($nodelist);
      $nodelist.=$nodeid
    }
  }
  print LOG "-> returned: $nodelist\n";
  return $nodelist;
}
########## End getnodes_hw ##########

########## Start getnodes_os ##########
sub getnodes_os {
  print LOG "-> getnodes_os\n";
  nodexref() if (!$NODE_COUNT);
  my $nodelist;
  for ($node=-1; $node<$NODE_COUNT; $node++) {
    next if ($NODE_COUNT==1 and $nodeid<0);
    $nodeid=($node<0) ? "0.s" : sprintf("0.%d",$node);
    print LOG "$nodeid x $NODE_INFO{\"(\".$nodeid.\")\"}{os}\n" if ($DEBUG);
    if ( $NODE_INFO{"(".$nodeid.")"}{os} eq $_[0] ) {
      $nodelist.="," if ($nodelist);
      $nodelist.=$nodeid
    }
  }
  print LOG "-> returned: $nodelist\n";
  return $nodelist;
}
########## End getnodes_os ##########

########## Start replforceaddr ##########
sub replforceaddr {
  print LOG "\n\n\n### ".localtime()." ### Starting replforceaddr\n";
  
  my $e,$e1;
  open(FILE,"avmgr getl --path=/REPLICATE 2>/dev/null|");
  while(<FILE>) {
    next if (!/^2/);
    my($type,$name,$foo)=split();
    printboth("ERROR: Replication may be setup from $name to this grid.\n");
    $e1="yes";
  }
  if ($e1) {
    printboth("RESOLUTION: Manually check the source grid for the --forceaddr flag in /usr/local/avamar/etc/repl_cron.cfg\n");
    printboth("            This flag requires special configuration after upgrading to 6.1. See Esc 5048 for more info\n\n");
  }

  if ( -r "/usr/local/avamar/etc/repl_cron.cfg" ) {
    my $result  = `grep "forceaddr" /usr/local/avamar/etc/repl_cron.cfg|grep -v "^#"`;
    if ($result =~ /forceaddr/ ) {
      printboth("ERROR:  Replication is using the --forceaddr flag which requires special configuration after upgrading to 6.1 and later\n");
      printboth("RESOLUTION: See escalation 5048 before performing an upgrade.\n\n");
      $e="yes";
    }
  }
  if ($e) {
    msg("Replication Force Addr","FAILED");
  } else {
    if ($e1) {
       msg("Replication Force Addr","WARNING");
    } else {
       msg("Replication Force Addr","PASSED");
    }
  }
}
########## End replforceaddr ##########

########## Start vm_dd_bug39571 ##########
sub vm_dd_bug39571 {
  print LOG "\n\n\n### ".localtime()." ### Starting vm_dd_bug39571\n";
  getinstalledversion() if (!$AVAMARVER);
  if ($AVAMARVER ne "6.0.1-66") {
    print LOG "Skipping $AVAMARVER is not 6.0.1-66\n"; 
    return;
  }
  getdatadomain() if (!$DDRMAINT_VERSION);
  checkclients() if (!$CHECK_CLIENTS);
  if (%DD and $VMWARE_CLIENT) {
    printboth("WARNING: VMware and Data Domain detected.\n");
    printboth("RESOLUTION: Consider applying hot fix 39571 if the VMware backups are going to Data Domain.\n\n");
    msg("Replication Force Addr","PASSED");
  }
}
########## End vm_dd_bug39571 ##########

########## Start etcprofile  ##########
sub etcprofile {
 print LOG "\n\n\n### ".localtime()." ### Starting etcprofile\n";
 my $cmd=q[ echo "COUNT: `grep -c '/usr/local/avamar/bin' /etc/profile`" ];
  mapall($ALL,$cmd);
  open(CMD_PIPE,$TMPFILE);
  my ($e)="";
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    if (/COUNT: (.*)/) {
      if ($1 == 0 ) {
      $e="yes";
      printboth("ERROR: Node $node /etc/profile PATH is wrong\n");
      }
    }
  }
  if ($e) {
    printboth("RESOLUTION: See esc5358.  Fix by replacing /etc/profile with /etc/profile.rpmsave\n\n");
    msg("/etc/profile","FAILED");
  } else {
    msg("/etc/profile","PASSED");
  }
}
########## End etcprofile  ##########

########## Start aerplugin  ##########
sub aerplugin {
  print LOG "\n\n\n### ".localtime()." ### Starting aerplugin\n";
  #openmcdb() if (!$dbh);
  #my $sql = qq[ select count(*) from cl_plugins where pid_number = 1024 ];
  #my $sth = $dbh->prepare($sql);
  #$sth->execute;
  #
  #while ( @row = $sth->fetchrow_array() ) {
  #  ($count)=@row;
  #}
  if (-e "/opt/EMC/TransportSystemService/config/GridService.xml") {
    $xml = new XML::Parser( Style => 'Tree' );
    $tree=$xml->parsefile("/opt/EMC/TransportSystemService/config/GridService.xml");
    SimpleXMLTree($tree);
    my $man="";
    for (grep /hostname/i, keys %xmltree) {
      $man.=", " if ($man);
      $man.="$xmltree{$_}";
    }
    msg("Registered Media Access Nodes","DETECTED at $man");
  } else {
    msg("Registered Media Access Nodes","NONE");
  }
  

}

########## End aerplugin  ##########

########## Start stunnelvers  ##########
sub stunnelvers {
  print LOG "\n\n\n### ".localtime()." ### Starting stunnelvers\n";
  if (!$PREUPGRADE and !$ADDNODE) {
    print LOG "Skipping: Not doing upgrade or add node\n";
    return;
  }
  getinstalledversion() if (!$AVAMARVER);
  if ( $VERSNUM < 600 or $VERSNUM >= 610 ) {
    print LOG "Skipping: $AVAMARVER is not 6.0.x\n"; 
    return;
  }
  getnodetype() if (!%PARTLIST);
  if ( $NODETYPE !~ /Gen4/i ) {
    print LOG "Skipping: $NODETYPE is not Gen4\n"; 
    return;
  }
  getconfiginfo() if (!$GOTCONFIGINFO);
  my ($node,$e,$last);
  foreach(grep(/stunnel/,@RPMS)) {
    print LOG "$_\n";
    ($node,$_)=split();
    if (/stunnel-4.36-0.10.2/) {
      $e="yes"
    }
  }
  if ($e) {
    printboth("RESOLUTION: stunnel will need to be upgraded post install/add node.  See bug 45983.\n\n");
    msg("stunnel version","FAILED");
  } else {
    msg("stunnel version","PASSED");
  }
}
########## End stunnelvers  ##########


########## Start bug47560 ##########
# Code 1 marked obsolete, bug 47560 fixed in rollup 50070/51416
sub bug47560 {
# Called from MCS patches if bug 50070 is needed
  print LOG "\n\n\n### ".localtime()." ### Starting bug47560\n";
    printboth("        Part of this bug is event code 1 will not create service requests.\n");
    printboth("        The file event_code_1.txt has all the code 1 events that have been missed\n");
    $cmd=qq[ sed -n '/6.1.1-8[17]/,\$p' /data01/cur/err.log | sed -n '/<0001>/p' ];
    mapall($ALL,$cmd);
    open(CMD_PIPE,$TMPFILE);
    open(EVENT,">event_code_1.txt");
    chomp($dt = `date +%Y-%m-%d`);
    print EVENT "======================================================\n";
    print EVENT "\n$dt Event Code 1 missed since upgrade\n\n";
    my ($nodes)="";
    while (<CMD_PIPE>) {chomp;
      print LOG "$_\n";
      if (/(\(0\..*\)) ssh/) {
        print EVENT "======================================================\n";
        print EVENT "Node $1\n"; 
      } else {
        print EVENT "$_\n";
      }
    }
}
########## End bug47560 ##########

########## Start ipmi ##########
sub ipmi {
  print LOG "\n\n\n### ".localtime()." ### Starting ipmi\n";
  gethardware() if (!$MANUFACTURER);
  my $nodes=getnodes_hw("dell|emc");
  if (!$nodes) {
    print LOG "no dell/emc nodes found\n";
    return;
  }
  $cmd=qq[ echo "IPMI: `/sbin/lsmod | grep -c ipmi`" ];
  mapall("--nodes=$nodes",$cmd);
  open(CMD_PIPE,$TMPFILE);
  my $e;
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/) {
      $node=$1; 
      next;
    } 
    if (/IPMI: (.*)/) {
      if ($1 < 2) {
        $e="yes";
        printboth("ERROR: Node $node IPMI is not working\n");
      }
      next;
    }
    printboth("ERROR: Unexpected output '$_' (last node $node)\n");
    $e="yes"
  }
  if ($e) {
    printboth("RESOLUTION: IPMI does not appear to be working.  See KB126655\n");
    if ($PREUPGRADE) {
      printboth("            An upgrade cannot be performed until this is fixed\n");
    }
    printboth("\n");
    msg("IPMI Check","FAILED");
  } else {
    msg("IPMI Check","PASSED");
  }

}
########## End ipmi ##########

########## Start rotatesecure ##########
# bug 38834, hotfix 46987
sub rotatesecure {
  print LOG "\n\n\n### ".localtime()." ### Starting rotatesecure\n";
  my $cmd=q[ head -1 /etc/logrotate.d/aide  ] ;
  mapall("--user=root $ALL",$cmd);
  open(CMD_PIPE,$TMPFILE);
  my ($nodes)="";
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    if (/\/var\/log\/secure\.\* {/ ) {
      $nodes.="," if ($nodes);
      $nodes.=$node;
    }
  }
  if ($nodes) {
    printboth("RESOLUTION: Apply hot fix 46987 to fix configuration file /etc/logrotate.d/aide.\n\n");
    msg("Rotate /var/log/secure","FAILED");
  } else {
#    msg("Rotate /var/log/secure","PASSED");
  }
}
########## End rotatesecure ##########

########## Start ldapauth ##########
sub ldapauth {
  print LOG "\n\n\n### ".localtime()." ### Starting ldapauth\n";
  
  $cmd= qq[ grep "enable_new_user_authentication_selection" /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml | grep -c true ];
  $newauth=`$cmd`;
  if ($VERSNUM >= 610 and $newauth) {
    msg("LDAP Authentication","PASSED");
    return;
  }
  if ( ! -e "/usr/local/avamar/etc/domains.cfg" ) {
    print LOG "Skipping: No file\n";
    return;
  }
  my ($e)="";
  open(FILE,"/usr/local/avamar/etc/domains.cfg");
  while(<FILE>) {
    next if (/^\s*#/);
    my ($name,$val)=split("=");
    next if ($val <= 1 );
    $e="yes";
  }
  if ($e) {
    printboth("RESOLUTION: If upgrading to 6.1 LDAP authentication may be broken. See esc 4320 for more info\n");
    msg("LDAP Authentication","WARNING");
  } else {
    msg("LDAP Authentication","PASSED");
  }
}
########## End ldapauth ##########

########## Start adsinfo  ##########
sub adsinfo {
  print LOG "\n\n\n### ".localtime()." ### Starting adsinfo\n";
  $cmd=qq[ tac /usr/local/avamar/var/avi/server_log/avinstaller.log.0 | grep 'ADS info: '] ;
  my $ads="";
  my %dupads="";
  open(FILE,"$cmd|");
  while(<FILE>) {chomp;
    if (/hostname: (.*), port.*version: (.*), last/) {
      next if ($dupads{$1});
      $dupads{$1}=1;
      $ads.=", " if ($ads);
      $ads.="$1 ($2)";
    }
  }
  if ($ads) {
    msg("Downloader Server:",$ads);
  }
}
########## End  adsinfo ##########

########## Start switchconf  ##########
sub switchconf {
  print LOG "\n\n\n### ".localtime()." ### Starting switchconf\n";
  getnodetype() if (!%PARTLIST);
  if ($NODETYPE !~ /gen4/i) { 
    print LOG "Skipping check.  No Gen4 in nodetype: $NODETYPE\n";
    return;
  }
  if ($NODE_COUNT == 1) {
    print LOG "Skipping check.  Single Node\n";
    return;
  }
  my $result=`ifconfig bond1`;
  print LOG $result;
  if ( $result !~ /Bcast:192.168.255.255/) {
    print LOG "Skipping check.  Default IP not in use\n";
    return;
  }
  mapall("--user=root --nodes=0.s","arping -I bond1 -c3 192.168.255.3");
  open(CMD_PIPE2,$TMPFILE);
  my $last="";
  my $e;
  while (<CMD_PIPE2>) { chomp;
    print LOG "$_\n";
    if (/^Unicast .*\[(.*)\]/) {
      my $mac=$1;
      if ($last ne $mac and $last) {
        $e="yes";
        printboth("ERROR: Duplicate IP Address bond1 192.168.255.3 MAC=$mac MAC=$last\n");
        printboth("       This is probably a conflict between node 0.1 and the switch\n");
        printboth("RESOLUTION: Resolve duplicate IP addresses\n");
        last;
      }
      $last=$mac;
    }
  }

  my $resolution="";
  my $err=0;
  ($resolution,my $switchtype1)=switchconf1("192.168.255.200","avg4_swa","Switch A",$resolution);
  ($resolution,my $switchtype2)=switchconf1("192.168.255.201","avg4_swb","Switch B",$resolution);
  if ($resolution) {
    printboth("$resolution\n");
    $err=1;
  }

  if ($switchtype1 ne $switchtype2) {
    printboth("ERROR: Switch A is $switchtype1 and Switch B is $switchtype2\n");
    printboth("RESOLUTION:  Replace one of the switches.  Difference switches are not supported\n\n");
    $err=1;
  }
  
  if ($err) {
    msg("Switch Configuration","FAILED");
  } else {
    msg("Switch Configuration","PASSED");
  }
}

# check each switch
sub switchconf1 {
  my($ip,$allied_pattern,$brocade_pattern,$resolution)=@_;
  my $switchtype="Unknown";
  my $result = qx{ echo -e 'set timeout 5\nspawn telnet $ip\nexpect {\n"login:" {send "manager\r"}\ntimeout exit}\nexpect "sword:"\n
                send -- "$SPW\r"\nexpect ">"\nsend -- "show conf\r"\n expect ">"\n send -- "quit\r"'|expect - 2>&1 };
  print LOG "#--> switch $ip: $result\n";
  if ($result =~ /No route to host/i) {
    printboth("INFO:  No switch found at default location $ip\n");
  } elsif ($result !~ /$allied_pattern|$brocade_pattern/i) {
    printboth("WARNING:  Switch $ip connected but did not respond as expected\n");
    $resolution="RESOLUTION: Configure switch to Avamar settings.  See KB127406\n";
  } else {
    $switchtype=($result =~ /$allied_pattern/) ? "Allied Telesys" : $switchtype ;
    $switchtype=($result =~ /$brocade_pattern/) ? "Brocade" : $switchtype ;
    print LOG "Found pattern '$allied_pattern|$brocade_pattern'.  Switchtype $switchtype\n";
  }
  return ($resolution,$switchtype);
}
########## End switchconf ##########

########## Start greenvillehotfix ##########
sub greenvillehotfix {
  print LOG "\n\n\n### ".localtime()." ### Starting greenvillehotfix\n";
  getinstalledversion() if (!$AVAMARVER);
  if ($AVAMARVER !~ /6.1.0-402/) { 
    print LOG "Skipping: $AVAMARVER is not 6.1.0-402\n";
    return;
  }
  my $result=`grep -c expire_data_after_secs  /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml`;
  print LOG "Count: $result\n";
  if ($result > 0 ) { 
    printboth("ERROR: Greenville Hotfix has been applied that will cause an upgrade to fail\n");
    printboth("RESOLUTION:  See esc6199, comment#9 for instructions before upgrading.\n\n");
    msg("Greenville Hotfix","FAILED");
  } else {
    msg("Greenville Hotfix","PASSED");
  }

}
########## End greenvillehotfix ##########


########## Start metadatacapacity ##########
sub metadatacapacity {
  print LOG "\n\n\n### ".localtime()." ### Starting metadatacapacity\n";
  if (!$PREUPGRADE and !$METADATA_CAPACITY) {
    print LOG "Skipping.  No preupgrade\n";
    return;
  }
  getnodetype() if (!%PARTLIST );
  getdatadomain() if (!$DDRMAINT_VERSION ) ;
  openmcdb() if (!$dbh);
  if (!%DD and !$METADATA_CAPACITY) {
    print LOG "Skipping.  No DD\n";
    return if !$DEBUG;
  }
  my $use_vers=($UPGRADE_VERSION) ? $UPGRADE_VERSION : $DATANODEVERSION;
  if ($use_vers < "7"  and !$METADATA_CAPACITY) {
    print LOG "Skipping.  Pre v7\n";
    return;
  }
  if ($VERSNUM >=700 and !$METADATA_CAPACITY) {
    print LOG "Skipping.  Already V7 ($VERSNUM)\n";
    return if !$DEBUG;
  }

  my $result=`grep stripeUtilizationCapacityFactor /usr/local/avamar/var/mc/server_data/prefs/mcserver.xml`;
  my($curr_stripefactor)=$results=~m {value="(.*)"};

print LOG "CS: $curr_stripefactor\n";
  my $err="";
  my ($utilization,$cpoverhead,$overhead,$gridsize,$cur,$readonly,$stripe_count_pct)=(0)x7;
  my (%disk,%node);
  $readonly=$NODELIST{'/nodestatuslist/gsanconfig/diskreadonly'};
  $readonly=(!$readonly and $DEBUG) ? 65 : $readonly ;
  if ($readonly >65) {
    printboth("WARNING: Read-only is not the default which may cause unpredicatble results.  Using 65% instead of $readonly\n");
    $readonly=65;
  } elsif ($readonly <65) {
    printboth("WARNING: Read-only is $readonly which is not the default and may cause unpredicatble results.\n");
  }


  # Get each nodes stripe count from avmaint ping
  my %nsc;
  open($fh,"avmaint ping|");
  while(<$fh>) {
    next if (!/id="(0\..+)-/);
    $nsc{$1}++;
  }

  # Get max stripe_count_pct and max cur 
  foreach my $node (sort @NODES) {
    my $physnode=$NODE_LXREF{$node};
    my $partno=$NODE_INFO{"$physnode"}{partno};
    my $maxstripe=$PARTLIST{$partno}{maxstripe};
    print LOG "node:$node part:$partno maxstripe:$maxstripe stripecount:$nsc{$node} pct:";
    if ($maxstripe<=0) {
      print LOG "ERR\n";
      printboth("ERROR: Node $node does not have a maximum stripe allowed value\n");
      $err="FAILED";
    } else {
      $stripe_count_pct=max($nsc{$node}/$maxstripe,$stripe_count_pct);
      print LOG ($nsc{$node}/$maxstripe),"\n";
    }
    for (my $disk=0;$disk<$NODELIST{"/nodestatuslist/nodestatus/$node/disks/count"};$disk++){
      my $key="/nodestatuslist/nodestatus/$node/disks/disk/$disk";
      my $srpct=$NODELIST{"$key/stripe-reserved"} / $NODELIST{"$key/fs-size"} ;
      print LOG qq[srpct $NODELIST{"$key/stripe-reserved"} / $NODELIST{"$key/fs-size"} = $srpct\n];
      $cur=max($cur, $srpct);
      $gridsize+=$NODELIST{"$key/fs-size"};
    }
    #$gridsize=$gridsize/$NODELIST{"/nodestatuslist/nodestatus/$node/disks/count"};
  }
  $utilization=sprintf("%d",$cur/$readonly*100*100);
  my $max=sprintf("%d",100*$cur); 
  # GREEN A
  if ($cur<.52) { #80%
    printboth("INFO:  Avamar system is at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain. (Green A)\n");
    printboth(qq[RESOLUTION: Please read the "EMC Avamar Metadata Capacity Reporting and Monitoring" Document for 7.0 before adding any additional workloads to Data Domain.\n\n]);
    msg("Metadata Capacity","INFO");
    return;
  }

  # RED
  if ($cur>=.78) { #120%
    $msg=qq[ERROR: Avamar system has been fully utilized at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain. (Red)\nRESOLUTION:  Please consult with the EMC account team to increase the capacity prior to upgrading to v7.0.  
             Upgrading now will cause the grid to go into a permanent, irrecoverable state where the Backup Scheduler is disabled. 
             Restores can still be performed but additional capacity will need to be added to the system to resume normal operations.\n\n];
    printboth($msg);
    msg("Metadata Capacity","FAILED");
    print "\n${msg}Do you want to continue performing other health checks? ";
    $input=<STDIN>;
    exit if ($input !~ /^y/i) ;
    return;
  }
  
### 
  # Check for 3.3TB nodes which we cant identify cpoverhead
###
  if ($NODETYPE eq "3.3TB Gen3" and !$CPOVERHEAD ) {
    print LOG "Gen3 3.3TB metadata\n";
    $file="/tmp/admincron.cps";
    my $msg="";
    if (! -e "$file") { while() { # while is to make easy way to exit on failure
#  File does not exist, add commands to cron
      my $xml = new XML::Parser( Style => 'Tree' );
      my $tree=$xml->parsefile("avmaint lscp|") ;
      SimpleXMLTree($tree);
      my %lscp=%xmltree;
      my $time="";
      for (grep /tag/, %lscp ) {
        my $key="/checkpointlist/checkpoint/$lscp{$_}";
        next if ($lscp{"$key/hfscheck/validcheck"} ne "true");
        my ($sec, $mn, $hr, $dd, $mm, $yy) = (localtime($lscp{"$key/cpctime"}));
        print LOG qq[HFS: $key $lscp{"$key/cpctime"} $mm/$dd/$yy $hr:$mn:$sec\n];
        $time="$mn $hr";
      }
      if (!$time) {
        $msg="ERROR: Unable to get checkpoint start time from last HFSCheck (avmaint lscp)\n";
        last;
      } 
      my $result=`crontab -l |grep -v '$file'> /tmp/admincron`;
      if ($? != 0 ) {
        $msg="ERROR: Failed to get current crontab (crontab -l): Err $? - $result\n";
        last;
      }
      print LOG "crontab -l : $? : $result\n";
      my $result=`cd /usr/local/avamar/bin; /usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid; /usr/local/avamar/bin/mapall --parallel copy cps 2>&1" 2>&1`;
      if ($?!=0) {
        $msg="ERROR: Failed to copy 'cps' to nodes (mapall copy cps): Err $? - $result\n";
        last;
      }
      print LOG "mapall copy: $? : $result\n";
      open(my $fh,">>/tmp/admincron");
      print $fh qq[$time * * * (/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid; /usr/local/avamar/bin/mapall './cps'") 2>/dev/null >> $file; sed -i -e :a -e '\$q;N;2000,\$D;ba' $file\n];
      my $result=qx{crontab /tmp/admincron};
      if ($?!=0) {
        $msg="ERROR: Failed to install new cron (crontab /tmp/admincron): Err $? - $result\n";
        last;
      }
      print LOG "updating cron: $? : $result\n";
      last;
      } #end while
      if ($msg) {
        printboth("NOTICE:  Avamar system is at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain.\n");
        printboth("${msg}       Automatic installation of overhead monitoring for Gen3 3.3TB nodes failed.\n");
        printboth(qq[RESOLUTION: Resolve problem identified or manually add overhead collecting to cron and "cps" to data nodes.
-------------------------------------------------------------------------------
Steps to start collecting checkpoint overhead on Gen3 3.3TB Nodes:
1. Log in to the grid as admin
2. Load SSH keys
# ssh-agent bash
# ssh-add ~/.ssh/dpnid

3. Copy 'cps' program to every node (even on single node servers): 
# cd /usr/local/avamar/bin
# mapall copy cps

4. Identify what time the validated checkpoint was created  (07:12 in the example).  The "rol" is the validated rolling hfscheck.
# cplist
# cp.20140320160917 Thu Mar 20 07:12:17 2014   valid rol ---  nodes   1/1 stripes  24125
# cp.20140320172253 Thu Mar 20 10:22:53 2014   valid --- ---  nodes   1/1 stripes  24125

5. Add the crontab line to the admin cron to run cps every day at the HFScheck time from step 3. Note the order is minute hour.
# crontab -e
07 12 * * * (/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid; /usr/local/avamar/bin/mapall './cps'") 2>/dev/null >> /tmp/admincron.cps; sed -i -e :a -e '\$q;N;2000,\$D;ba' /tmp/admincron.cps
-------------------------------------------------------------------------------
\n]);
        msg("Metadata Capacity","FAILED");
      } else { 
        printboth("NOTICE:  Avamar system is at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain.\n");
        printboth("         Automatic installation of overhead monitoring for Gen3 3.3TB succeeded.\n");
        printboth("RESOLUTION: Re-run script after five days to get metadata recommendation\n\n");
        my $results=`touch $file`;
        msg("Metadata Capacity","FAILED");
      }
      return;
    } else {
#   File exists, check for 5 days worth of history to use
      open(my $fh,$file);
      my ($oh,$cnt,$days)=(0)x3;
      while(<$fh>) {
        my($gb,$pct,$cp)=split();
        $oh+=$pct if (/cp\./);
        $cnt++ if (/ cur/);
        $days++ if (/Using/);
      }
      print LOG "Days: $days  count:$cnt  TotOH:$oh\n";
      if ($cnt>1) {
        $CPOVERHEAD=$oh/$cnt;
        print LOG "CPOVERHEAD=$CPOVERHEAD\n";
      }
      if ($days<5 and !$OVERRIDE) {
        printboth("NOTICE:  Avamar system is at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain.\n");
        printboth("         Overhead monitoring has been installed for Gen3 3.3TB nodes but there are only $days days of overhead monitoring.\n");
        printboth("RESOLUTION: Re-run script after five days to get metadata recommendation\n\n");
        msg("Metadata Capacity","FAILED");
        return;
      }
    }
  }
# End of Gen3 3.3TB

 # YELLOW cur>=80% <=120% Get maintenance history. Count cp,hfs,gc. Build criteria for sql to select hfs CP's
 if ($CPOVERHEAD) {
   print LOG "Skipping all cpoverhead checks. using flag cpoverhead=$CPOVERHEAD * 5\n";
   $overhead=$CPOVERHEAD/100*5 ;
 } else {
  my $crit="ERROR";
  my $days=0;
  while($crit =~ /ERROR/ and $days<=30) {
    $crit=cpoverhead($days);
    print LOG "$crit\n";
    $days+=1;
  }
  if ($crit =~ /ERROR/ ) {
    printboth("WARNING:  Avamar system is at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain.\n");
    printboth("$crit\n        Cannot determine checkpoint overhead.  No reliable 5 day period in past 30 days\n");
    printboth("RESOLUTION:  Determine why maintenance routines have not run reliably for 5 days in a row any time in the past month\n\n");
    printboth("             Escalate to an RCM SME and then Avamar AppEng if needed. Included hc_proactive_check.log with email\n\n");
    msg("Metadata Capacity","FAILED");
    return;
  }
 
### Get CP overhead:  Highest value of O/S at HFSCP, lowest O/S for that day, also grab cur and disk size
  my $sday=$days+5;

 my $sql=qq[ select avg(cpavg) as cpavg 
             from ( 
               select date_time,avg (max) as cpavg 
               from ( 
                 select date_time,node,disk,max(used_mb/capacity_mb)- 
                  (select min(used_mb/capacity_mb) 
                   from v_node_space m 
                   where date_time>=NOW()-INTERVAL '$sday day' 
                    and date <= NOW()-INTERVAL '$days day'  
                    and n1.node=m.node and n1.disk=m.disk
                  ) as max from v_node_space n1 
                 where ($crit) 
                 and disk >= 0 group by 1,2,3
               ) as dayavg
               group by date_time order by avg(max) desc offset 2
             ) as gridavg
  ];
  print LOG $sql,"\n";
  my $sth = $dbh->prepare($sql); $sth->execute;
  my $R=$sth->fetchrow_hashref();
  $overhead=$R->{cpavg}*5;
  print LOG "cnt=$c  overhead: $overhead \n" if $DEBUG;
 }

 ### Check Retenion
  my ($retenmsg,$retenset)=("")x2;
  if (!$METADATA_RETENTION) {
    $retention=60;
    $retenmsg=".\nThe default retention of 60 days is being used which affects these estimates.  Use --retention=N to change retention days";
  } else {
    $retention=$METADATA_RETENTION;
    $retenmsg=" with $retention days of retention";
  }

### Calculate everything
  $gridsize=$gridsize/1024/1024;
  my $maxcur=$overhead+$cur;
  my $disknogc=.89;
  my $maxallowcur=($disknogc-$overhead >.78) ? .78 : $disknogc-$overhead;
  my $availcur=$maxallowcur-$cur;
  my $parity=1;
  if ($NODE_COUNT>2) {
    my $parity_nodes=($NODE_COUNT>9) ? 9 : $NODE_COUNT-1;
    $parity=1-(1/$parity_nodes);
  }
  my $metadata=$availcur * $gridsize  * $parity;
  my $reten_adjust=2+(.03*$retention);
  my $stripefactor=sprintf("%3.2f",$maxallowcur/($readonly/100) );
  my $minfs=$metadata * 100 / $reten_adjust ;
  my $maxfs=$minfs*4;
  
    printf LOG "Node Count.....: %d\n",$NODE_COUNT;
    printf LOG "Read-only......: %d\n",$readonly;
    printf LOG "CUR............:%6.2f%% (Utilization=%d)\n",100*$cur, $utilization;
    printf LOG "Disknogc.......:%6.2f%% \n",100*$disknogc;
    printf LOG "Overhead.......:%6.2f%% \n",100*$overhead;
    printf LOG "Max allow Cur..:%6.2f%% (disknogc-overhead to max of 78%%)\n",100*$maxallowcur;
    printf LOG "Cur............:%6.2f%% (stripe-reserved)\n",100*$cur;
    printf LOG "Available Cur..:%6.2f%% (MaxAllowCur-Cur)\n",100*$availcur;
    printf LOG "Grid Size......:%6.2fTB (raw disk space)\n",$gridsize;
    printf LOG "Parity factor..:%6.2f%%\n",100*$parity;
    printf LOG "AV metadata....:%6.2fTB (gridsize*Parity%%*AvailCur%%)\n",$metadata;
    printf LOG "RetentionFactor:%6.2f   (based on $retention days)\n",$reten_adjust;
    printf LOG "Min FS on DD...:%6.2fTB (avmetadata * 100 / retention)\n",$minfs;
    printf LOG "Max FS on DD...:%6.2fTB (avmetadata * 400 / retention)\n",$maxfs;
    printf LOG "StripeFactor...:%6.2fTB (maxallowcur / readonly)\n",$stripefactor;
    print LOG "\n" ;

# OUTPUT
  my $category,$ddonly;
  printboth("WARNING:  Avamar system is at $utilization% ($max% CUR) capacity for metadata storage for backups to Data Domain with an estimate of ".sprintf("%d",$overhead*100)."% overhead. ");
    printboth(qq[\nRESOLUTION:   The customer must be advised of and agree to new requirements.  
              If the customer does not agree, consult with the EMC account team prior to upgrading to v7.0.  
              Upgrading now and not adhering to the new requirements may cause the server to go into a permanent, 
              irrecoverable state where the Backup Scheduler is disabled.  Restores can still be performed but
              additional capacity will need to be added to the system in order to resume normal operations.  
              Please be sure to read the "EMC Avamar Metadata Capacity Reporting and Monitoring" Document for 7.0.
              Consult with the EMC account team to ensure the Avamar grid is ready for additional workloads to Data Domain.
]);
    if ($metadata<0 or $overhead+$cur>.89 or $stripefactor<1.05) {
      printboth(qq[\nThe new requirements will allow the grid to be upgraded but no estimate can be given for the amount of metadata storage for Data Domain backups.\n]);
    } else {
      printboth(qq[\nThe new requirements will allow configuration changes so there is an additional ].sprintf("%.1fTB",$metadata).qq[ of metadata storage for Data Domain backups.\nThis will protect between an estimated],sprintf("%dTB and %dTB",$minfs,$maxfs),qq[of front end file system data sent to Data Domain$retenmsg.\n]);
    }

    if ($overhead + $cur < .75 ) {
      $req=" - There are no new requirements for this category.\n";
      $category="Yellow A+";
    } elsif ($overhead + $cur < .85) {
      $req =" - New clients must have their backups sent to Data Domain\n";
      $req.=" - Existing Avamar clients can continue to backup to Avamar.\n";
      $category="Yellow A";
    } elsif ($overhead+$cur < .89)  {
      $req =" - New clients must have their backups sent to Data Domain\n";
      $req.=" - Existing Avamar clients must change to send their backups to Data Domain if supported\n";
      $req.=" - Existing Avamar clients not supported by Data Domain can continue to backup to Avamar\n";
      $category="Yellow B";
      $ddonly=" - dd_only_mode=SUPPORTED (mcserver.xml)\n";
    } else  {
      $req=" - New clients must have their backups sent to Data Domain\n";
      $req.=" - Existing Avamar client must change to send their backups to Data Domain if supported.\n";
      $req.=" - Existing Avamar clients not supported by Data Domain must be stopped.\n";
      $req.=" - No new data can be added to the Avamar grid from new or existing clients.\n";
      $category="Yellow C";
      $stripefactor=1.20;
      $ddonly=" - dd_only_mode=ALL (mcserver.xml)\n";
    }
  printboth("\nNEW REQUIREMENTS:\n$req");
  $disknogc*=100;
  printboth("\nConfiguration Changes For $category:\n - stripeUtilizationCapacityFactor=$stripefactor (mcserver.xml)\n${ddonly} - disknogc=$disknogc (avmaint config)\n\n");
  msg("Metadata Capacity","WARNING");
}
########## End metadatacapacity ##########


########## Start cpoverhead ##########
sub cpoverhead {
  my $days=shift;
  my $sdays=$days+7;
  print LOG "cpoverhead date $date\n";
  my $sql = qq[ select code,date,time,summary from v_events where code in (4003,4004,4201,4202,4301,4302)
    and date >= NOW() - INTERVAL '$sdays day' and date <= NOW()-INTERVAL '$days day' order by date, time  ];
  my $sth = $dbh->prepare($sql); $sth->execute;
  my %event;
  my $crit="";
  my $LASTCP;
  while ( my $R = $sth->fetchrow_hashref() ) {
    print LOG "Event Code: $R->{code} $R->{date} $R->{time} $R->{summary}\n";
    if ($R->{code}==4004) { return "ERROR: Failed HFSCheck on $R->{date}.";}
    if ($R->{code}==4202) { return "ERROR: Failed GC on $R->{date}.";}
    if ($R->{code}==4302) { return "ERROR: Failed CP on $R->{date}.";}
    $event{$R->{code}}++;
    # Add last CP to criteria when we see HFS
    if ($R->{code}==4003){
      print LOG "HFS Checkpoint: $LASTCP->{date} $LASTCP->{time}\n";
      my $time=substr($LASTCP->{time},0,4);
      $crit.=" or " if ($crit);
      $crit.=" (date_time >= '$R->{date} ${time}0:00' and date_time < '$R->{date} ${time}9:59') \n ";
    }
    $LASTCP={%$R};
  }
  print LOG "5 day HFS cnt.: $event{4003}\n5 day CP count: $event{4301}\n5 day GC count: $event{4201}\n";
  return "ERROR: $event{4003} Successful HFSChecks is fewer than the required 5 in a 5 day span." if ($event{4003} < 5 and !$OVERRIDE);
  return "ERROR: $event{4201} Successful Garbage Collect runs is fewer than required 5 in a 5 day span" if ($event{4201} < 5 and !$OVERRIDE);
  return "ERROR: $event{4301} Successful Checkpoints is fewer than required 5 in a 5 day span" if ($event{4301} < 5 and !$OVERRIDE);
  printboth("WARNING: $event{4301} Checkpoints is fewer than the recommended 10 in a 5 day span.  This could cause checkpoint overhead to double.") if ($event{4301}<10) ;
  return $crit;
}
########## End cpoverhead ##########


########## Start nodexref ##########
sub nodexref {
  print LOG "\n\n\n### ".localtime()." ### Starting nodexref\n";
  $cmd='tail -1 /data01/cur/err.log; echo "SHELL:"$SHELL' ;
  mapall("",$cmd);
  open(CMD_PIPE,$TMPFILE);
  $NODE_COUNT=0;
  my $shell="";
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    if (/(\(0\..*\)) ssh/) {
      $node=$1;
      $NODE_COUNT++;
    } elsif (/^SHELL:(.*)/) {
      if (!/bash/) {
        $shell.="ERROR: Node $node shell is $1 and not the default /bin/bash\n";
      }
    } else {
      my($date,$logical)=split();
      $logical =~ s/[{}()]//g;
      $NODE_XREF{$node}=$logical;
      $NODE_LXREF{$logical}=$node;
      print LOG "phys $node log $logical for $_\n";
    }
  }
  if ($shell) {
    printboth("${shell}RESOLUTION:  See KB193264\n\n");
    msg("Shell Environment","FAILED");
  }
}
########## End nodexref ##########

########## Start replpartners ##########
sub replpartners {
  print LOG "\n\n\n### ".localtime()." ### Starting replpartners\n";
  $cmd=qq[ avmgr getl --path=/REPLICATE 2>&1 | tail +2 ];
  open(CMD_PIPE,"$cmd|");
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    my ($foo,$name,$foo2)=split();
    msg("Replication Partner","Target for $name");
  }
  $cmd=qq[ grep -P '^\s*--dstaddr' /usr/local/avamar/etc/repl*_cron*.cfg 2>/dev/null | sort -u ];
  open(CMD_PIPE,"$cmd|");
  my %dupname;
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    my ($foo,$name)=split("=");
    next if ($dupname{$name});
    $dupname{$name}=1;
    msg("Replication Partner","Source to $name");
  }
}
########## End replpartners ##########

########## Start etchosts ##########
sub etchosts {
  print LOG "\n\n\n### ".localtime()." ### Starting etchosts\n";

  my $e=0;
  $cmd=qq[ ping -c1 `hostname` ];
  mapall($ALL,$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) {chomp;
    print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    if (/unknown host (.*)/) {
      printboth("Error: Node $node hostname $1 is not resolvable.\n");
      $e=1;
    }
  }
  if ($e) {
    printboth("RESOLUTION: Fix DNS or add hostname to /etc/hosts\n\n");
    msg("Host Name Entry","FAILED");
  }
}
########## End etchosts ##########

########## Start plugin_catalog ##########
sub plugin_catalog {
  print LOG "\n\n\n### ".localtime()." ### Starting plugin_catalog\n";
  if (!$PREUPGRADE) {
    print LOG "Skipping: only run for preupgrade\n";
    return;
  }
  #<plugin-list version="70100.427">
  $_=qx{ grep 'plugin-list version' /usr/local/avamar/lib/plugin_catalog.xml };
  my ($plugver)= m/"(.*)"/;
  msg("Plugin Catalog Version",$plugver);
}
########## End plugin_catalog ##########

########## Start checkemctools ##########
sub getcmdtool {
  print LOG "\n\n\n### ".localtime()." ### Starting checkemctools\n";
  gethardware() if (!$MANUFACTURER);
  my $nodes=getnodes_hw("emc");
  if (!$nodes) {
    print LOG "no emc nodes found\n";
    return;
  }
  my $e="";
  $cmd=q[  CmdTool2 -encinfo -a0 -nolog | awk '{print "ENC:"$0}';
           CmdTool2 -ShowSummary -A0 -nolog | awk '{print "SS:"$0} ';
           CmdTool2 -LDInfo -Lall -aALL -nolog | awk '{print "VD:"$0} ';
           sudo ipmitool sdr | awk '{print "SDR:"$0}';
           flashupdt -i | awk '{print "FLSH:"$0} ';
           ipmitool raw 0x30 0x2e 0x01 | awk '{print "CR:"$0} ';
           dmidecode | grep SandyBridge | awk '{print "SB:"$0} ';
  ];

  mapall("--user=root --nodes=$nodes",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while (<CMD_PIPE>) { chomp;
    #print LOG "$_\n";
    $node=$1 if (/(\(0\..*\)) ssh/);
    (my $cmd,$_)=split(":",$_,2);
    if ($cmd eq "SDR") {
      my($name,$info,$value)=split(/\s*\|\s*/);
      $CMDTOOL{"SDR"}{$node}{$name}{$name}=$value if $value;
      next;
    }
    if ($cmd eq "CR") {
      $CMDTOOL{"flash"}{$node}{"CR"}=$_;
      next;
    }

    s/^\s*//; s/\s*$//;
    my($field,$value)=split(/\s*:\s*/,$_,2);
    $field=~ s/\s*$//;

    if ($cmd eq "SS") {
      $category=$_ if (/^System$|^Controller$|^BBU$|^Enclosure$|^PD$|^Virtual Drives$/ );
      $name=$value if ($field =~ /^ProductName$|^BBU Type$|^Connector$|^Virtual Drive$/);
      $name=$value if ($field eq "Product Id" and $category ne "PD" );
      $CMDTOOL{$category}{$node}{$name}{$field}=$value if $value;
      print LOG "Add CMDTOOL {$category}{$node}{$name}{$field}=$value\n" if $value;
    } elsif ($cmd eq "ENC") {
      $name=$value if ($field =~ /Product Identification/);
      $CMDTOOL{"Enclosure"}{$node}{$name}{$field}=$value if ($field =~ /Product Revision Level/);
      print LOG "Add CMDTOOL {Enclosure}{$node}{$name}{$field}=$value\n" if $value;
    } elsif ($cmd eq "VD") {
      $name=$value if ($field =~ /^Virtual Drive/);
      $CMDTOOL{"VirtualDrive"}{$node}{$name}{$field}=$value if $value;
      print LOG "Add CMDTOOL {Virtual Drive}{$node}{$name}{$field}=$value\n" if $value;
    } elsif ($cmd eq "FLSH"){
      $name=$field if (/System BIOS and FW Versions|BMC Firmware Version:|Baseboard Information:|System Information:|Chassis Information:/);
      $value =~ s/^[ \.]*//;
      $CMDTOOL{"flash"}{$node}{$name}{$field}=$value if $value;
      print LOG "Add CMDTOOL {flash}{$node}{$name}{$field}=$value\n" if $value;
    } elsif ($cmd eq "SB") {
      $CMDTOOL{"dmidecode"}{$node}{"SandyBridge"}=$_;
      print LOG "Add CMDTOOL {dmidecode}{$node}{SandyBridge}=$_\n" if $value;
    }
  }
}

########## End checkemctools ##########

########## Start checkemcstorage ##########
sub checkemcstorage {
  print LOG "\n\n\n### ".localtime()." ### Starting checkemcstorage\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  getcmdtool() if (!%CMDTOOL);
  my $e="";
  my $fail="PASSED";

 if (!$PREUPGRADE) {
  # Check Controller FW Package
  $e="";
  $section="Enclosure";
  $field="Product Revision Level";
  for $node (sort keys %{$CMDTOOL{$section}} ) {
   for $name (sort keys %{$CMDTOOL{$section}{$node}} ) {
     $value=$CMDTOOL{$section}{$node}{$name}{$field};
     print LOG qq[Enc: key: $key node:$node name:$name $field: $value\n];
     if ($name =~ /RES2SV240/ and $value !~/0d00/ ) {
       printboth("INFO: Node $node SAS expander firmware '$value' does not match most recent known version of '0d00'\n");
       $e="yes";
       $fail="WARNING";
     }
   }
  }
  printboth("RESOLUTION: Apply hot fix 56915 to upgrade firmware.\n\n") if ($e);
 } # END OF SKIP FOR PREUPGRADE

# INTEL BLOCK UPDATE
 my %rpm = (
	"CmdTool2" 			=>"8.07.16-1", 
	"storcli" 			=>"1.13.06-1",
	"selviewer" 			=>"11.0-B10",
	"syscfg"			=>"2.0-B10",
	"ipmiutil"			=>"2.7.9-1.EMC.SLES11",
	"sysinfo"			=>"12.0-B11",
	"flashupdt"			=>"11.0-B15",
	"lsi-megaraid_sas-kmp-default"	=>"06.704.15.00_2.6.32.12_0.7-3.1",
	"intel-igb-kmp-default"		=>"3.4.7_2.6.32.12_0.7-4.1",
	"intel-gb"			=>"3.4.7-4.1",
	"intel-ixgbe-kmp-default"	=>"3.14.5_2.6.32.12_0.7-1",
	"intel-ixgbe"			=>"3.14.5-1",
	"qlogic-qla2xxx-kmp-default"	=>"8.03.07.03.11.1.k_2.6.32.12_0.7-1"
   );

# Intel Block
# dont release yet. may be problem 
if ( 1 == 2 ) {
  my $emcblock="";
  my $biostransfer="";
  for my $node (sort (@NODES, ("0.s"))) {
   $biostransfer.="WARNING: Node $node is in BIOS firmware transfer mode\n" if ($CMDTOOL{"dmidecode"}{"($node)"}{"SandyBridge"});
   for my $component (sort keys %rpm) {
     my $version=getmaxrpmver(" $component",$node);
     $emcblock.="INFO:  Node $node $component version '$version' does not match latest known version of $rpm{$component}\n" if ( $version !~ /$rpm{$component}/ and $version) ;
   }
   my $version=$CMDTOOL{"Controller"}{"Intel(R) Integrated RAID Module RMS25CB080(Bus 0, Dev 0)"}{"FW Package Version"} ;
   $emcblock.="INFO:  Node $node Controller Firmware version '$version' does not match latest known version of 23.33.0-0022\n" if ($version ne "23.33.0-0022" and $version) ;

   $version=$CMDTOOL{"flash"}{"System BIOS and FW Versions"}{"BIOS Version"} ;
   $emcblock.="INFO:  Node $node System BIOS version '$version' does not match latest known version of 02.03.0003\n"  if ( $version !~ /02.03.0003/  and $version);

   $version=$CMDTOOL{"flash"}{"BMC Firmware Version"}{"ME Firmware Version"} ;
   $emcblock.="INFO:  Node $node ME Firmware version '$version' does not match latest known version of 02.01.07.328\n"  if ($version ne "02.01.07.328" and $version);

   $version=$CMDTOOL{"flash"}{"BMC Firmware Version"}{"OP Code"};
   $emcblock.="INFO:  Node $node BMC Firmware version '$version' does not match latest known version of 1.21.6580\n" if ( $version ne "1.21.6580" and $version);

   $version=$CMDTOOL{"flash"}{"BMC Firmware Version"}{"SDR Version"} ;
   $emcblock.="INFO:  Node $node SDR Firmware version '$version' does not match latest known version of 1.13\n" if ($version !~ /1.13/ and $version) ;
  }
  if ($emcblock) {
    my $msg="\n             Readme contains additional actions for nodes in BIOS firmware transfer mode" if ($biostransfer);
    printboth("$emcblock${biostransfer}RESOLUTION:  See hotfix 59674 for more information about the Intel block update$msg\n\n");
    msg("Intel block update","INFO");
  } else {
    msg("Intel block update","PASSED");
  }
}

# Megaraid and Megalodon drive
  my $errmegalodon="";
  my $errmegaraid="";
  for $node (sort keys %{$CMDTOOL{"PD"}} ) {
    for $disk (sort keys %{$CMDTOOL{"PD"}{$node}} ) {
       print LOG "disk: $node $disk $CMDTOOL{'PD'}{$node}{$disk}{'Product Id'}\n"; 
       $megalodon=1 if ($CMDTOOL{"PD"}{$node}{$disk}{"Product Id"} eq "ST2000NM0033-9ZM175" and $CMDTOOL{"PD"}{$node}{$disk}{"Revision"} =~ /GT0[26]/) ;
    }
    print LOG "driver $CMDTOOL{'System'}{$node}{'SGPIO'}{'Driver Version'}\n";
    if ( $megalodon and $CMDTOOL{"System"}{$node}{"SGPIO"}{"Driver Version"} eq "00.00.05.38-SL1") {
      $errmegaraid.="ERROR: Node $node Megaraid_sas driver 00.00.05.38-SL1 and Megalodon drive ST2000NM0033-9ZM175 found.\n" if ($errmegaraid !~ /$node/);
    } elsif ($megalodon) {
      $errmegalodon.="WARNING: Node $node has drive ST2000NM0033-9ZM175\n" if ($errmegalodon !~ /$node/);
    }
  }
  if ($errmegaraid) {
    printboth("${errmegaraid}RESOLUTION:  See hotfix bug 225015 for more information\n\n");
    msg("Megaraid Driver Version","FAILED");
  }
  if ($errmegalodon) {
    printboth("${errmegalodon}RESOLUTION:  Set perftriallimit to 16.  See esc8504 for more info\n\n");
    msg("Megalodon Drive","WARNING");
  }

 if (!$PREUPGRADE) {
  # Check For cold redundancy bug
  $e="";
  $section="flash";
  for $node (sort keys %{$CMDTOOL{$section}} ) {
     $value=$CMDTOOL{$section}{$node}{"BMC Firmware Version"}{"Op Code"}; 
     my $cr=$CMDTOOL{$section}{$node}{"CR"}; 
     print LOG "OpCode:$value CR:$cr\n";
     if ( $value < "1.20.5793" and $cr !~ /01 00/) {
       printboth("ERROR: Node $node power supply incorrectly set to cold redundancy\n");
       $e="yes";
       $fail="FAILED";
     }
  }
  printboth("RESOLUTION: See KB194024 for more information.\n\n") if ($e);
 }

  # Check For bad status or state
  $e="";
  for $section ("BBU","Enclosure","Controller","PD","Virtual Drives","VirtualDrive") {
    for $node (sort keys %{$CMDTOOL{$section}} ) {
     for $name (sort keys %{$CMDTOOL{$section}{$node}} ) {
       $field="State"; $value=$CMDTOOL{$section}{$node}{$name}{$field};
       if (!$value) {
         $field="Status"; $value=$CMDTOOL{$section}{$node}{$name}{$field};
       }
       next if !$value;
       if ($value !~ /ok|online|active|healthy|optimal/i) {
         printboth("ERROR: Node $node $section $name hardware in unknown $field '$value'\n");
         $e="yes";
         $fail="FAILED";
       }
     }
    }
  }
  printboth("RESOLUTION: Resolve hardware issues.\n             For disk issues try 'CmdTool2 -PDGetMissing -a0' or 'avsysreport vdisk|grep Slot' and look for a missing number\n\n") if ($e);

  # Check For bad SDR value
  $e="";
  my $resolution="";
  $section="SDR";
  for $node (sort keys %{$CMDTOOL{$section}} ) {
   for $name (sort keys %{$CMDTOOL{$section}{$node}} ) {
     $value=$CMDTOOL{$section}{$node}{$name}{$name};
     print LOG qq[SDR: key: $key node:$node name:$name $field: $value\n];
     if ($value !~ /ok|ns/) {
       printboth("ERROR: Node $node Sensor '$name' has unexpected status of '$value'\n");
       $resolution.="            For BB +3.3V Vbat issues see KB168990\n" if ($name =~ /BB.*Vbat/ and $resolution !~ /Vbat/);
       $e="yes";
       $fail="FAILED";
     }
   }
  }
  printboth("RESOLUTION: Check and resolve any hardware issues.  Use 'sudo ipmitool sdr' to see the error\n$resolution\n") if ($e);

  msg("EMC Hardware Health", $fail);
}
########## End checkemcstorage ##########

########## Start avhardening ##########
sub avhardening {
  print LOG "\n\n\n### ".localtime()." ### Starting avhardening\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  # Example rpm:  (0.0) avhardening-2.0.0-3
  if (my @noderpms=grep(/avhardening/,@RPMS)){
    my $lastrpm="x";
    my ($msg,$e,$upgmsg)=("")x4;
    for my $node (sort @NODES) {
      my $physnode=$NODE_LXREF{$node};
      my ($ver)=grep(/^\($physnode\)/,@noderpms);
      my ($rpmnode,$rpm)=split(/\s/,$ver);
      print LOG "phys:$physnode logic:$node rpm:$rpm\n";

      # Min req for SLES
      if ($NODE_INFO{$node}{os} =~ /suse/){ 
        # remove everything in rpm up to first number. replace any - with . for version comparison
        (my $tmprpm=$rpm) =~ s/^.*?(\d)/\1/;
        my @VER=split(/[-\.]/, $tmprpm);
        my @MIN=split(/[-\.]/, "2.0.0-7");
        my $error=0;
        my $index=0;
        for (@MIN) {
          last if (@VER[$index] > @MIN[$index]) ;
          if (@VER[$index] < @MIN[$index]) {
            $error=1;
            last;
          }
          $index++;
        }
      }
      if ($PREUPGRADE and $error) {
        $upgmsg.="ERROR:  Node $node $rpm is less than version 2.0.0-7\n";
      }
      $msg.="   Node $node AvHardening RPM $rpm\n";
      $e="yes" if ($rpm ne $lastrpm and $lastrpm ne "x") ;
      $lastrpm=$rpm;
    }
    if ($upgmsg) {
      printboth($upgmsg) ;
      printboth("RESOLUTION: Before upgrading avhardening must be removed.  See Esc 7192 for more information\n\n");
    }
    if ($e) {
      printboth("ERROR:  Mismatch of security RPM's installed\n$msg");
      printboth("RESOLUTION:  Review version of avhardeing RPM's installed on each node\n\n") ;
    }
    if ($e or $upgmsg) {
      msg("Avamar Hardening RPM","FAILED");
    } elsif ($lastrpm ne "x" ) {
      $lastrpm =~ s/^.*avhardening-//;
      msg("Avamar Hardening RPM",$lastrpm);
    }
  } else {
    print LOG "No hardening RPMS found\n";
  }
}
########## End avhardening #########


########## Start gen4sver ##########
sub gen4sver {
  print LOG "\n\n\n### ".localtime()." ### Starting gen4sver\n";
  getinstalledversion() if (!$AVAMARVER);
  if ($VERSNUM >= 611 ) {
    print LOG "Gen4s ok on $VERSNUM\n";
    return;
  }
  printboth("WARNING:  Avamar Version $AVAMARVER does not support Gen4s hardware.  Make sure you are not adding Gen4s hardware.\n\n") ;
  msg("Hardware Type", "WARNING");
}
########## End gen4sver ##########

########## Start getear ##########
sub getear {
  print LOG "\n\n\n### ".localtime()." ### Starting getear\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  for (grep /atrestencryption-status\/enabled/, %NODELIST) {
    if ( $NODELIST{$_} eq "true" ) {
      if ($PREUPGRADE and $UPGRADE_VERSION =~ /7.1.0/) {
        printboth("WARNING: If proper steps are not taken prior to running the Upgrade Workflow, the workflow\n");
        printboth("         will fail, and additional more difficult steps will have to be taken.\n");
        printboth("RESOLUTION: Be sure to follow the preupgrade steps outlined in the Solve Desktop Procedure Generator in the section\n");
        printboth("            called 'Configuration update for systems with Encryption at Rest enabled' before starting the Upgrade Workflow.\n\n"); 
        msg("Upgrade to 7.1.0 with EAR caution","WARNING");
      } else {
        printboth("INFO:  Encryption At Rest is enabled\n");
        msg("Encryption At Rest", "ENABLED");
      }
      last;
    }
  }

}
########## End getear ##########

########## Start getrestapi ##########
sub getrestapi {
  print LOG "\n\n\n### ".localtime()." ### Starting getrestapi\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  my $restapi_version="Not Installed";
  for(grep(/rest-api/,@RPMS)) {chomp;
    ($restapi_version)=$_=~ m/rest-api-(.*)/;
  }
  msg("REST API Version", $restapi_version);
}
########## End getrestapi ##########

########## Start getdellstorage ##########
sub getdellstorage {
  print LOG "\n\n\n### ".localtime()." ### Starting getdellstorage\n";
  gethardware() if (!$MANUFACTURER);
  my $nodes=getnodes_hw("dell");
  if (!$nodes) {
    print LOG "Skipping, no Dell nodes found\n";
    return;
  }
  checkostools() if (!$RAN_OMREPORT);
  if (!$OMREPORT) {
    printboth("WARNING: Dell Hardware will not be checked, 'omreport' not installed on all Dell nodes.\n\n");
    msg("Dell Hardware Status","WARNING");
    return;
  }
  my $node,$category,$name,$field,$value;
  my $cmd=q[ omreport storage controller controller=0;
             omreport chassis info; omreport chassis bios;
             omreport chassis memory; omreport chassis processors;
             omreport chassis pwrsupplies; omreport chassis temps;
             omreport chassis volts; omreport chassis batteries;
             omreport chassis | sed -e 's/\(.*\)\s*:\s*\(.*\)/\2:\1/';
           ];
  mapall("--nodes=$nodes",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while(<CMD_PIPE>) {
    print LOG;chomp;
    undef $field; undef $value;

    if (/(\(0\..*\)) ssh/) {
        $node=$1; undef $category; undef $name; next;
    }
    next if (!$node);

    $category=$name=$field=$value="noctl" if (/No controllers found/);
    if ((/^(Controller)s$/) or (/^(Connector)s$/) or (/^(Enclosure)\(s\)$/) or (/^(Virtual Disk)s$/) or
        (/^(Physical Disk)s$/) or (/^(Battery)$/) or (/^(Batteries)$/) or (/^(Main System Chassis)$/) or (/^(.*) Information$/)) {
      $category=$1; $name="0"; next;
    }
    next if (!$category);

    ($field,$value)=split(/\s*:\s*/,$_,2) if (!$value) ;
    $name=$value if ($field  =~ /^ID$|^Index$/);
    next if (!defined $field or !defined $value or !defined $name);

    $DELLSTORAGE{$category}{$node}{$name}{$field}=$value;
    print LOG "Add DELLSTORAGE c:$category n:$node name:$name f:$field v:$value\n";
  }
}
########## End getdellstorage ##########

########## Start checkdellstorage ##########
sub checkdellstorage {
  print LOG "\n\n\n### ".localtime()." ### Starting checkdellstorage\n";
  getdellstorage() if (!%DELLSTORAGE);
  return if (!%DELLSTORAGE);
  getopersys() if (!$OS);

  my $e="";
  my $fail="PASSED";
  my $section,$field;

  # Check for Main System Chassis
  $e="";
  $section="Main System Chassis";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      for my $field (sort keys %{$DELLSTORAGE{$section}{$node}{$name}}) {
        my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
        next if ($field =~ /COMPONENT/ or $value =~ /Ok|Learning/);
        $e.="ERROR:  Node $node $field status is $value\n";
      }
    }
  }

  # Check chassis status
  my @sections=("Memory","Processors");
  @sections=(@sections,"Power Supplies","Temperature Probes","Voltage Probes","Batteries") if(!$PREUPGRADE);
  $field="Status";
  for $section (@sections) {
    for my $node (sort keys %{$DELLSTORAGE{$section}}) {
      for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
        my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
        next if (($section eq "Memory" and $DELLSTORAGE{$section}{$node}{$name}{"Type"} =~ /Not Occupied/) or
                 ($section eq "Processors" and $DELLSTORAGE{$section}{$node}{$name}{"Processor Brand"} =~ /Not Occupied/) or
                 ($section eq "Voltage Probes" and $value =~ /Unknown/) or $value =~ /Ok/i);
        $e.="ERROR:  Node $node $section at index $name $field is $value\n";
      }
    }
  }

  # Compare Installed and Available memory
  $section="Memory";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      my ($installed,$foo) = split(" ",$DELLSTORAGE{$section}{$node}{$name}{"Total Installed Capacity"});
      my ($available,$foo) = split(" ",$DELLSTORAGE{$section}{$node}{$name}{"Total Installed Capacity Available to the OS"});
      if ($installed - $available > 1023) {
        $e.="ERROR: Node $node Memory installed is $installed MB but only $available MB is available to the O/S\n";
      }
    }
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION: Resolve hardware errors detected\n\n");
    msg("Dell Hardware Status","FAILED");
  } else {
    msg("Dell Hardware Status","PASSED");
  }

  # Check for No controllers found
  $e="";
  $section="noctl";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    $e.="ERROR:  Node $node No controllers found\n";
  }
  if ($e) {
      printboth("\n$e");
      printboth("RESOLUTION:  Determine why no controllers are found.  Restarting Dell Open Manage services may fix the problem\n");
      printboth("             Be cautious restarting as it might kill the GSAN.  Take a CP and see KB163733 to quiesce the grid\n\n");
      msg("Dell Controller Status","FAILED");
  }

  # Check for a bad Status or State
  $e="";
  my @sections=("Controller","Virtual Disk","Physical Disk");
  @sections=(@sections,"Connector","Battery","Enclosure") if(!$PREUPGRADE);
  for $section (@sections) {
    for my $node (sort keys %{$DELLSTORAGE{$section}} ) {
     for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
       $field="State"; my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
       if (defined $value and $value !~ /Ready|Online|Charging|Learning/){
         $e.="ERROR:  Node $node $section $name in unexpected $field '$value'\n";
       }
       $field="Status"; $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
       if (defined $value and $value !~ /Ok|Charging|Non-Critical|Learning/){
         $e.="ERROR:  Node $node $section $name in unexpected $field '$value'\n";
       }
       $field="Failure Predicted"; $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
       if (defined $value and $value !~ /No/){
         $e.="ERROR:  Node $node Disk ID $name $field '$value'\n";
       }
     }
    }
  }
  if ($e) {
    printboth "\n$e";
    printboth("RESOLUTION:  ");
    printboth("For Enclosure Backplane issues see KB123834\n             ") if ($e =~ /Enclosures.*State/);
    printboth("Fix the hardware errors\n\n");
    msg("Disk Controller Status","FAILED");
  } else {
    msg("Disk Controller Status","PASSED");
  }

  # Check Patrol Read Mode to be Disabled
  $e="";
  $section="Controller";
  $field="Patrol Read Mode";
  for my $node (sort keys %{$DELLSTORAGE{$section}} ) {
   for my $name (sort keys %{$DELLSTORAGE{$section}{$node}} ) {
     my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
     $e.="ERROR:  Node $node $field is $value.\n" if ($value ne "Disabled");
   }
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION:  Use the following commands to disable patrol read\n");
    printboth("             For all nodes use:  mapall --noerror --all+ --user=root '<commands from below>'\n");
    printboth("             omconfig storage controller action=setpatrolreadmode controller=0 mode=manual\n");
    printboth("             omconfig storage controller action=stoppatrolread controller=0\n");
    printboth("             omconfig storage controller action=setpatrolreadmode controller=0 mode=disable\n\n");
    msg("Dell Patrol Read Disabled","FAILED");
  } else {
    msg("Dell Patrol Read Disabled","PASSED");
  }

  # Check Virtual Disks for Disk Caching to be Disabled
  $e="";
  $section="Virtual Disk";
  $field="Disk Cache Policy";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    my $diskcache="";
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
      $diskcache.=" $name" if ($value ne "Disabled");
    }
    $e.="ERROR:  Node $node Disk Cache Enabled For ID's:$diskcache.\n" if ($diskcache);
  }
  if ($e) {
    printboth("\n$e");
    printboth("ERROR:  Disk caches are enabled\n");
    printboth("RESOLUTION:  Review ETA KB92871\n\n");
    msg("Disk Cache Disabled","FAILED");
  } else {
    msg("Disk Cache Disabled","PASSED");
  }

  # Check Controller Driver
  $e="";
  $section="Controller";
  $field="Driver Version";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
      my $kernel=$NODELIST{"/nodestatuslist/nodestatus/$node/version/kernel"} ;
      if ($value =~ /00\.00\.04\.01-RH1/ 
          and $DELLSTORAGE{$section}{$node}{$name}{"Name"} =~ /PERC 6\/i/i 
          and $kernel !~ /2.6.9-104.ELsmp/ 
          and $NODE_INFO{$node}{os} =~ /redhat/i 
          and $DELLSTORAGE{"Chassis"}{$node}{"0"}{"Chassis Model"} !~ /2950/) {
        $e.="INFO:  Node $node $DELLSTORAGE{$section}{$node}{$name}{'Name'} driver $value is out of date\n";
      }
    }
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION: If node has experienced Ping/No SSH upgrade driver to 00.00.04.29.  See bug 55276\n\n");
    $fail="INFO";
  }
  msg("Disk Controller Driver Version",$fail);

  #### Start Dell Block Update
  # Check Controller Firmware
  $e="";
  $fail="PASSED";
  $section="Controller";
  $field="Firmware Version";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
      if (($value !~ /12.10.2-0004|12.10.4-0001/) and $DELLSTORAGE{$section}{$node}{$name}{"Name"} =~ /PERC H700/i or
          ($value !~ /6.3.3.0002/ and $DELLSTORAGE{$section}{$node}{$name}{"Name"} =~ /PERC 6\/i/i and
           $DELLSTORAGE{"Chassis"}{$node}{"0"}{"Chassis Model"} !~ /2950/)) {
        $e.="INFO:  Node $node $DELLSTORAGE{$section}{$node}{$name}{'Name'} firmware $value is out of date\n";
      }
    }
  }

  # Check BIOS Version
  $section="BIOS";
  $field="Version";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      my $value=$DELLSTORAGE{$section}{$node}{$name}{$field};
      if ($value ne '1.8.2' and $DELLSTORAGE{"Chassis"}{$node}{"0"}{"Chassis Model"} =~ /R510/) {
        $e.="INFO:  NODE $node $DELLSTORAGE{'Chassis'}{$node}{'0'}{'Chassis Model'} BIOS version $value out of date\n";
      }
      if ($value ne '6.0.7' and $DELLSTORAGE{"Chassis"}{$node}{"0"}{"Chassis Model"} =~ /R710/) {
        $e.="INFO:  NODE $node $DELLSTORAGE{'Chassis'}{$node}{'0'}{'Chassis Model'} BIOS version $value out of date\n";
      }
    }
  }
  # Check drive firmware
  $section="Physical Disk";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    my $diskfw="";
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      if ($DELLSTORAGE{$section}{$node}{$name}{"Revision"} =~ /03.00C09|03.00C10/ and
          $DELLSTORAGE{$section}{$node}{$name}{"Product ID"} =~ /WDC WD1002FBYS/) {
        $diskfw.=" $name";
      }
    }
    $e.="ERROR:  Node $node Disks with affected firmware: $diskfw\n" if ($diskfw);
  }

  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION:  Apply Dell Block updates in hotfix 55276.\n\n");
    $fail="FAILED";
  }
  msg("Dell Block Update",$fail);
  #### End Dell Block Update

  #### Start Drive Firmware
  $e="";
  $fail="PASSED";
  $section="Physical Disk";
  $field="Revision";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    my $diskfw="";
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      if ($DELLSTORAGE{$section}{$node}{$name}{$field} =~ /GKAOA9RA|GKAOA9N1|GKAOA74A/ and
          $DELLSTORAGE{$section}{$node}{$name}{"Product ID"} =~ /Hitachi HUA721010KLA330/) {
        $diskfw.=" $name";
      }
    }
    $e.="ERROR:  Node $node Disks with affected firmware: $diskfw\n" if ($diskfw);
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION:  Disk Drive firmware is out of date\n");
    printboth("             See TSE T012511FO in the Avamar Procedure Generator for product type HUA721010KLA330\n\n");
    $fail="FAILED";
  }

  $e="";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    my $diskfw="";
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      if (($DELLSTORAGE{$section}{$node}{$name}{$field} =~ /A4C2/ and
           $DELLSTORAGE{$section}{$node}{$name}{"Product ID"} =~ /HUS153030VLS300/) or
          ($DELLSTORAGE{$section}{$node}{$name}{$field} =~ /HS09/ and
           $DELLSTORAGE{$section}{$node}{$name}{"Product ID"} =~ /ST3300656SS/)) {
        $diskfw.=" $name";
      }
    }
    $e.="ERROR:  Node $node Disks with affected firmware: $diskfw\n" if ($diskfw);
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION:  Disk Drive firmware is out of date\n");
    printboth("             See KB118622 for more information\n\n");
    $fail="FAILED";
  }

  $e="";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    my $diskfw="";
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      if ($DELLSTORAGE{$section}{$node}{$name}{$field} =~ /01.01D0[12]/ and
          $DELLSTORAGE{$section}{$node}{$name}{"Product ID"} =~ /WDC WD2003FYYS/) {
        $diskfw.=" $name";
      }
    }
    $e.="ERROR:  Node $node Disks with affected firmware: $diskfw\n" if ($diskfw);
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION:  Disk Drive firmware is out of date\n");
    printboth("             See KB122437 for more information on bug 37550/35475\n\n");
    $fail="FAILED";
  }

  $e="";
  for my $node (sort keys %{$DELLSTORAGE{$section}}) {
    my $diskfw="";
    for my $name (sort keys %{$DELLSTORAGE{$section}{$node}}) {
      if ($DELLSTORAGE{$section}{$node}{$name}{$field} =~ /0C06/ and
          $DELLSTORAGE{$section}{$node}{$name}{"Product ID"} =~ /WDC WD1002FBYS-18A6B0/) {
        $diskfw.=" $name";
      }
    }
    $e.="ERROR:  Node $node Disks with affected firmware: $diskfw\n" if ($diskfw);
  }
  if ($e) {
    printboth("\n$e");
    printboth("RESOLUTION:  Disk Drive firmware is out of date\n");
    printboth("             See the Avamar Procedure Generator -> Miscellaneous Procedures -> WD 1TD Drive Firmware Update from 0C06\n\n");
    $fail="FAILED";
  }
  msg("Disk Firmware",$fail);
  #### End Disk Firmware

}
########## End checkdellstorage ##########

########## Start upgradepath ##########
sub upgradepath {
  print LOG "\n\n\n### ".localtime()." ### Starting upgradepath\n";

  getinstalledversion() if (!$VERSNUM);
  getdatadomain() if (!$DDRMAINT_VERSION) ;

  # no path from 6.0 to 7.1
  if ( $VERSNUM < 610 and $UPGRADE_VERSION =~ /^7.1/) {
    printboth("ERROR: There is no direct upgrade path from $AVAMARVER to $UPGRADE_VERSION\n");
    printboth("RESOLUTION: See ETA KB 188915\n\n");
    msg("Upgrade Path","FAILED");
    return;
  }

  # no path w/dd from <=6.0 to >=7
  if ( %DD and $VERSNUM<610 and $UPGRADE_VERSION >= '7' ) {
    printboth("ERROR: There is no direct upgrade path from $AVAMARVER to $UPGRADE_VERSION with Data Domain\n");
    printboth("RESOLUTION: See ETA KB 188915\n\n");
    msg("Upgrade Path","FAILED");
    return;
  }

  # no path w/dd from 6.1 to >7.1
  if ( %DD and $AVAMARVER =~ /^6.1/ and $UPGRADE_VERSION >= '7.1' ) {
    printboth("WARNING: There might not be a direct upgrade path from $AVAMARVER to $UPGRADE_VERSION\n");
    printboth("RESOLUTION: See KB articles 188915 and 193637 to determine upgrade path depending on current versions of Avamar and DDOS.\n\n");
    msg("Upgrade Path","WARNING");
    return;
  }

  # recommend not using 7.0.1 unless only opt (v6.0 w/dd)
  if ($UPGRADE_VERSION =~ /7.0.1/ and !(%DD and $AVAMARVER =~ /^6.0/) ) {
    printboth("WARNING: EMC Strongly urges all customers to upgrade to 7.0.2 or later\n");
    printboth("RESOLUTION: Reconsider upgrading to 7.0.2 or later instead of 7.0.1\n\n");
    msg("Upgrade Path","WARNING");
    return;
  }
}
########## End upgradepath ##########

########## Start kernelcnt ##########
sub kernelcnt {
  print LOG "\n\n\n### ".localtime()." ### Starting kernelcnt\n";
  if (!$PREUPGRADE) {
    print LOG "Skipping: only run for preupgrade\n";
    return;
  }
  getconfiginfo() if (!$GOTCONFIGINFO);
  my $nodes=getnodes_os("suse");
  if (!$nodes) {
    print LOG "no suse nodes found\n";
    return;
  }
  my %count;
  my $e="";
  for(grep(/kernel-default/,@RPMS)){
    print LOG "$_\n";
    next if (/extra|devel|utils/);
    ($node,$_)=split();
    if ($nodes =~ /$node/) {
      $count{$node}++
    } else {
      print LOG "not suse OS\n";
    }
  }
  for my $node (keys %count){
    print LOG "Count: $count{$node}\n";
    if ( $count{$node} > 4 ){
      $e.="ERROR: Node $node Too many ($count{$node}) kernel RPMs are installed\n";
    }
  }
  if ($e){
    printboth("${e}RESOLUTION: See KB189741\n\n");
    msg("Kernel RPMs","FAILED");
  }
}
########## End kernelcnt ##########

########## Start paritysolvercheck ##########
sub paritysolvercheck {
  print LOG "\n\n\n### ".localtime()." ### Starting paritysolvercheck\n";
  if ($NODE_COUNT < 3 ) {
    print LOG "no parity\n";
    return;
  }

# paritysolver status: -1=started, 0=ok, 1=error, 2=warn

  my $is_running=`ps -af | grep 'paritysolver\$' |grep -cv grep`;
  print LOG "is_running = $is_running\n";
  my $runtime=0;
  if ( -e "/home/admin/.paritysolver") {
    open(my $fh,"/home/admin/.paritysolver");
    chomp($_=<$fh>);
    my ($status,$time)=split(",");
    $runtime=time - $time;
    print LOG "status:$status time:$time runtime:$runtime\n";
    if ($status <0 ) {
      if ( $is_running and $runtime < 3600 ) {
        printboth("INFO: Paritysolver background process still running. Elapsed seconds: $runtime\n");
        printboth("RESOLUTION:  Wait for paritysolve to finish\n");
        msg("Parity Solver","INFO");
      } else {
        # taking too long
        printboth("ERROR: Background process failed to run paritysolver\n");
        printboth("RESOLUTION:  See KB190401 for more info\n");
        msg("Parity Solver","WARNING");
      }
    } elsif ($status == 0) {
      msg("Parity Solver","PASSED");
    } elsif ($status == 1 ) {
      printboth("ERROR: Paritysolver must be run\n");
      printboth("RESOLUTION:  See KB190401 for more info\n");
      msg("Parity Solver","FAILED");
    }
  }
  # Run or re-run paritysolver as long as its not running
  if ( $is_running == 0 ) {
    # Set first run
    if (! -e "/home/admin/.paritysolver") {
      open($fh,">/home/admin/.paritysolver");
      print $fh "-1,",time,"\n";
      close($fh);
      printboth("INFO: Background process started to run paritysolver\n");
      printboth("RESOLUTION:  Re-run proactive check at least one hour from now or see KB190401 for more info\n");
      msg("Parity Solver","INFO");
    }
    # Start if never run or more than 1 day since last
    if ($runtime==0 or $runtime > 3600*24 ) {
      print LOG ("start background process: nohup $0 --paritysolver &");
      system("nohup $0 --paritysolver >/tmp/paritysolvercheck 2>&1 &");
    }
  } else {
    print LOG ("is_running: ", `ps -af | grep 'paritysolver\$'`);
  }
}
########## End paritysolvercheck ##########

########## Start paritysolver ##########
sub paritysolver {

# NOTE: This is a copy of paritysolver. 
#
# Redirect standard output and error to proactives log file
*STDERR=*LOG;
*STDOUT=*LOG;
open(IN,"avmaint stats --extended|");

######## 
######## Start script here minus interpreter.  
########
########  Comment out use strict;
########  change while(<>) to while(<IN>)
########  change first exitcode=2 on WARN
########  remove exit;



#
# usage: paritysolver.pl <extended stats output>
#
# This script determines whether or not any parity group has one or more
# stripes on the same node.
#
# Version 1.2: fixed issue with parsing node IDs greater than 0.10
#
# Version 1.1: changed parity count check to a warning, prints stripes in question, fixed counting issue
#
# Version 1.0: initial version
#

#use strict;

# parity stripe id => [(node id, backing file location), ...]
my %parityinfo;

# parity stripe id => {parity member id => (node id, backing file location), ...}
my %paritygroups;

my @nodes;

my $exitcode = 0;
my $groupsaffected = 0;
my $stripesaffected = 0;

while (<IN>) {
    my $line = $_;
    next unless $line =~ /^\[/ or $line =~ /^PING\s+node=(0\.[0-9A-F]+)$/;

    push @nodes, $1 if $line =~ /^PING\s+node=(0\.[0-9A-F]+)$/;

    my $nodeid;
    my $stripeid;
    my $filename;
    my $parityid;

    if ($line =~ /node:(0\.[0-9A-F]+).*\s+id:(0\.[0-9A-F]+\-[0-9A-F]+)\s+kind:localparitystripe\s+filename=(.*)\s+linkcount.*/) {
        $nodeid = $1;
        $stripeid = $2;
        $filename = $3;

        $parityinfo{$stripeid} = [$nodeid, $filename];
    } elsif ($line =~ /node:(0\.[0-9A-F]+).*\s+id:(0\.[0-9A-F]+\-[0-9A-F]+)\s+kind:.*\s+filename=(.*?)\s+linkcount.*parity=(0\.[0-9A-F]+\-[0-9A-F]+)\s+.*$/) {
        $nodeid = $1;
        $stripeid = $2;
        $filename = $3;
        $parityid = $4;

        $paritygroups{$parityid}{$stripeid} = [$nodeid, $filename];
    }
}

if (scalar(keys %parityinfo) != scalar(keys %paritygroups)) {
    print "WARN: mismatching parity counts - parityinfo(" . scalar(keys %parityinfo) . ") !=  paritygroups(" . scalar(keys %paritygroups) . ")\n";
    print join("\n", grep { !exists $parityinfo{$_} } sort keys %paritygroups) . "\n"
        if scalar(keys %paritygroups) > scalar(keys %parityinfo);
    print join("\n", grep { !exists $paritygroups{$_} } sort keys %parityinfo) . "\n"
        if scalar(keys %parityinfo) > scalar(keys %paritygroups);
    $exitcode = 2;
}

foreach my $paritystripe (sort keys %parityinfo) {
    next if !exists $paritygroups{$paritystripe};
    my %usednodes;

    $usednodes{$parityinfo{$paritystripe}->[0]}++;

    foreach my $safestripe (sort keys %{$paritygroups{$paritystripe}}) {
        $usednodes{$paritygroups{$paritystripe}{$safestripe}->[0]}++;
    }

    if(grep { $usednodes{$_} > 1 } keys %usednodes) {
        my %paritygroup = %{$paritygroups{$paritystripe}};
        my $printstr = "[" . $parityinfo{$paritystripe}->[0] . ", $paritystripe] => ";

        print "ERROR: one or more stripes in parity group are on the same node\n";
        $printstr .= join ",", map { "[" . $paritygroup{$_}->[0] . ", $_]" } sort keys %paritygroup;
        print "$printstr\n";

        ++$groupsaffected;
        $stripesaffected += grep { $usednodes{$_} > 1 } keys %usednodes;
        $exitcode = 1;
    }
}

print scalar(keys %paritygroups) . " parity groups checked - $groupsaffected parity group(s) affected - $stripesaffected stripe(s) affected\n";


######## 
######## End script here minus exit.
########


  open($fh,">/home/admin/.paritysolver");
  print $fh "$exitcode,",time,"\n";
  close $fh;
  chomp(my $systemid=`avmaint nodelist | grep systemid | head -1`);
  print "Exitcode: $exitcode\n";
  my $details=scalar(keys %paritygroups) . " parity groups checked - $groupsaffected parity group(s) affected - $stripesaffected stripe(s) affected\n";
  sendemail("$systemid paritysolver='$exitcode'",$details);
}
########## Start paritysolver ##########

########## Start checkopenfiles ##########
sub checkopenfiles {
  print LOG "\n\n\n### ".localtime()." ### Starting checkopenfiles\n";
  if (  $VERSNUM<700 ) {
    print LOG "Skipping for version $VERSNUM less than 7.x";
    return;
  }
  my $cmd=q[ sysctl fs.file-max | awk '{print "SYS:"$0}' 
             grep nofile /etc/security/limits.conf | awk ' !/^\s*#/ {print "LIM:"$0}' 
           ];
             # running proc limit: ps h -C gsan | awk '{system("cat /proc/"$1"/limits")}' | awk '/Max open files/ {print "GSAN:"$4}'|head -1
  mapall("--user=root",$cmd);
  open(CMD_PIPE,$TMPFILE);
  my $e="";
  while(<CMD_PIPE>) {
    print LOG $_;chomp;
    $node=$1 if (/(\(0\..*\)) ssh/);
    if (/^SYS:.*=\s*(\d*)/) {
      $e.="ERROR: Node $node sysctl file-max setting of $1 is less than the required 1600000\n" if ($1 < 1600000 );
    } elsif (/^LIM:.*nofile\s+(\d*)/) {
      $e.="ERROR: Node $node /etc/security/limits.conf nofile setting of $1 is less than the required 800000\n" if ($1 < 800000);
#    } elsif (/^GSAN:(\d*)/) {
#      $e.="ERROR: Node $node Running GSAN process open files setting of $1 is less than the required 800000\n" if ($1 < 800000);
    }
  }
  if ($e) {
    printboth("${e}RESOLUTION:  See KB191132 to change settings to required values.\n");
    printboth("             NOTE: Running GSAN process errors require restarting Avamar\n") if ($e =~ /GSAN process/);
    printboth("\n");
    msg("Open File Settings","FAILED");
  } else {
    msg("Open File Settings","PASSED");
  }
}
########## Start checkopenfiles ##########

########## Start osconfig ##########
sub oscheck {
# shellshock 201526
  print LOG "\n\n\n### ".localtime()." ### Starting oscheck\n";
  getavamarver() if (!$AVTAR_VERSION);
  my $cmd=qq[ env x='() { :;}; echo "SS:1"' bash -c "" ] ;
  
  my $msg=($PREUPGRADE) ? "RCM PCA #: RP2014-0004" : "CVE-2014-6271";
  my ($ss)=("")x1;
  mapall("",$cmd);
  open(CMD_PIPE,$TMPFILE);
  while(<CMD_PIPE>) {
    print LOG $_; 
    $node=$1 if (/(\(0\..*\)) ssh/);
    if ( /SS:1/) {
      $ss.="ERROR: Node $node is subject to $msg\n";
    }
  }
  if ($ss) {
    printboth("${ss}RESOLUTION: See Hotfix 202719\n\n");
    msg($msg,"FAILED");
  }

# Leap Second hotfix. If before Jun 30, 2015 23:59 UTC

  getopersys if (!$OS);
  if ($OS !~ /suse/ ) {
    print LOG "Skipped leap second check for o/s $OS\n";
    return;
  }
  my $nodes=getnodes_os("suse");
  if ( $nodes and !$VBA and time < 1435708740 ) {
    mapall("--nodes=$nodes --user=root","atq");
    open(CMD_PIPE,$TMPFILE);
    while(<CMD_PIPE>) {
      print LOG $_; 
      if (/(\(0\..*\)) ssh/) {
        $node=$1;
        # Patched kernel
        next if ( grep(/$node.*2.6.32.59-0.19/,@RPMS));
        $ls{$node}=1;
        next;
      }
      delete $ls{$node} if (/2015-0[67]/);
    }
    my $msg="";
    for (keys %ls) {
      $msg.="ERROR: Node $_ does not have leap second hotfix installed\n";
    }
    if ($msg) {
      printboth("${msg}RESOLUTION: Install Hotfix 229168\n\n");
      msg("Kernel Leap Second","FAILED");
    } else {
      msg("Kernel Leap Second","PASSED");
    }
  }
}
########## End oscheck ##########

########## Start repoempty ##########
sub repoempty {
  print LOG "\n\n\n### ".localtime()." ### Starting repoempty\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  for (@DATA_REPO) {
    my($node,$dir)=split();
    printboth("WARNING: Node $node Directory $dir is not empty. AvInstaller workflow appears to be active\n");
  }
  if (@DATA_REPO) {
    printboth("RESOLUTION: Do not delete any files. Do not place new AVP files into packages Directory.\n            Escalate internally to Remote Proactive Team Leader.\n\n");
    msg("AvInstaller Repository Check","WARNING");
  }
}
########## End repoempty ##########

########## Start checkmessages ##########
sub checkmessages {
  print LOG "\n\n\n### ".localtime()." ### Starting checkmessages\n";
  getconfiginfo() if (!$GOTCONFIGINFO);
  for (@DATA_checkmessages) {
    printboth("ERROR: Node $node reported $msg\n");
  }
  if (@DATA_checkmessages) {
    printboth("RESOLUTION: See KB194320 to increase cache size\n\n");
    msg("ARP Cache Overflow","FAILED");
  }
}
########## End checkmessages ##########

########## Start getmaxrpmver #########
# Pass in regex to match RPMs
sub getmaxrpmver {
#  print LOG "\n\n\n### ".localtime()." ### Starting getmaxrpmver\n";
  my $rpm_regex=shift;
  my $nodeid=shift;
  my $rpm_ver="";
#  print LOG "find rpm $rpm_regex for node $nodeid\n";
  my (@MAX,@VER);
  for (grep /$rpm_regex/, @RPMS){
#     print LOG "RPM: $_\n";
     (my $node,$rpm)=split();
     next if ($node !~ /$nodeid/);
#     print LOG "found rpm $rpm_regex for node $nodeid\n";
     $rpm =~ s/^.*?(\d)/\1/;  # Remove RPM name till first number
#     print LOG "vers=$r\n";
     my @VER=split(/[-\.]/, $rpm);
     my $index=0;
     for (@VER) {
       #print "ndx:$index ver:@VER[$index]  max:@MAX[$index]\n";
       if (@VER[$index] > @MAX[$index]) {
         @MAX=@VER;
         $rpm_ver=$rpm;
#         print LOG "new max = $rpm_ver\n";
         last;
       }
       $index++;
     }
  }
#  print LOG "return=$rpm_ver\n";
  return $rpm_ver;
}
########## End getmaxrpmver #########

########## Start getvba ##########
sub getvba {
  print LOG "\n\n\n### ".localtime()." ### Starting getvba\n";
  if (! -e "/usr/local/avamar/etc/EBR-VERSION") {
    print LOG "Skipping: No VBA version found\n";
    $VBA="";
    return;
  }
  getconfiginfo() if (!$GOTCONFIGINFO);

  $VBA=1;
  # Get latest AvamarVMwareCombined version
  my $results;
  my @MAX;
  my (%VCENTER,%NSR);

  open($fh,"/usr/local/vdr/etc/vdp_version_info");
  while(<$fh>){chomp;
    $VBA_VERSION=$1 if (/nemo-scripts=(\S*)/ and !$VBA_VERSION);
    $VBA_VERSION=$1 if (/ova-upgrade=(\S*)/);
  }
print "start\n";

# NOTE: client=rpmvers. mcs=md5sum.
#  hf=>?  ddos=>compatible data domain version	nsr=> compatible networker version
#  ebr_nw* => rpm version installed
# avnwcomm => bug # seen in avnwcomm --version output.
#  hfavtar => bug # seen in avtar  --verison output
  my %vbaver = (
    "1.1.1.50" =>{  ddos=>"5\.4\.1\.[2-9]|5\.4\.[2-9]|5\.5\..\..", nsr=>"8\.2\.1",
                    rpm =>  { rpm=>"ebr-nw-2.0.1-204", bug=>238060 }, 
                    rpm1 => { rpm=>"ebr-nw-2.0.1-199", bug=>233936 }, 
                    rpm2 => { rpm=>"ebr-nw-2.0.1-203", bug=>238254 }
                 },
    "1.1.1.46" => {  hf=>"231042", ddos=>"5\.4\.1\.[2-9]|5\.4\.[2-9]|5\.5\..\..", nsr=>"8\.2\.1",
                     rpm => {rpm=>"flr-nw-app-2.0.1-194", bug=>231480 }
                  }, 
    "1.1.1.41" => {  ddos=>"5\.4\.1\.[2-9]|5\.4\.[2-9]|5\.5\..\..", nsr=>"8\.2\.1.*671", }, 
    "1.1.0.149" => { ddos=>"5\.4\.1\.[2-9]|5\.4\.[2-9]|5\.5\..\..", nsr=>"8\.2\.", 
                     rpm => {rpm=>"ebr-nw-2.0.0-318", bug=>225771 },
                     rpm2=> {rpm=>"ebr-nw-2.0.0-324", bug=>232801 },
                     rpm1=> {rpm=>"flr-nw-app-2.0.0-322", bug=>231492 }
                   },
    "1.1.0.141" => { ddos=>"5\.4\.1\.[2-9]|5\.5\..\..", nsr=>"8\.2\.", },
    "1.0.3.6" => {   ddos=>"5\.3\.0\.[6-9]|5\.3\.[1-9]|5\.4\.1\.[2-9]|5\.4\.[2-9]|5\.5\.0\.", nsr=>"8\.1\.3",
                     rpm => { rpm=>"ebr-nw-1.3.301", bug=>235225 }
                 },
    "1.0.2.16" => {  ddos=>"5\.3\.0\.[6-9]|5\.3\.[1-9]|5\.4\.1\.[2-9]|5\.4\.[2-9]", nsr=>"8\.1\.2",
                     avnwcomm=>"231356", hfmcs=>"222752",	mcs=>"481e3a1cb7d0fd51b695e951c1d1a547",
                     rpm => { rpm=>"AvamarVMwareCombined-linux-sles11-x86_64-7.0.162-12", bug=>222268 }
                 }, 
    "1.0.1.9" => {   gsan=>"7.0.61-5",
			avnwcomm=>"196356", ddos=>"5\.3\.0\.[6-9]|5\.3\.[1-9]|5\.4\.1\.[2-9]|5\.4\.[2-9]", nsr=>"8\.1\.1",
			avtar=>"7.0.161-16", hfavtar=>"201117", 
			client=>"7.0.161-18", hfclient=>"222267",
			hfmcs=>"199300", mcs=>"aeb0f7798d18d3558e13337403656712"
                 },
    "1.0.0.199" => { gsan=>"7.0.60-11", ddos=>"5\.3\.0\.[6-9]|5\.3\.[1-9]|5\.4\.1\.[2-9]|5\.4\.[2-9]"  },
    "1.0.0.180" => {  gsan=>"7.0.60-7", ddos=>"5\.3\.0\.[6-9]|5\.3\.[1-9]|5\.4\.1\.[2-9]|5\.4\.[2-9]"  }
  );


  print LOG "\n\nVBA VERSION '$VBA_VERSION'\n";
  if ($vbaver{$VBA_VERSION}{ddos}) {
    msg("VBA Version",$VBA_VERSION);

    my $error=0;
    # Check for recalled version
    if ($VBA_VERSION eq "1.1.1.41") {
        printboth("ERROR:  VBA Version $VBA_VERSION has been recalled\n");
        printboth("RESOLUTION:  Upgrade to a newer version\n\n");
        msg("VBA Recall","FAILED");
        $error=1;
    }

    # Check for hotfixes by RPM installed
    for (grep(/^rpm/, keys %{$vbaver{$VBA_VERSION}}) ) {
      print LOG "HOT FIX RPM: $vbaver{$VBA_VERSION}{$_}{rpm} $vbaver{$VBA_VERSION}{$_}{bug}\n";
      if (!grep(/$vbaver{$VBA_VERSION}{$_}{rpm}/, @RPMS)) {
        printboth("WARNING:  Hot fix $vbaver{$VBA_VERSION}{$_}{bug} is available for $VBA_VERSION\n");
        printboth("RESOLUTION:  See hotfix information to see if this grid requires an update\n\n");
        $error=1
      } else { 
        print LOG "found rpm matching: $vbaver{$VBA_VERSION}{$_}{rpm}\n";
      }
    }

    # Check for avnwcomm hotfixes
    if ( $vbaver{$VBA_VERSION}{avnwcomm} ){
      open($fh,"/usr/local/avamarclient/bin/avnwcomm --version");
      my $hf;
      while(<$fh>){ $hf=1 if (/$vbaver{$VBA_VERSION}{avnwcomm}/); print LOG $_; }
      if (!$hf){
        printboth("WARNING:  avnwcomm hotfix $vbaver{$VBA_VERSION}{avnwcomm} is available for $VBA_VERSION\n");
        printboth("RESOLUTION:  See hotfix information to see if this grid requires an update\n\n");
        msg("VBA avnwcomm updates","FAILED");
        $error=1;
      }
    }

    # Check for avtar hotfixes
    print LOG "avtar: $vbaver{$VBA_VERSION}{avtar} and $AVTAR_VERSION ne $vbaver{$VBA_VERSION}{avtar}\n";
    if ( $vbaver{$VBA_VERSION}{avtar} and $AVTAR_VERSION ne $vbaver{$VBA_VERSION}{avtar} ){
        printboth("WARNING:  avtar hotfix $vbaver{$VBA_VERSION}{hfavtar} is available for $VBA_VERSION\n");
        printboth("RESOLUTION:  See hotfix information to see if this grid requires an update\n\n");
        msg("VBA avtar updates","FAILED");
        $error=1;
    }

    # Check for client hotfixes
    print LOG "client: $vbaver{$VBA_VERSION}{client} and $vbaver{$VBA_VERSION}{client} ne $VBA_RPM\n";
    if ( $vbaver{$VBA_VERSION}{client} and $vbaver{$VBA_VERSION}{client} ne $VBA_RPM ){
      printboth("WARNING:  Client Hotfix $vbaver{$VBA_VERSION}{hfclient} is available for $VBA_VERSION\n");
      printboth("RESOLUTION:  See hotfix information to see if this grid requires an update\n\n");
      msg("VBA client updates","FAILED");
      $error=1;
    }

    # Check for mcs hotfixes
    print LOG "mcs: $vbaver{$VBA_VERSION}{mcs} and $vbaver{$VBA_VERSION}{mcs} ne $MCS_MD5SUM\n";
    if ( $vbaver{$VBA_VERSION}{mcs} and $vbaver{$VBA_VERSION}{mcs} ne $MCS_MD5SUM ){
      printboth("WARNING:  MCS Hotfix $vbaver{$VBA_VERSION}{hfmcs} is available for $VBA_VERSION\n");
      printboth("RESOLUTION:  See hotfix information to see if this grid requires an update\n\n");
      msg("VBA MCS updates","FAILED");
      $error=1;
    }

   # Check for 231042 hotfix
    if ( $vbaver{$VBA_VERSION}{hf} == 231042 and !grep(/2.6.32.59-0.17.1.8297.0.PTF.924392/,@RPMS) ){
      printboth("ERROR: Hotfix $vbaver{$VBA_VERSION}{hf} is required for $VBA_VERSION\n");
      printboth("RESOLUTION:  See hotfix for more information\n\n");
      msg("VBA updates","FAILED");
      $error=1;
    }

    # Check for iragent
    openmcdb() if (!$dbh);
    my $sth = $dbh->prepare("select cid from v_clients where full_domain_name='/clients/iragent' and enabled");
    $sth->execute;
    $R=$sth->fetchrow_hashref;
    $results=qx{sudo  cat /usr/local/avamar/var/client/cid.bin | sed -n '2p'};
    chomp($results);
    print LOG "mcscid=$R->{cid}  cid.out=$results\n";
    if ($R->{cid} ne $results) {
      printboth("ERROR: There appears to be a problem with /clients/iragent.\nIt doesn't exist or there is a CID mismatch MCS CID is '$R->{cid}' cid.out is '$results'\n");
      printboth("RESOLUTION:  See KB198220 to further troubleshoot this problem.\n\n");
     msg("VBA /clients/iragent","FAILED") ;
    }
 
     msg("VBA updates","PASSED") if (!$error);
  } else {
    print LOG "Unknown VBA version\n";
# unknown version?
  }

### Get Networker Info
  open(my $fh,"/usr/local/vdr/etc/vcenterinfo.cfg");
  while(<$fh>){chomp;
    print LOG "$_\n";
    my ($fld,$val)=split("=");
    $VCENTER{$fld}=$val;
  }
  if ($VCENTER{"networker-hostname"}){
    print LOG qq[Get nsr version from $VCENTER{"networker-hostname"}\n];
    open (my $fh,qq[ echo "print type:NSR" | nsradmin -s $VCENTER{"networker-hostname"} -i - 2>&1 |]);
    while(<$fh>){chomp; 
      print LOG "$_\n";
      my($key,$value)=$_=~m{\s*(.*):\s(.*);};
      $NSR{$key}=$value;
    }
  }
  msg("NetWorker Host:",$VCENTER{"networker-hostname"}." ".$NSR{"version"});
  if (!$NSR{"version"}) {
    printboth("ERROR: Unable to determine NetWorker version\n");
    printboth("RESOLUTION: Verify NetWorker is running and reachable from this host\n\n");
    msg("NetWorker Connectivity:","FAILED");
  } else {
    msg("NetWorker Connectivity:","PASSED");
    if ($vbaver{$VBA_VERSION}{nsr} and $NSR{"version"} !~ /$vbaver{$VBA_VERSION}{nsr}/){
      msg("NetWorker Connectivity:","PASSED");
      print LOG "regex: $vbaver{$VBA_VERSION}{nsr}\n";
      printboth("ERROR: NetWorker version $NSR{version} and VBA Version $vbaver{$VBA_VERSION}{appver} may not be compatible\n");
      printboth("RESOLUTION: Consult release information to verify these versions are compabitble\n\n");
      msg("VBA/NetWorker Version:","FAILED");
    } else {
      msg("VBA/NetWorker Version:","PASSED");
    }
  }

  # Check Local NetWorker Major version
  my $local=qx{strings /usr/sbin/nsrexecd | awk -F: '/#.*Release/ {split(\$2,V,".");printf "%d.%d", V[1], V[2]}'};
  print LOG "local=$local remote=$NSR{'version'}\n";
  if ( $NSR{"version"} !~ / $local/) {
    printboth("WARNING: Local NetWorker version $local is different than the NetWorker server $NSR{'version'}\n");
    printboth("RESOLUTION:  Local and remote NetWorker major version numbers should be the same\n\n");
    msg("NetWorker Local Version","FAILED");
  }

  # Check nsrexecd running
  if ( qx{ps -ae | grep -c nsrexecd} != 1 ){
    printboth("ERROR: nsrexecd is not running\n");
    printboth("RESOLUTION: Determine why it is not running\n\n");
    msg("Networker nsrexecd","FAILED");
  }

  # Data Domain Compatibility
  getdatadomain() if (!$DDRMAINT_VERSION) ;
  my $e="";
  foreach (@DD_INDEX) {
    my $ddver=$DD{"/avamar/datadomain/ddrconfig/$_/ddos-version"};
    print LOG qq[ddr index: $_  version $ddver\n];
    if ( $vbaver{$VBA_VERSION}{ddos} and $ddver !~ /$vbaver{$VBA_VERSION}{ddos}/ ) {
      my $ddname=$DD{"/avamar/datadomain/ddrconfig/$_/hostname"};
      $e.=("ERROR: Data Domain $ddname version $ddver and VBA Version $vbaver{$VBA_VERSION}{appver} may not be compatible\n");
    }
  }
  if ($e){
    printboth($e."RESOLUTION: Consult release information to verify these versions are compabitble\n\n");
    msg("VBA/Data Domain Version:","FAILED");
  } else {
    msg("VBA/Data Domain Version:","PASSED");
  }

  # Get EMWEBAPP status
  $results=qx{emwebapp.sh --test};
  chomp($results);
  if ($results =~ /status: (.*)/) {
    if ($1 eq "up" ) {
      msg("EM Web App","PASSED");
    } else {
      printboth("ERROR:  Enterprise Manager Web application status is '$1'\n");
      printboth("RESOLUTION: Enable webapp?\n\n");
      msg("EM Web App","FAILED");
    }
  }
}
########## End getvba ##########

########## Start chkspace ##########
sub chkspace {
  print LOG "\n\n\n### ".localtime()." ### Starting chkspace\n";
  my $result=qx{df | awk '/space/ && \$5>90 {print \$5}'};
  chomp($result);
  if ($result) { 
    printboth("ERROR:  /space partition is at $result used.\n");
    printboth("RESOLUTION:   See KB172570 for more information\n\n");
    msg("VBA /space","FAILED");
  } else {
    msg("VBA /space","PASSED");
  }
}
########## End chkspace ##########

########## Start chkproxy ##########
sub chkproxy {
  print LOG "\n\n\n### ".localtime()." ### Starting chkproxy\n";
  openmcdb() if (!$dbh);
  my $sql = qq[ select descr,checkin_ms/1000 as checkin, agent_version, checkin_ms/1000<EXTRACT(EPOCH FROM NOW()-INTERVAL '1 minutes') as overdue 
      from clients where client_type='VPROXY_REGULAR' ];
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  my ($pe,$pver,$pve);
  while ($R=$sth->fetchrow_hashref()){
    if ($R->{overdue} eq "t") {
      my ($dd,$mm,$yr) = (localtime($R->{checkin}))[3,4,5];
      my $date=sprintf("%04d-%02d-%02d",$yr+1900,$mm+1,$dd);
      $pe.="WARNING: proxy $R->{descr} has not checked in since $date\n";
    }
    if (!$pver) { 
      $pver=$R->{agent_version};
    } elsif ( $pver ne $R->{agent_version}) {
      $pve.="WARNING: Proxy $R->{descr} version $R->{agent_version} doesn't match other proxy versions $pver\n";
    }
  }
  if (!$pe) {
    msg("VBA Proxies","PASSED");
  } else {
    printboth($pe."RESOLUTION: Verify proxy status.  Disable to remove this message. See KB199021 for more info\n\n");
    msg("VBA Proxies","FAILED");
  }
  if ($pve){
    printboth($pve."RESOLUTION: Verify all proxy versions\n\n");
    msg("VBA Proxy Versions","WARNING");
  }
}
########## End chkproxy ##########

########## Start servicemode ##########
sub servicemode {
  print LOG "\n\n\n### ".localtime()." ### Starting servicemode\n";
  my $hours=shift;
  if ($hours) {
    print LOG  "send message hours=$hours\n";
    $hours=3;
    if (system(qq[avmaint infomessage --errcode=1 --errkind=error --ava "ServiceMode_$hours"]) != 0 ) {
      printboth("ERROR: Unknown error running avmaint commands (err: $!)\n");
      printboth("RESOLUTION:  Try running command manually: avmaint infomessage --errcode=1 --errkind=error --ava 'ServiceMode_$hours'\n\n");
    } else {
      system("(echo $hours > /home/admin/.servicemode; sleep 1m; rm /home/admin/.servicemode)2>/dev/null 2>&1 &");
      print LOG "started background command to removed servicemode file in $hours hours\n";
      print("\nService Mode enabled for $hours hours\n\n");
    }
  } elsif (my $time=(stat "/home/admin/.servicemode")[9]){
    chomp(my $hours=`cat /home/admin/.servicemode`);
    my ($sec, $min, $hour, $day,$month,$year,$foo) = localtime($time);
    msg("Service Mode",sprintf "Enabled %02d/%02d/%4d at %02d:%02d for $hours hours",$month+1,$day,$year+1900,$hour,$min);
  }
}
########## End servicemode ##########

########## Start upgdpath ##########
sub upgdpath {
  print LOG "\n\n\n### ".localtime()." ### Starting upgdpath\n";
  if (!$PREUPGRADE) {
    print LOG "Not upgrading\n";
    return
  }
  getdatadomain() if (!$DDRMAINT_VERSION) ;
  getinstalledversion() if (!$AVAMARVER);

  print LOG "VERSNUM=$VERSNUM AVAMARVER=$AVAMARVER PREUPGRADE=$UPGRADE_VERSION\n";
  if ($VERSNUM <620  and $UPGRADE_VERSION =~ /^7\.2/) {
    printboth("ERROR: There is no direct upgrade from $AVAMARVER to $UPGRADE_VERSION");
    printboth("RESOLUTION: You Must upgrade to 7.1.2 as an intermediate step before upgrading to 7.2");
    msg("Upgrade Path:","FAILED");
    return
  }
  if ($AVAMARVER =~ /^7.0/ and $UPGRADE_VERSION =~ /^7\.2/ and $DDCNT>0 ) {
    printboth("ERROR: There is no direct upgrade from $AVAMARVER to $UPGRADE_VERSION when Data Domain is present");
    printboth("RESOLUTION: You must upgrade to 7.1.2 first so you can then upgrade your DDOS to a minimum of 5.5.0.9 before upgrading to 7.2.");
    msg("Upgrade Path","FAILED");
    return
  }
  msg("Upgrade Path","PASSED");
}

########## Start upgdpath ##########


########## Start dtltsecurity ##########
sub dtltsecurity {
  print LOG "\n\n\n### ".localtime()." ### Starting dtltsecurity\n";
  getavamarver() if (!$DATANODEVERSION);
  getopersys() if (!$OS);
  my %dtltwar = ( "7.1.1" => { rhelmd5=>"40404ac160002d83733db2bae2e3e901", slesmd5=>"92fa487ef5ec1b617894127620068b7c", bug=>235341 },
                  "7.0.2" => { rhelmd5=>"ce1259a51494cdbdc1ade7d212f8ccf9", slesmd5=>"ce1259a51494cdbdc1ade7d212f8ccf9", bug=>239448 },
                  "7.0.3" => { rhelmd5=>"c4c56d76b63a4ec4b910f2b66d05c691", slesmd5=>"c4c56d76b63a4ec4b910f2b66d05c691", bug=>235342 }
                );
  if ($PREUPGRADE) {
    print LOG "skip for preupgrade\n";
    return
  }
  if (! -e "/usr/local/avamar/lib/dtlt.war") {
    print LOG "skip dtlt.war doesnt exist\n";
    return
  }
  my ($gsan_maj,$foo)=split("-",$DATANODEVERSION);
  $bugmd5=($NODE_INFO{"(0.s)"}{os} =~ /suse/i) ? $dtltwar{$gsan_maj}{slesmd5} : $dtltwar{$gsan_maj}{rhelmd5};
  print LOG "gsanmaj: $gsan_maj  bugmd5='$bugmd5'  os=$NODE_INFO{$node}{os}\n";
  if ( $bugmd5 ) {
    chomp(my $dtltmd5=`md5sum /usr/local/avamar/lib/dtlt.war`);
    $dtltmd5 =~ s/ .*//;
    print LOG "md5 dtlt.war $dtltmd5\n";
    if ($dtltmd5 ne $bugmd5) {
      printboth("ERROR:  This grid is vulnerable to bug $dtltwar{$gsan_maj}{bug}\n");
      printboth("RESOLUTION:  See hot fix $dtltwar{$gsan_maj}{bug} for more information\n\n");
      msg("DTLT Security","FAILED");
    }
  }
}
########## End dtltsecurity ##########

########## Start tomcatdir ##########
sub tomcatdir {
  print LOG "\n\n\n### ".localtime()." ### Starting tomcatdir\n";
  if (-d "/usr/local/jakarta-tomcat-5.5.9" and $UPGRADE_VERSION =~ /7\.1\.[012]/) {
    printboth("WARNING:  Directory /usr/local/jakarta-tomcat-5.5.9/ exists\n");
    printboth("RESOLUTION:  See escalation 23513/bug 232101 for more info\n\n");
    msg("Jakarta Tomcat Directory","FAILED");
  }
}
########## End tomcatdir ##########
#
#
#

#

#

#

#

#
#
########## Start capacity.pl ##########
sub capacity_info {

#!/usr/bin/perl
#
#  $Id: //AV/main/pss/support/proactive_check.pl#90 $
#
# 3.5 - 9/16/14 fixed top change rate clients comparing dd&ava new to ava total.
# 3.4 - fixed div/0 err if no avamar
# 3.3 - fixed <="6" to <"7" on version
# 3.2 - --ava was showing ddr top clients
# 3.1 - dont allow to run as root. the version check doesnt work
# 3.0 - fix bug from 2.9. repl DD info only available on 7.0+
# 2.9 - identify repl target DD backups
# 2.8 - identify repl DD backups, print note about DDR new
# 2.7 - fixed problem identifying DDR clients, replication source, net, --domain, # of files
# 2.6 - fixed problem identifying version
# 2.5 - rewrite using perl, added sql injection rejection, start, end, gb, norepl, ava, ddr flags.

use Switch;

  my $LIMIT=5;
  my $IN_DAYS=14;

  my $SIZE=1024*1024;
  my $SIZEID="mb";
  my ($INCL_DDR_HOSTNAME,$INCL_REPL_DDR,$START,$END,$DATEWHERE);
  my (%CLI,%SENT,$DDR_TOTAL_FILES,%FILES,%dates);
  if ( $> == 0 ) {
    print "This program cannot be run as root.  Please change to the 'admin' user.\n";
    exit 1;
  }

  my @gsan=grep(/^\s*version:/, `gsan --version`);
  (my $VERSION=$gsan[0]) =~ s/^\s*version:\s*//;
  if ($VERSION>"5" or !$VERSION) {
    $INCL_DDR_HOSTNAME=", ddr_hostname";
    $INCL_REPL_DDR=($VERSION>="7" or !$VERSION) ? ", b.ddr_hostname" : ",''" ;
  }

  my $BACKUP_TYPES="1,2,12";
  my($AVAMAR_ONLY,$DDR_ONLY,$INCL_DDR,$NO_REPL, $DOMAIN, $CLIENT, $GRAND_TOTAL_ADDED, $GRAND_TOTAL_FILES);
  my $PROG = "capacity.sh v3.5";

# Open Database
  openmcdb() if (!$dbh);

# Arguments
print LOG "capacity args\n";
  foreach(@ARGV) {
    print LOG "capacity args: $_\n";
    if($_ !~ /^--([^=]+)=?(.*)$/) {
      print STDERR "Invalid command line argument: $_\n";
      exit;
    }
    my $arg = $1;
    my $value = $2;
    switch ($arg) {
      case /ca|de/ {my $foo=bar}
      case /^h/   { capHelp(1); exit 0;} #help
      case /^v/     { print "$PROG\n"; exit 0; } #version
      case /^da/      { $IN_DAYS=$value; } # days
      case /^t/       { $LIMIT=$value; } #top
      case /^ava/      { $AVAMAR_ONLY=1;} #avamar
      case /^ddr/      { $DDR_ONLY=1; } #ddr
      case /^norepl/   { $BACKUP_TYPES="1,2"; } #norepl
      case /^cl/   { $CLIENT=" and client_name like ".$dbh->quote("%$value%"); } #client
      case /^do/   { $DOMAIN=" and dpn_domain like ".$dbh->quote("%$value%"); } #domain
      case /^gb/       { $SIZE=1024*1024*1024; $SIZEID="gb";} #gb
      case /^s/       { chomp($START=`date --date="$value" '+%Y-%m-%d'`); if (!$START) {print "Bad Date\n"; exit 1};; } #start
      case /^e/       { chomp($END=`date --date="$value" '+%Y-%m-%d'`); if (!$END) {print "Bad Date\n"; exit 1};; } #end
      else            { print "Invalid Command line: --$arg\nTry --help\n"; exit; }
    }
  }
print LOG "end capacity args\n";



  if ($START) {
    $DATEWHERE=" started_ts >= '$START' ";
    $DATEWHERE.=" and started_ts <= '$END' " if ($END);
  } else {
    $DATEWHERE=" (started_ts + INTERVAL '$IN_DAYS DAY') >= date(NOW()) ";
  }

  my $SQL=qq[ select date(started_ts) as started_ts, bytes_modified_sent, bytes_scanned, num_mod_files,
               dpn_domain||'/'||client_name as client_name, num_of_files,server,'' as backup_type $INCL_DDR_HOSTNAME
              from activities
              where <date>
                and type in ($BACKUP_TYPES)
                and bytes_scanned>0 and bytes_modified_sent>=0
                $CLIENT $DOMAIN
              UNION
                select date(a.started_ts) as started_ts, a.bytes_modified_sent, a.bytes_scanned, a.num_mod_files,
                  a.dpn_domain||'/'||a.client_name as client_name, a.num_of_files, '', 'REPL' as backup_type  $INCL_REPL_DDR
                from repl_activities a
                join v_repl_backups b on a.cid=b.cid and a.wid=b.wid
                where <date>
                and a.type in ($BACKUP_TYPES)
                and a.bytes_scanned>0 and a.bytes_modified_sent>=0
                $CLIENT $DOMAIN
             ];

# Run Capacity Report
  *OUTPUT=*STDOUT;
  my $PRINT="yes";
  my $ddr_repl_msg;
  get_capacity_info($DATEWHERE,$IN_DAYS);
  $PRINT="";
  my  $n=($IN_DAYS<30) ? 30 : $IN_DAYS+30;
  get_capacity_info("(started_ts + INTERVAL '$n DAY') >= date(NOW())",$n);
  $n+=30;
  get_capacity_info("(started_ts + INTERVAL '$n DAY') >= date(NOW())",$n);

  print $ddr_repl_msg if ($ddr_repl_msg);
#
  $LIMIT=10 if (!$LIMIT);
  big_clients();
  client_files();
  exit 0;


########## Start sub capHelp() ##########
# Help/Usage sub routine
sub capHelp {
    print <<"xxEndHelpxx";

$PROG

This will print information regarding the amount of new data being added to the grid and amount of data being removed by garbage collection.
If there are backups going to data domain additional columns will be added to show how much data is going to data domain and how much to avamar.
The amount scanned and change rate will include both Avamar and Data Domain data.  Removed and Net are always just Avamar data.
You can use the --avamar or -ddr flags so that the Scanned and Rate columns will only reflect Avamar or Data Domain information.


--version       Display the program version
--help          Display the help screen
--days=n        Limit data to backups in the past "n" days. Defaults to 14
--client=x      Limit data to backups with clients that contain "x"
--domain=x      Limit data to backups in domains that contain "x"
--avamar        Limit data to backups with Avamar as the target
--ddr           Limit data to backups with Data Domain as the target
--norepl        Do not include replication backups
--gb            Report in GB instead of MB
--top=n         Limit large client list to "n".  Default 5
--start=x       Start report from date mm/dd/yy
--end=x         End report on date mm/dd/yy


xxEndHelpxx
}

########## End of sub capHelp() ##########



########## Start capacity_info ########
sub get_capacity_info {
  $DATEWHERE=shift;
  $IN_DAYS=shift;
  my (%dates,%gcinfo,%buinfo,$sql,$sth);

# GCINFO
  (my $tmp=$DATEWHERE) =~ s/started_ts/start_time/g;
  $sql = qq[ select start_time, elapsed_time, result, bytes_recovered, passes
        from v_gcstatus
        where $tmp
        ];

  $sth = $dbh->prepare($sql);
  $sth->execute;

  while ( my @row = $sth->fetchrow_array() ) {
    my ($start,$time)=split(" ",$row[0]);
      $dates{$start}=$start;
      $gcinfo{$start}=[ @row ];
  }
  $sth->finish;

# Backup and Destination Replication Info
  ($sql=$SQL) =~ s/<date>/$DATEWHERE/g;
  $sth = $dbh->prepare($sql);
  $sth->execute;

#date(started_ts) as started_ts, bytes_modified_sent, bytes_scanned, num_mod_files, dpn_domain||/||client_name as client_name, num_of_files $INCL_DDR_HOSTNAME

  while ( my $R = $sth->fetchrow_hashref() ) {
    my $ddr=($R->{ddr_hostname}) ? 1 : 0;
    if ($R->{backup_type} eq "REPL" and $VERSION<"7") {
      $ddr_repl_msg="\nNOTE:  In this version of Avamar replication data cannot be identified as Avamar or Data Domain.\n";
      $ddr_repl_msg.="       All replication data will end up under Avamar New.\n";
    }
    if ($PRINT) {
      if ($R->{ddr_hostname}) {
        $DDR_TOTAL_FILES+=$R->{num_mod_files};
        $FILES{$R->{client_name}} += $R->{num_mod_files};
      }
      $SENT{$R->{client_name}} += $R->{bytes_modified_sent};
      $CLI{$R->{client_name}}{scan} += $R->{bytes_scanned};
      $CLI{$R->{client_name}}{totfiles} += $R->{num_of_files};
      $CLI{$R->{client_name}}{ddr} = $R->{ddr_hostname};

    }
    $buinfo{$R->{started_ts}}{totsent}+= $R->{bytes_modified_sent};
    $buinfo{$R->{started_ts}}{totscan}+= $R->{bytes_scanned} ;
    $buinfo{$R->{started_ts}}{totcnt}+= 1;
    if (!$ddr) {
      $buinfo{$R->{started_ts}}{sent} += $R->{bytes_modified_sent};
      $buinfo{$R->{started_ts}}{scan} += $R->{bytes_scanned} ;
      $buinfo{$R->{started_ts}}{cnt} += 1;
      $dates{$R->{started_ts}}=$R->{started_ts};
    } else {
      $buinfo{$R->{started_ts}}{ddrsent} += $R->{bytes_modified_sent};
      $buinfo{$R->{started_ts}}{ddrscan} += $R->{bytes_scanned} ;
      $buinfo{$R->{started_ts}}{ddrcnt} += 1;
      $INCL_DDR=1;
      $dates{$R->{started_ts}}=$R->{started_ts};
    }
  }


# Print headings
 if ($PRINT) {
  my $e="==========";
  printf ("\n%-10s ","  DATE");
  printf OUTPUT ("%10s    %4s ","AVAMAR NEW","#BU") if (!$DDR_ONLY) ;
  printf OUTPUT ("%10s    %4s ","DDR NEW","#BU") if (!$AVAMAR_ONLY and $INCL_DDR) ;
  printf OUTPUT ("%10s    ","SCANNED");
  printf OUTPUT ("%10s    %5s %4s %10s    ","REMOVED","MINS","PASS","AVAMAR NET") if (!$DDR_ONLY);
  printf OUTPUT ("%10s\n","CHG RATE");

  printf OUTPUT ("%10s ",$e);
  printf OUTPUT ("%10s=== %4s ",$e,"====") if (!$DDR_ONLY) ;
  printf OUTPUT ("%10s=== %4s ",$e,"====") if (!$AVAMAR_ONLY and $INCL_DDR) ;
  printf OUTPUT ("%10s=== ",$e);
  printf OUTPUT ("%10s=== %5s %4s %10s=== ",$e,"====","====",$e) if (!$DDR_ONLY);
  printf OUTPUT ("%10s\n",$e);
 }
# Print Detail Lines
  my $cnt=0;
  my($array,$buchg,$tbuscan,$tgcrecovered,$tbunew,$tgcelap,$date);
  my ($gcstart,$gcelap,$gcresult,$gcrecovered,$gcpass)=("");
  my ($gt_totsent, $gt_totscan, $gt_ddrsent, $gt_ddrcnt, $gt_sent, $gt_cnt, $gt_gcrecovered, $gt_gcelap, $gt_totcnt,$gt_gcpass)=(0);
  foreach $date (sort keys %dates ) {
    my $array = $gcinfo{$date};
    ($gcstart,$gcelap,$gcresult,$gcrecovered,$gcpass)=@$array;
    $gcrecovered*=-1;
    my $totsent=$buinfo{$date}{totsent};
    my $totscan=$buinfo{$date}{totscan};

    if ($AVAMAR_ONLY) {
       $totsent=$buinfo{$date}{sent};
       $totscan=$buinfo{$date}{scan};
    }

    if ($DDR_ONLY) {
       $totsent=$buinfo{$date}{ddrsent};
       $totscan=$buinfo{$date}{ddrscan};
    }
    my $pchange  = ($totscan==0) ? "       N/A" : sprintf("%9.2f%",$totsent/$totscan*100) ;
    if ($PRINT) {
      printf ("%10s ",$date);
      printf OUTPUT ("%10d $SIZEID %4d ",$buinfo{$date}{sent}/$SIZE,$buinfo{$date}{cnt}) if (!$DDR_ONLY) ;
      printf OUTPUT ("%10d $SIZEID %4d ",$buinfo{$date}{ddrsent}/$SIZE,$buinfo{$date}{ddrcnt}) if (!$AVAMAR_ONLY and $INCL_DDR) ;
      printf OUTPUT ("%10d $SIZEID ", $totscan / $SIZE );
      printf OUTPUT ("%10d $SIZEID %5d %4d %10d $SIZEID ",$gcrecovered/$SIZE, $gcelap/60, $gcpass, ($buinfo{$date}{sent} + $gcrecovered)/$SIZE) if (!$DDR_ONLY);
      printf OUTPUT ("%10s\n", $pchange);
    }
    $gt_totsent += $totsent;
    $gt_totscan += $totscan;
    $gt_ddrsent += $buinfo{$date}{ddrsent};
    $gt_ddrcnt  += $buinfo{$date}{ddrcnt};
    $gt_sent += $buinfo{$date}{sent} ;
    $gt_cnt  += $buinfo{$date}{cnt} ;
    $gt_gcrecovered += $gcrecovered;
    $gt_gcelap += $gcelap;
    $gt_totcnt++;
    $gt_gcpass+=$gcpass;
  }
 if ($PRINT) {
  printf ("===================================");
  printf OUTPUT ("===================") if (!$DDR_ONLY) ;
  printf OUTPUT ("===================") if (!$AVAMAR_ONLY and $INCL_DDR) ;
  printf OUTPUT ("=======================================") if (!$DDR_ONLY);
  printf OUTPUT ("\n");
  $GRAND_TOTAL_ADDED=0;
  $GRAND_TOTAL_ADDED+=$gt_sent if (!$DDR_ONLY) ;
  $GRAND_TOTAL_ADDED+=$gt_ddrsent if (!$AVAMAR_ONLY) ;
 }
  printf ("%3d DAY AVG",$IN_DAYS);
  printf OUTPUT ("%10d $SIZEID %4d ",$gt_sent/$SIZE/$gt_totcnt,$gt_cnt/$gt_totcnt) if (!$DDR_ONLY) ;
  printf OUTPUT ("%10d $SIZEID %4d ",$gt_ddrsent/$SIZE/$gt_totcnt,$gt_ddrcnt/$gt_totcnt,) if (!$AVAMAR_ONLY and $INCL_DDR) ;
  printf OUTPUT ("%10d $SIZEID ", $gt_totscan / $SIZE/$gt_totcnt );
  printf OUTPUT ("%10d $SIZEID %5d %4d %10d $SIZEID ",$gt_gcrecovered/$SIZE/$gt_totcnt, $gt_gcelap/60/$gt_totcnt, $gt_gcpass/$gt_totcnt, ($gt_sent + $gt_gcrecovered)/$SIZE/$gt_totcnt) if (!$DDR_ONLY);
  my $pchange  = ($gt_totscan==0) ? "       N/A" : sprintf("%9.2f%",$gt_totsent/$gt_totscan*100) ;
  printf OUTPUT ("%10s\n", $pchange);
}
########## End capacity_info ########

########## Start big_clients ########
sub big_clients {


  print "\nTop Change Rate Clients.  Total Data Added ".int($GRAND_TOTAL_ADDED/$SIZE). "$SIZEID\n\n";
  printf ("%13s %10s %7s %4s %s\n","NEW DATA","% OF TOTAL","CHGRATE","TYPE","CLIENT");
  printf ("%13s %10s %4s %s\n","=============","==========","=======","====","======");

#date(started_ts) as started_ts, bytes_modified_sent, bytes_scanned, num_mod_files, dpn_domain||/||client_name as client_name, num_of_files $INCL_DDR_HOSTNAME

  my @keys = sort { $SENT{$b} <=> $SENT{$a} } keys %SENT;
  my $cnt=0;
  for my $client ( @keys ) {
    my $chgrate=0;
    $chgrate=($SENT{$client}/$CLI{$client}{scan})*100 if ($CLI{$client}{scan} gt 0) ;
    my $type=($CLI{$client}{ddr}) ? "DDR" : "AVA";
    next if ($DDR_ONLY and $type ne "DDR");
    next if ($AVAMAR_ONLY and $type ne "AVA");
    my $pct=($GRAND_TOTAL_ADDED>0) ? ($SENT{$client}/$GRAND_TOTAL_ADDED)*100 : 0;
    (my $pclient=$client) =~ s/_.{22}$//;
    my $sz=($SIZE>0) ? $SENT{$client}/$SIZE : 0;
    printf OUTPUT ("%10d $SIZEID %9.2f %6.2f%% %4s %s\n",$sz,$pct,$chgrate,$type,$pclient);
    $cnt++; last if ($cnt==$LIMIT);
  }
  print OUTPUT "\n";
}

########## End big_clients ########

########## Start client_files########
sub client_files{
  return if (!$DDR_TOTAL_FILES);
  print "\nTop File Count Clients. Total Files Added $DDR_TOTAL_FILES\n\n";
  printf ("%13s %10s %7s %4s %s\n","NUM FILES","% OF TOTAL","TYPE","CLIENT");
  printf ("%13s %10s %4s %s\n","=============","==========","====","======");

  my @keys = sort { $FILES{$b} <=> $FILES{$a} } keys %FILES;
  my $cnt=0;
  for my $client ( @keys ) {
    my $type=($CLI{$client}{ddr}) ? "DDR" : "AVA";
    next if ($type ne "DDR");
    my $pct=($FILES{$client}/$DDR_TOTAL_FILES)*100;
    (my $pclient=$client) =~ s/_.{22}$//;
    printf OUTPUT ("%13d %9.2f %4s %s\n", $FILES{$client}, $pct, $type,$pclient);
    $cnt++; last if ($cnt==$LIMIT);
  }
  print OUTPUT "\n";
}

########## End client_files ########

}
########## End capacity.pl ##########
