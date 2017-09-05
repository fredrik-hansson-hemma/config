#!/bin/sh -p
#
# ObjectSpawner.sh
#
# syslog      Starts the SAS Object Spawner
#

# Uncomment the set -x to run in debug mode
# set -x

# Source level_env
. `dirname $0`/../level_env.sh

CONFIGDIR=$LEVEL_ROOT/ObjectSpawner

LOGSDIR=/opt/sas/config/Lev1/ObjectSpawner/Logs
SASENV=$SASROOT/bin/sasenv
OMRCFG=$LEVEL_ROOT/ObjectSpawner/metadataConfig.xml
SPWNNAME="Object Spawner - bs-ap-04"
SERVERUSER=sas
CMD_OPTIONS=" -dnsmatch bs-ap-04.lul.se -sspi "
COMMAND="$SASROOT/utilities/bin/objspawn"
SCRIPT=`basename $0`

if [ "$SAS_INSTALL_ROOT" = "" ] ; then
    SAS_INSTALL_ROOT=$SASROOT
    export SAS_INSTALL_ROOT
fi

# Are we super user
if id | grep "^uid=0(" >/dev/null 2>&1 ; then
   root=1
else
   root=0
fi

# If there is a keytab present for the object spawner, export it here
if [ -f "$CONFIGDIR/objspawn.keytab" ]; then
   KRB5_CLIENT_KTNAME="$CONFIGDIR/objspawn.keytab"
   export KRB5_CLIENT_KTNAME
fi

# Get argument
case "$1" in
   start | -start)
         if [ -f $CONFIGDIR/$SERVER_PID_FILE_NAME ]; then
            pid=`cat $CONFIGDIR/$SERVER_PID_FILE_NAME`
            kill -0 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
               echo "Spawner is already running (pid $pid)"
               exit 0
            fi
            rm $CONFIGDIR/$SERVER_PID_FILE_NAME
         fi
         if [ $root -eq 1 ]; then
            su - $SERVERUSER -c "$CONFIGDIR/$SCRIPT start2_tag &"
         else
            $CONFIGDIR/$SCRIPT start2_tag &
         fi
         ;;
   start2_tag)
         cd $CONFIGDIR
         . $SASENV
         SASROOT=$SASROOT
         export SASROOT

         # Source usermods file
         . $CONFIGDIR/ObjectSpawner_usermods.sh

         eval "nohup $COMMAND $CMD_OPTIONS -sasSpawnerCn \"$SPWNNAME\" -xmlconfigfile $OMRCFG -logconfigloc $CONFIGDIR/logconfig.xml ${USERMODS}> $LOGSDIR/ObjectSpawner_console_bs-ap-04.log 2>&1 &"
         pid=$!
         echo $pid > $CONFIGDIR/$SERVER_PID_FILE_NAME
         echo "Spawner is started (pid $pid)..."
# Trap signals 9 and 15 and pass on to child process
         trap 'kill $pid' 2 3 15
         wait $!
         rm "$CONFIGDIR/$SERVER_PID_FILE_NAME"
         echo "Spawner is stopped"
         echo "Log files are located at: $LOGSDIR"
         ;;
   stop | -stop)
         if [ -f $CONFIGDIR/$SERVER_PID_FILE_NAME ]; then
            pid=`cat $CONFIGDIR/$SERVER_PID_FILE_NAME`
            kill $pid
            if [ $? -ne 0 ]; then
               echo "pid: $pid"
            fi
         else
            echo "Spawner is stopped" 
         fi
         ;;
   status | -status)
         if [ -f $CONFIGDIR/$SERVER_PID_FILE_NAME ]; then
            pid=`cat $CONFIGDIR/$SERVER_PID_FILE_NAME`
            kill -0 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
               echo "Spawner is started (pid $pid)"
            else
               echo "Spawner is stopped"
            fi
         else
            echo "Spawner is stopped"
         fi
         ;; 
   restart | -restart)
         $0 stop
         if [ $? -eq 0 ]; then 
            sleep 5
            $0 start
         fi   
         ;;
   *)
         echo "Usage: $SCRIPT {-}{start|stop|status|restart}"
         exit 1
esac

exit 0
