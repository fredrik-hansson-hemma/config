#!/bin/sh -p
#
#
# syslog      Starts the Postgres Server
#

# Uncomment the set -x to run in debug mode
# set -x

# Source appserver_env
. `dirname $0`/../level_env.sh

CONFIGDIR=/opt/sas/config/Lev1/WebInfrastructurePlatformDataServer
BINDIR=/opt/sas/sashome/SASWebInfrastructurePlatformDataServer/9.4/bin
LOGSDIR=/opt/sas/config/Lev1/WebInfrastructurePlatformDataServer/Logs
SCRIPT=`basename $0`
SERVERUSER=sas
COMMAND=""/opt/sas/sashome/SASWebInfrastructurePlatformDataServer/9.4/bin/pg_ctl""

# S1083332 & S1081892 - make sure we start on the host we were configured on
HOSTNAME=$(hostname -s)
IPADDR=$(host -n $HOSTNAME | awk '{print $4;}')
CONFIGHOSTNAME=bs-ap-20
CONFIGIPADDR=$(host -n $CONFIGHOSTNAME | awk '{print $4;}')

# Set config file path
# SASCFGPATH="$LEVEL_ROOT/sasv9_meta.cfg, $CONFIGDIR/@iomsrv.webinfdsvrc.config.file.name@, $CONFIGDIR/@iomsrv.webinfdsvrc.config.usermods.file.name@"
# export SASCFGPATH

# Are we super user
if id | grep '^uid=0(' >/dev/null 2>&1 ; then
   root=1
else
   root=0
fi

# Get argument
case "$1" in
   start | -start)
         if [ "$IPADDR" = "$CONFIGIPADDR" ]; then
            if [ -f $CONFIGDIR/data/postmaster.pid ]; then
               pid=`head -1 $CONFIGDIR/data/postmaster.pid`
               kill -0 $pid > /dev/null 2>&1
               if [ $? -eq 0 ]; then
                  echo "Server is already running (pid $pid)"
                  exit 0
               fi
               rm $CONFIGDIR/data/postmaster.pid
            fi
            if [ $root -eq 1 ]; then
               su - $SERVERUSER -c "$CONFIGDIR/$SCRIPT start2_tag &"
            else
               $CONFIGDIR/$SCRIPT start2_tag &
            fi
         else
             echo "Start failure due to start issued on the incorrect host.  $HOSTNAME != $CONFIGHOSTNAME  $IPADDR != $CONFIGIPADDR"
             exit 0
         fi
         ;;
   start2_tag)
         cd $BINDIR
         LD_LIBRARY_PATH=/opt/sas/sashome/SASWebInfrastructurePlatformDataServer/9.4/lib:$LD_LIBRARY_PATH
         LIBPATH=/opt/sas/sashome/SASWebInfrastructurePlatformDataServer/9.4/lib:$LIBPATH
         export LD_LIBRARY_PATH
         export LIBPATH
         nohup $COMMAND start -D "/opt/sas/config/Lev1/WebInfrastructurePlatformDataServer/data" -o "-i -p 9432" > $LOGSDIR/webinfdsvrc_console.log 2>&1 &
         pid=$!
#         echo $pid > $CONFIGDIR/data/postmaster.pid
         echo "Server is started (pid $pid)..."
# Trap signals 9 and 15 and pass on to child process
#         trap 'kill $pid' 2 3 15
#         wait $!
#         rm "$CONFIGDIR/data/postmaster.pid"
#         echo "Server is stopped"
         echo "Log files are located at: $LOGSDIR"
         exit 0
         ;;
   stop | -stop)
         cd $BINDIR
         LD_LIBRARY_PATH=/opt/sas/sashome/SASWebInfrastructurePlatformDataServer/9.4/lib:$LD_LIBRARY_PATH
         LIBPATH=/opt/sas/sashome/SASWebInfrastructurePlatformDataServer/9.4/lib:$LIBPATH
         export LD_LIBRARY_PATH
         export LIBPATH
         nohup $COMMAND stop -D "/opt/sas/config/Lev1/WebInfrastructurePlatformDataServer/data" -m f > $LOGSDIR/webinfdsvrc_console.log 2>&1 &
         # give the server some time to stop before trying to remove the pid
         sleep 5
         if [ -f $CONFIGDIR/data/postmaster.pid ]; then
            pid=`head -1 $CONFIGDIR/data/postmaster.pid`
            kill $pid
            if [ $? -ne 0 ]; then
               echo "pid: $pid"
            fi
         else
            echo "Server is stopped"
            exit 0
         fi
         ;;
   status | -status)
         if [ -f $CONFIGDIR/data/postmaster.pid ]; then
            pid=`head -1 $CONFIGDIR/data/postmaster.pid`
            kill -0 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
               echo "Server is started (pid $pid)"
            else
               echo "Server is stopped"
            fi
         else
            echo "Server is stopped"
         fi
         ;;
   restart | -restart)
         $0 stop
         if [ $? -eq 0 ]; then
            sleep 5
            $0 start
         fi
         ;;
   remotestart | -remotestart)
         if [ -f $CONFIGDIR/data/postmaster.pid ]; then
            pid=`head -1 $CONFIGDIR/data/postmaster.pid`
            kill -0 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
               echo "Server is already running (pid $pid)"
               exit 1
            fi
            rm $CONFIGDIR/data/postmaster.pid
         fi
         if [ $root -eq 1 ]; then
            su - $SERVERUSER -c "$CONFIGDIR/$SCRIPT start2_tag &"
            exit 0
         else
            $0 start2_tag
            exit 0
         fi
         ;;
   remotestop | -remotestop)
         if [ -f $CONFIGDIR/data/postmaster.pid ]; then
            $0 stop
         else
            echo "Server is already stopped"
            exit 1
         fi
         ;;
   remotestatus | -remotestatus)
         if [ -f $CONFIGDIR/data/postmaster.pid ]; then
            pid=`head -1 $CONFIGDIR/data/postmaster.pid`
            kill -0 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
               echo "Server is started (pid $pid)"
               exit 0
            else
               echo "Server is stopped"
               exit 1
            fi
         else
            echo "Server is stopped"
            exit 1
         fi
         ;;
   *)
         echo "Usage: $SCRIPT {-}{start|stop|status|restart}"
         exit 1
esac

exit 0
