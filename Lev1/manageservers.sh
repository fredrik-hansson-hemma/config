#!/bin/sh
#
# manageservers.sh
# 
# This script is intented to aid development and testing teams by providing a simple means 
# of checking, starting and stopping servers on unix.  While something similar may be shipped
# to customers, it is not intended that this particular script be shipped.
#
# syslog      Manage SAS Servers
#

# Uncomment the set -x to run in debug mode
# set -x

# Source sasconfig_env
. `dirname $0`/level_env.sh

SCRIPT=`basename $0`

# Get argument
if [ "$1" = "start" ]; then
   arg=start
elif [ "$1" = "stop" ]; then
   arg=stop
elif [ "$1" = "status" ]; then
   arg=status
elif [ "$1" = "restart" ]; then
   arg=restart
else
   arg=$1
fi

# Execute each server script with our augument
case "$arg" in
   start)
      # Metadata Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.metadatasrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f start
           sleep 3
        done
      
      # Object Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.objectspawnr.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f start
           sleep 3
        done
            
      # OLAP Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.olapserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f start
           sleep 3
        done
      
      # Connect Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.connectsrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f start
           sleep 3
        done
      
      # Share Server
        files=`find $LEVEL_ROOT -type f -name @server.sharesrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f start
           sleep 3
        done
      
      # Table Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.tableserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f start
           sleep 3
        done
         ;;
   stop)
      # Metadata Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.metadatasrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f stop
           sleep 3
        done
      
      # Object Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.objectspawnr.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f stop
           sleep 3
        done
            
      # OLAP Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.olapserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f stop
           sleep 3
        done
      
      # Connect Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.connectsrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f stop
           sleep 3
        done
      
      # Share Server
        files=`find $LEVEL_ROOT -type f -name @server.sharesrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f stop
           sleep 3
        done
      
      # Table Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.tableserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f stop
           sleep 3
        done
         ;;
   status)
      # Metadata Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.metadatasrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f status
        done
      
      # Object Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.objectspawnr.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f status
        done
            
      # OLAP Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.olapserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f status
        done
      
      # Connect Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.connectsrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f status
        done
      
      # Share Server
        files=`find $LEVEL_ROOT -type f -name @server.sharesrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f status
        done
      
      # Table Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.tableserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f status
        done
         ;; 
   restart)
      # Metadata Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.metadatasrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f restart
           sleep 3
        done
      
      # Object Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.objectspawnr.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f restart
           sleep 3
        done
            
      # OLAP Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.olapserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f restart
           sleep 3
        done
      
      # Connect Spawner
        files=`find $LEVEL_ROOT -type f -name @spawner.connectsrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f restart
           sleep 3
        done
      
      # Share Server
        files=`find $LEVEL_ROOT -type f -name @server.sharesrv.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f restart
           sleep 3
        done
      
      # Table Server
        files=`find $LEVEL_ROOT -type f -name @iomsrv.tableserver.script.name@`
        for f in $files
        do
           echo 
           echo `basename $f`
           $f restart
           sleep 3
        done
         ;;
   *)
         echo "Usage: $SCRIPT {start|stop|status|restart}"
esac
