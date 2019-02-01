#!/bin/bash
#
# Event handler script for restarting the mysql slave process on the remote machine
#
#

REMOTEHOST=$1
REMOTEPORT=$2
MYSQLUSER=$3
MYSQLPASS=$4
SERVICESTATE=$5
SERVICESTATETYPE=$6
SERVICEATTEMPT=$7
MAXSERVICEATTEMPTS=$8
BEFOREMAXSERVICEATTEMPTS=$(($MAXSERVICEATTEMPTS - 1))

SLAVESTATUS=`mysql -h ${REMOTEHOST} -P ${REMOTEPORT} -u ${MYSQLUSER} --password=${MYSQLPASS} -e "show slave status\G" 2>&1 /dev/null`

SLAVESQLSTATE=`echo "${SLAVESTATUS}" |grep Slave_SQL_Running: | awk '{print $2}'`
SLAVEIOSTATE=`echo "${SLAVESTATUS}" |grep Slave_IO_Running: | awk '{print $2}'`
ERRORNUM=`echo "${SLAVESTATUS}" |grep  Last_SQL_Errno: | awk '{print $2}'`
ERRORMSG=`echo "${SLAVESTATUS}" |grep Last_SQL_Error: | awk '{print $2}'`

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
				# In case it is in SOFT state and reach MAXSERVICEATTEMPTS - 1, try to restart the slave process
				# In case it is in HARD state, try to restart the slave process
                case "$SERVICESTATETYPE" in
                        SOFT)
                        if [ $SERVICEATTEMPT -ge $BEFOREMAXSERVICEATTEMPTS ]
                        then
							case "$ERRORNUM" in
									0)
									echo -n "Restarting MySQL slave process"
									mysql -h ${REMOTEHOST} -P ${REMOTEPORT} -u ${MYSQLUSER} --password=${MYSQLPASS} -e "start slave\G" 2>&1 /dev/null
									echo -n "Slave process restarted because of $ERRORMSG"
									;;
									1205)
									echo -n "Restarting MySQL slave process"
									mysql -h ${REMOTEHOST} -P ${REMOTEPORT} -u ${MYSQLUSER} --password=${MYSQLPASS} -e "start slave\G" 2>&1 /dev/null
									echo -n "Slave process restarted because of $ERRORMSG"
									;;
									*)
									echo -n "I don't know about this error, cannot restart MySQL process"
									echo -n "Last_SQL_Error: $ERRORMSG"
									exit 1
									;;
							esac
                        fi
                        ;;
                        HARD)
                        	case "$ERRORNUM" in
									0)
									echo -n "Restarting MySQL slave process"
									mysql -h ${REMOTEHOST} -P ${REMOTEPORT} -u ${MYSQLUSER} --password=${MYSQLPASS} -e "show slave status\G" 2>&1 /dev/null
									;;
									1205)
									echo -n "Restarting MySQL slave process"
									mysql -h ${REMOTEHOST} -P ${REMOTEPORT} -u ${MYSQLUSER} --password=${MYSQLPASS} -e "show slave status\G" 2>&1 /dev/null
									;;
									*)
									echo -n "I don't know about this error"
									exit 1
									;;
							esac
                        ;;
                esac
                ;;
esac
exit 0
