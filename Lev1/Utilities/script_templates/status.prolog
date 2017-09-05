#
# Check server status. We could invoke each server script with "status",
# but it's quicker to do this directly. Note that if the status check
# paradigm changes in the server scripts, those changes will need to
# be propagated to here.
#
# This uses the cheap-but-quick approach that simply checks for
# alive server PIDs.
#
server_status()
{

  $Logmsg "$SASSRV_STATUS"

  # Variables defined by generate_boot_scripts.sh - MUST BE ROOTED AT CHAR POSITION 1
SCRIPT_PRE=
MYPATH=

  #
  # Should we invoke the sas.servers.pre script?
  #
  if [ "$SCRIPT_PRE" = "YES" ];
  then
  {
     if [ -x "$MYPATH/sas.servers.pre" ];
     then
       $MYPATH/sas.servers.pre status
     fi
  }
  fi

  #
  # generated code follows
  #

