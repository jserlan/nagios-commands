#!/bin/bash
#
# Event handler script for restarting the web server on the remote machine
#
#

REMOTEUSER=$1
REMOTEHOST=$2
SERVICESTATE=$3
SERVICESTATETYPE=$4
SERVICEATTEMPT=$5
MAXSERVICEATTEMPTS=$6
BEFOREMAXSERVICEATTEMPTS=$(($MAXSERVICEATTEMPTS - 1))

# Check whether if the service status is CRITICAL
# In case it is different to CRITICAL, nothing to do automatically
case "$SERVICESTATE" in
        OK)
        ;;
        WARNING)
        ;;
        UNKNOWN)
        ;;
        CRITICAL)
		# Check whether if the service is in HARD or SOFT state
		# In case it is in SOFT state and reach MAXSERVICEATTEMPTS - 1, try to restart Apache
		# In case it is in HARD state, try to restart Apache
                case "$SERVICESTATETYPE" in
                        SOFT)
                        if [ $SERVICEATTEMPT -ge $BEFOREMAXSERVICEATTEMPTS ]
                        then
                        echo "yes"
                                echo -n "Restarting HTTP service"
                                ssh ${REMOTEUSER}@${REMOTEHOST} 'sudo /usr/sbin/service apache2 status > /dev/null 2>&1 && echo "Apache already started" && exit 0 || sudo /usr/sbin/apache2ctl -t > /dev/null 2>&1 && sudo /usr/sbin/service apache2 start > /dev/null 2>&1 && echo "Apache successfully started"'
                        else
                        fi
                        ;;
                        HARD)
                        echo -n "Restarting HTTP service"
                        ssh ${REMOTEUSER}@${REMOTEHOST} 'sudo /usr/sbin/service apache2 status > /dev/null 2>&1 && echo "Apache already started" && exit 0 || sudo /usr/sbin/apache2ctl -t > /dev/null 2>&1 && sudo /usr/sbin/service apache2 start > /dev/null 2>&1 && echo "Apache successfully started"'
                        ;;
                esac
                ;;
esac
exit 0
