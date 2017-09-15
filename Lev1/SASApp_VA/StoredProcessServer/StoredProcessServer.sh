#!/bin/sh -p
#
# storedprocessserver.sh
#
# This script invokes sas with the default configuration for this
# application server. It changes directories so that sas is invoked
# from the root directory of this application server.
#

# Uncomment the set -x to run in debug mode
# set -x

# Source appserver_env
. `dirname $0`/../appservercontext_env.sh

CONFIGDIR=$APPSERVER_ROOT/StoredProcessServer
LOGSDIR=/opt/sas/config/Lev1/SASApp_VA/StoredProcessServer/Logs
CMD_OPTIONS=""

# Source usermods file
. $CONFIGDIR/StoredProcessServer_usermods.sh

# Set config file path
SASCFGPATH="$APPSERVER_ROOT/sasv9.cfg, $APPSERVER_ROOT/sasv9_usermods.cfg, $CONFIGDIR/sasv9.cfg, $CONFIGDIR/sasv9_usermods.cfg"
export SASCFGPATH

Quoteme() {
   if [ $# -gt 1 ]; then
      quoteme="\"$*\""
   else
      quoteme=$1
   fi
}

cmd="$SAS_COMMAND $CMD_OPTIONS $USERMODS_OPTIONS "

for arg in "$@" ; do
   Quoteme $arg
   tmp="$quoteme"
   cmd="$cmd $tmp"
done

eval exec $cmd
