#!/bin/sh -p
#
# javabatch.sh
#
# Script for managing the SASApp_VA - Logical SAS Java Batch Server
#

# Uncomment the set  -x to run  in debug mode
# set -x

# test this shell to see if it can do arrays, and if not, exec ksh to run this script
eval "f[0]"="0" 2>/dev/null ; [ "$f" != "0" ] && exec /bin/ksh "$0" "$@"

# Source usermods file
. /opt/sas/config/Lev1/VASchedDist/vascheddistbatch_usermods.sh

exec "/opt/sas/config/Lev1/Applications/SASVisualAnalytics/HighPerformanceConfiguration/javaBatchServer.sh" "$@" "${USERMODS_OPTIONS[@]}"
