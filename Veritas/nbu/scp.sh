#!/usr/bin/expect -f

# connect via scp
spawn scp "user@example.com:/home/santhosh/file.dmp" /u01/dumps/file.dmp
#######################
expect {
-re ".*es.*o.*" {
exp_send "yes\r"
exp_continue
}
-re ".*sword.*" {
exp_send "PASSWORD\r"
}
}
interact


# scp nw99qdt@ghnbumstr1:/usr/openv/netbackup/db/shared_scripts/excludemanager.ba.sh /usr/openv/netbackup/db/shared_scripts/excludemanager.ba.sh

Send file to 					  To server/path
scp /tmp/openv.tar.gz nw99qdt@ghnbumstr1_b:/tmp/openv.tar.gz

scp nw99qdt@ghnbutest01:/usr/openv/netbackup/db/shared_scripts/excludemanager.ba.sh /usr/openv/netbackup/db/shared_scripts/excludemanager.ba.sh


scp nw99qdt@ghnbutest01:/usr/openv/netbackup/db/shared_scripts/imageextend.ba.sh /usr/openv/netbackup/db/shared_scripts/imageextend.ba.sh


scp nw99qdt@alpnbumstr1:/usr/openv/netbackup/bin/support/nbcplogs.conf /usr/openv/netbackup/bin/support/nbcplogs.conf
