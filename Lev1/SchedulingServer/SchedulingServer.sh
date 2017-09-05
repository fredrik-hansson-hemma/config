#!/bin/bash -p
#
# schedulingserver.sh
#
# Script for managing the OS Scheduling Server
#

# Uncomment the set -x to run in debug mode
# set -x

# Source appserver_env
. "`dirname \"$0\"`/../level_env.sh"

CONFIGDIR="$LEVEL_ROOT"/'SchedulingServer'

# Source usermods file
. "$CONFIGDIR"/'SchedulingServer_usermods.sh'

# Set config file path
SASCFGPATH="/opt/sas/sashome/SASFoundation/9.4/sasv9.cfg, $CONFIGDIR/sasv9.cfg, /opt/sas/config/Lev1/SchedulingServer/sasv9_usermods.cfg"
export SASCFGPATH

exec "$SAS_COMMAND" "$@" "${USERMODS_OPTIONS[@]}"
