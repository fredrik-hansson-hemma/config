#!/bin/sh -p
###########################################################################################
#  sas.sh
#
# This script invokes sas with the default configuration for this application server. 
#
###########################################################################################

# Uncomment the set -x to run in debug mode
# set -x

# Source appserver_env
. `dirname $0`/appservercontext_env.sh

CONFIGDIR=`dirname $0`

# Source usermods file
. $CONFIGDIR/sas_usermods.sh

# Set config file path
SASCFGPATH="$CONFIGDIR/sasv9.cfg, $CONFIGDIR/sasv9_usermods.cfg"
export SASCFGPATH

Quoteme() {
   if [ $# -gt 1 ]; then
      quoteme="\"$*\""
   else
      quoteme=$1
   fi
}
SAS_CMD_OPTIONS="-metaautoresources 'SASApp_VA'"
cmd="$SAS_COMMAND $SAS_CMD_OPTIONS $SAS_USERMODS_OPTIONS"

for arg in "$@" ; do
   Quoteme $arg
   tmp="$quoteme"
   cmd="$cmd $tmp"
done

eval exec $cmd 
