start_servers ()
{
  #
  # We use the current time to figure out which log file to check
  # (in most cases).
  #
  # This could break if the system is rebooted right at midnight, since the date
  # may wrap. We'll check for that if the initial log file existence fails.
  #
  SCRIPT_TIME=`date +%Y%m%d%H%M%S`

  #
  # Crank everything up
  #

  $Logmsg "$SASSRV_START"

  #
  # All instances of local SAS Metadata servers have to precede the 
  # other SAS server types in the start sequence.
  #
  # If any local instance of a SAS Metadata server fails to start, the 
  # rest of the start operation is aborted.
  #
  # If any instances of the other server types fail to start, a message 
  # is logged for that instance, but the start operation will continue
  # with the remaining servers (if any).


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
       $MYPATH/sas.servers.pre start
     fi
  }
  fi


  #
  # Generated start code follows:
  #

 


