
#!/bin/bash
# Should be /usr/openv/netbackup/db/shared_scripts/createscript.ba.sh
echo "Place full path of new script below."
echo "VI will be invoked"
echo "Example:  /usr/openv/netbackup/db/shared_scripts/example.ba.sh"
echo "------------"
read PATHOFFILE
vi $PATHOFFILE
echo ""
echo ""
chmod u+x $PATHOFFILE
echo ""
chmod 755 $PATHOFFILE
echo "Done"
