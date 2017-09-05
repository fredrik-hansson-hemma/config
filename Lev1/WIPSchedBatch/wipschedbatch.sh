#!/bin/ksh -p
#
# javabatch.sh
#
# Script for managing the SASAppVA - Logical SAS Java Batch Server
#

# Uncomment the set  -x to run  in debug mode
# set -x

# Source usermods file
. /opt/sas/config/Lev1/WIPSchedBatch/wipschedbatch_usermods.sh

exec "/opt/sas/config/Lev1/Web/Applications/SASWIPSchedulingServices9.4/servicetrigger" "$@" "${USERMODS_OPTIONS[@]}"
