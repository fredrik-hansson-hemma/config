stop_servers ()
{
  #
  # Shut everything down (in reverse order).
  # We assume that the assorted "stop" scripts will succeed.
  #

  $Logmsg "$SASSRV_STOP"


  # Variables defined by generate_boot_scripts.sh - MUST BE ROOTED AT CHAR POSITION 1
SCRIPT_MID=
MYPATH=

  #
  # Should we invoke the sas.servers.mid script?
  #
  if [ "$SCRIPT_MID" = "YES" ];
  then
  {
     if [ -x "$MYPATH/sas.servers.mid" ];
     then
       $MYPATH/sas.servers.mid stop
     fi
  }
  fi


