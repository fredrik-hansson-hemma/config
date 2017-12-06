#!/bin/ksh -p
#
# sasbatch.sh
#
# Script for managing the SAS DATA Step Batch Server
#

# Uncomment the set -x to run in debug mode
# set -x

# Clear METAUSER and METAPASS to prevent trying to use them as a one-time password, which would fail 
unset METAUSER
unset METAPASS

# Source appserver_env
parentpath='/opt/sas/config/Lev1/SASApp_VA'
. "$parentpath/appservercontext_env.sh"

CONFIGDIR="$APPSERVER_ROOT"/'BatchServer'

# Source usermods file
. "$CONFIGDIR"/'sasbatch_usermods.sh'

# Set config file path
SASCFGPATH="/opt/sas/config/Lev1/SASApp_VA/sasv9.cfg, /opt/sas/config/Lev1/SASApp_VA/sasv9_usermods.cfg, /opt/sas/config/Lev1/SASApp_VA/BatchServer/sasv9.cfg, /opt/sas/config/Lev1/SASApp_VA/BatchServer/sasv9_usermods.cfg"
export SASCFGPATH

# Skapa katalog för returkod, om den inte redan finns
ls /saswork/batchrun/ > /dev/null || mkdir /saswork/batchrun

"$SAS_COMMAND" -noxcmd -lrecl 32767 "$@" "${USERMODS_OPTIONS[@]}"
# To allow SAS warnings (rc==1) to be treated as okay, remove the "exec" on the line above and uncomment the lines below.
rc=$?
#if [ $rc -eq 1 ]; then
#  rc=0
#fi
dt=`date +%Y%m%d`
echo "/opt/sas/config/Lev1/SASApp_VA/BatchServer/sasbatch.sh" "$@" "Retur:"$rc "Datum:"$dt>> /saswork/batchrun/returncodes.txt

# Raden ovan kanske borde ersättas med raden nedan för att få med alla USERMODS_OPTIONS-arrayen
# Vågar inte ändra nu precis före produktionssättning av nya miljön. Vi tar det i januari 2018.
# echo "$SAS_COMMAND" -noxcmd -lrecl 32767 "$@" "${USERMODS_OPTIONS[@]}" "Retur:"$rc "Datum:"$dt>> /saswork/batchrun/returncodes.txt

# Ett litet trick för att skriptet ska returnera SAS-programmets returkod
(exit $rc)
