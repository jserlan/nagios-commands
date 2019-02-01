# Nagios scripts for event handlers

## What is it ?

Event handlers is an optional command that allow Nagios to perform tasks automatically following a change in the status detected for a host or a service.

Since the event handlers scripts are executed by Nagios process, as the check commands, they can take the Nagios macros as arguments.

## Configuration example

Following with an example that will run a script on a remote machine to restart Apache HTTPd remotely if it's down. The event handler scripts will be executed on a CRITICAL HARD status or juste before the last SOFT status.  

### The script http-restart-remotely.sh

You need to store the script in a folder that Nagios can read, for instance put your script under the nagios-plugins folder's, for this example I chose to store into ```/usr/local/nagios/libexec/eventhandlers/```.

```bash
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
```

### The requirements of the scripts

#### Add execution rights on the script

```
cd /usr/local/nagios/libexec/eventhandlers/
chmod ugo+x http-restart-remotely.sh
```

#### Add Nagios user ssh key's on the remote host with your monitoring user

```
su nagios
cd
ssh-keygen -b 2048 -t rsa
ssh-copy-id -i ~/.ssh/id_rsa <remoteuser>@<remotehost>
```

### Define the service in Nagios

```
define service {
    host_name               somehost.example.com
    service_description     HTTP service
    max_check_attempts      3
    event_handler           http-restart-remotely!<remoteuser>!<maxattempt>
    ...
}
```

### Define the command in Nagios

```
define command {
    command_name    http-restart-remotely
    command_line    /usr/local/nagios/libexec/eventhandlers/http-restart-remotely.sh $ARG1$ $HOSTADDRESS$ $SERVICESTATE$ $SERVICESTATETYPE$ $SERVICEATTEMPT$ $ARG2$
}
```
