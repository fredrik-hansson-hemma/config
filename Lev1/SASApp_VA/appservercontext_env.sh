#!/bin/sh -p
#
# appservercontext_env.sh
#
# syslog      Set environment variables relative to the application server context
#

# Define needed environment variables
if [ -f `dirname $0`/../level_env.sh ]; then
   . `dirname $0`/../level_env.sh
else
   . `dirname $0`/../../level_env.sh
fi

APPSERVER_ROOT=$LEVEL_ROOT/SASApp_VA

. $APPSERVER_ROOT/appservercontext_env_usermods.sh

# Define the initial directory context
cd $APPSERVER_ROOT
