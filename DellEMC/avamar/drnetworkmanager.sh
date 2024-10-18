#!/bin/bash
#==============================================================================
#  SCRIPT.........:  
#  AUTHOR.........:  James Godfrey
#  EMAIL..........:  james.david.godfrey@gmail.com; jgodfrey@gaig.com
#  CREATED........:  10-26-16
#  DESCRIPTION....:  To Be used as an API like interface with front end scripts
#  NOTES..........:  This script should be placed on the DR grid at /home/admin/scripts/drnetworkmanager.sh
#                    This script should be placed on the proxy that will be doing VM resotres at /usr/local/avamar/scripts/drnetworkmanager.sh
#==============================================================================
# CHANGE	DATE		Email/Name						COMMENTS
# 0			10-26-16	jgodfrey@gaig.com				Specialty script for managing DR bubble 
# 1         11-14-17    jgodfrey@gaig.com               Updated scripts to work with boyers vblock and vblock proxy fklapavaprx05
#==============================================================================
PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/sbin:/usr/sbin:/home/jgodfrey/bin:/usr/openv/netbackup/bin/goodies::/usr/openv/netbackup/bin:/usr/openv/netbackup/bin/admincmd:/usr/openv/scripts:/opt/emc-tools/bin:/usr/local/avamar/bin:/sbin:/usr/sbin:/usr/local/avamar/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/apache/bin:/usr/local/ssl/bin"
set -o pipefail


#Variables


#start options parse - Don't forget to add your switches here
while getopts c:d:f:p:s:x:v:-: optionName; do
case "$optionName" in


-)  # --> Use long options for functions.  Variables will not work.
	case "${OPTARG}" in
	
	
	bubble_move_in)
		# Example syntax add: $avaworker --bubble_move_in
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'ifdown bond0.27; ifup bond0.757' " ;
		echo "Avamar has been moved into the DR bubble - vlan 757. These changes will not survive a reboot.";
	;;
	
	bubble_move_out)
		# Example syntax add: $avaworker --bubble_move_out
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'ifdown bond0.757; ifup bond0.27' " ;
		echo "Avamar has been moved out of the DR bubble - vlan 27.";
	;;
	
	
	vcenter_restore_enable)
		# Example syntax add: $avaworker --vcenter_route_enable
		### New vCenters will need to be added to this with the right network and netmask
		### New Proxies on new vCenters need to be added
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route add -net 10.60.50.0 gw 10.60.100.1 netmask 255.255.254.0 dev bond2' " ; ##vblock
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route add -net 10.60.16.0 gw 10.60.100.1 netmask 255.255.252.0 dev bond2' " ; ##fsx500
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route add -net 10.60.8.0 gw 10.60.100.1 netmask 255.255.252.0 dev bond2' " ; ##esx500 managment 
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route add -host 10.60.27.201 gw 10.60.100.1 dev bond2' " ;    ##apavaprx01 on vblock
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route add -host 10.60.27.205 gw 10.60.100.1 dev bond2' " ;    ##apavaprx05 on vblock
		echo " You should now be able to restore VMs to the the DR hypervisor while in the DR bubble. These changes will not survive a reboot.";
	;;
	
	
	vcenter_restore_disable)
		# Example syntax add: $avaworker --vcenter_route_disable
		### New vCenters will need to be added to this with the right network and netmask
		### New Proxies on new vCenters need to be added
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route del -net 10.60.50.0 netmask 255.255.254.0 dev bond2' " ; ##vblock
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route del -net 10.60.16.0 netmask 255.255.252.0 dev bond2' " ; ##esx500
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route del -net 10.60.8.0 netmask 255.255.252.0 dev bond2' " ; ##fsx500 managment
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route del -host 10.60.27.201' " ;   ##apavaprx01 on vblock
		/usr/bin/ssh-agent bash -c "/usr/bin/ssh-add ~/.ssh/dpnid 2>/dev/null; /usr/local/avamar/bin/mapall --user=root --all+ --noerror 'route del -host 10.60.27.205' " ;   ##apavaprx05 on vblock
		echo "Removed modified routes for bond2 (10.60.100.x) to talk to DR vCenter/ESXi enviroment and proxies.";
	;;
	
	
	proxy_vcenter_restore_enable)
		# Example syntax add: $avaworker --proxy_vcenter_restore_enable
		sed -i -e 's/10.60.27.11/10.60.100.11/g' /usr/local/avamar/var/axionfs.cmd
		sed -i -e 's/10.60.27.11/10.60.100.11/g' /usr/local/avamarclient/etc/mcconfig.xml
		sed -i -e 's/10.60.27.11/10.60.100.11/g' /usr/local/avamarclient/var/avagent.cfg
		echo "Finding and replacing 10.60.27.11 to 10.60.100.11 in proxy config files";
		
		echo "Added 10.60.100.10 to the hosts file"
		echo "10.60.100.10	dd01.td.afg	dd01" >> /etc/hosts
		
		echo "Restarting axionfs and avagent"
		service axionfs restart
		/etc/init.d/avagent restart
		echo "Done."
	;;
	
	
	proxy_vcenter_restore_disable)
		# Example syntax add: $avaworker --proxy_vcenter_restore_disable
		sed -i -e 's/10.60.100.11/10.60.27.11/g' /usr/local/avamar/var/axionfs.cmd
		sed -i -e 's/10.60.100.11/10.60.27.11/g' /usr/local/avamarclient/etc/mcconfig.xml
		sed -i -e 's/10.60.100.11/10.60.27.11/g' /usr/local/avamarclient/var/avagent.cfg
		echo "Finding and replacing 10.60.100.11 to 10.60.27.11 in proxy config files";
		
		echo "Removing 10.60.100.10 from the hosts file"
		sed -i '/dd01.td.afg/d' /etc/hosts
		
		echo "Restarting axionfs and avagent"
		service axionfs restart
		/etc/init.d/avagent restart
		echo "Done."
	;;
	
		
	esac;;
	

*) 
	if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
		echo "Non-option argument: '-${OPTARG}'" >&2
	fi
;;
esac
done
