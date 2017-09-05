#!/bin/sh
#
# generate_boot_scripts.sh
#
# This script will generate a new "sas.servers" script to use as
# a system boot time start/stop script for all of the SAS servers 
# installed in the local LEVELDIR. The sas.servers start/stop
# script will sequence the server types appropriately, and where applicable,
# parses their logs to determine that each server instance has started 
# successfully as a result of THIS boot before starting the next server. 
#
# The sas.servers script can also be used to manually start, stop, and
# check status of all of the SAS servers installed in the local LEVELDIR
# with the appropriate argument.
#
# The resulting start/stop script supports multiple instances of each SAS
# server type. Local SAS Metadata servers are started first and stopped
# last to accommodate dependent SAS servers (SAS OLAP et al).
#
# With the advent of SAS 9.4, the sas.servers script has been extended to also
# invoke a sas.servers.pre script which starts a database, and sas.servers.mid which
# starts a series of mid-tier servers. By default, sas.servers "start" operations 
# will invoke in order:
#
#   sas.servers.pre start  (database)
#   sas.servers start  (EBI servers)
#   sas.servers.mid start  (mid-tier servers and agents)
#
# By default, "stop" operations will invoke:
#
#   sas.servers.mid stop
#   sas.servers stop
#   sas.servers.pre stop
#
# The generate_boot_scripts.sh script now supports two options: -nomid and -nopre
# Invoking these options while generating a new sas.servers script will disable default
# invocation of the related sub-script(s), so if you wish to manually invoke each script
# rather than having them all started by sas.servers, you would generate a new sas.servers
# with the options:
#
#    ./generate_boot_scripts.sh  -nomid  -nopre
#
#
#
# If changes are made to the SAS installation, such as adding additional
# servers or deleting/disabling existing server instances, this script can
# be rerun to generate new start/stop script reflecting the new SAS environment.
#
# How it works:
# The script searches the LEVELDIR directory tree for SAS .srv files which
# describe the paths to each server instance's control scripts and
# log files. These paths, along with other code fragments, are used
# to generate the final start/stop script. The resulting script will
# have header comments describing how to install it in the system's
# init/rc hierarchy if desired.
#
# The OS type is derived from the Unix "uname" command, with specific Linux
# versions determined by scanning /proc/version.
#
# Usage:
#  ./generate_boot_scripts.sh <-nopre> <-nomid>
#
# The resulting sas.servers script is a combination of code fragments:
#
#   sas.servers_<platform>.prolog
#   sas.servers.mainlog
#   start.prolog
#   1 or more <server>_start.template files
#   start.epilog
#   stop.prolog
#   1 or more <server>_stop.template files
#   stop.epilog
#   status.prolog
#   1 or more <server>_status.template files
#   status.epilog
#   sas.servers.epilog
#

#
# These symbols are populated by the SAS ConfigWizard.
# 
SERVERUSER=sas
LEVELDIR=/opt/sas/config/Lev1
SCRIPTDIR=$LEVELDIR/Utilities/script_templates

IRSS_SERVER_DIR=$LEVELDIR/Applications/SASInformationRetrievalStudioforSAS

FEDERATION_SERVER_DIR=$LEVELDIR/FederationServer

STARTCMD=start
STOPCMD=stop
RESTARTCMD=restart
STATUSCMD=status

SASMSGFILE_EN=$LEVELDIR/Utilities/script_templates/messages_en.txt
SASMSGFILE=$LEVELDIR/Utilities/script_templates/messages_en.txt

#
# statically-defined symbols
#

# The generated output filenames
 
SCRIPTFILE=sas.servers
SCRIPTNAME=$LEVELDIR/$SCRIPTFILE
SCRIPTFILEPRE=sas.servers.pre
SCRIPTNAMEPRE=$LEVELDIR/$SCRIPTFILEPRE
SCRIPTFILEMID=sas.servers.mid
SCRIPTNAMEMID=$LEVELDIR/$SCRIPTFILEMID

# The maximum number of instances of a particular SAS server type
# that are supported by this tool in a given configuration. This limit
# corresponds to the number of related output messages strings supplied
# in the script_templates/messages_<locale>.txt file
MAX_INSTANCES=5

# The version of the SAS server configuration file (.srv) format 
# supported by this utility. This should rarely change.
FORMATVERSION=1

#++++
# script functions/subroutines
#++++

#
# get_paths - parse the script and log paths from a SAS server .srv file
#
# $1 - path to the SAS server .srv file
#
# global symbol input:
#   COUNT_DISABLED  "TRUE" = count and flag server instances disabled by the
#                            DISABLE keyword in the server's .srv control file.
#                   "FALSE" = neither count nor flag disabled instances
#
# returns 0 on success, >0 on failure
# sets the symbols:
#  CONTROLPATH
#  LOGPATH
#  SCONTEXT
#
# as required, increments the symbols:
#  IGNORED
#  ERRIGNORED
#
# The current (v1) SAS .srv file format is as follows:
#
#  Line1: line offset into the file for the config data; this offset
#         exists so that changes to, or native-language translations of 
#         these header comments can be accommodated.
#
#  Line2 to offset-1: comments, ignored
#
#  offset: ENABLE/DISABLE  DISABLE will cause this server instance to be
#          ignored for purposes of the start/boot script. Remaining lines
#          in this file will be ignored.
#
#  offset+1: this file format version, used to accommodate changes in
#            script generation and as an additional format sanity check.
#
#  offset+2: path to SAS server control script, server.pid is assumed
#            to live at this same directory
#
#  offset+3: path to SAS server log files, may differ from above
#
#  offset+4: server context if needed, or "NULL"
#

get_paths()
{ 
  SRVFILE=$1
#echo get_paths orig SRVFILE is $SRVFILE
  SRVFILE=`echo $SRVFILE | tr "#" " "`
#echo get_paths SRVFILE is $SRVFILE

  OFFSET=`head -n 1 "$SRVFILE"`
#echo get_paths OFFSET is $OFFSET

  # Using sed for this is a bit like using a sledgehammer... "ed" would
  # work too, but would require the additional overhead of a pipe to pass
  # the editor commands.

  # Check for the ENABLE/DISBALE flag (also serves as a format sanity check)

  FLAG=`sed -n "$OFFSET p" <$SRVFILE`
#echo FLAG=$FLAG
  if [ "$FLAG" = "ENABLE" ];
  then
    # check that we accept this file format version
    OFF=`expr $OFFSET + 1`
#echo OFF=$OFF
    VER=`sed -n "$OFF p" <$SRVFILE`
#echo VER=$VER
    if [ $VER -ne $FORMATVERSION ];
    then
      if [ "$COUNT_DISABLED" = "TRUE" ];
      then
        echo $0: The SAS server configuration file '"'$SRVFILE'"'
        echo appears to be an incompatible format, expected $FORMATVERSION
        echo This SAS server instance will be ignored.
        echo
        ERRIGNORED=`expr $ERRIGNORED + 1`
      fi
      return 1
    fi
    # get the path to the SAS server control script, also used for server.pid
    OFF=`expr $OFFSET + 2`
#echo OFF=$OFF
    CONTROLPATH=`sed -n "$OFF p" <$SRVFILE`
#echo CONTROLPATH=$CONTROLPATH

    # get the path to the SAS server logs
    OFF=`expr $OFFSET + 3`
#echo OFF=$OFF
    LOGPATH=`sed -n "$OFF p" <$SRVFILE`
#echo LOGPATH=$LOGPATH

    # get the server context, if any, equal NULL if none
    OFF=`expr $OFFSET + 4`
#echo OFF=$OFF
    SCONTEXT=`sed -n "$OFF p" <$SRVFILE`
#echo SCONTEXT=$SCONTEXT

  elif [ "$FLAG" = "DISABLE" ]; # a valid file has ENABLE or DISABLE only
  then
    if [ "$COUNT_DISABLED" = "TRUE" ];
    then
      echo $0: The SAS server configuration file '"'$SRVFILE'"'
      echo specifies the DISABLE keyword, so this SAS server instance
      echo will be ignored.
      echo
      IGNORED=`expr $IGNORED + 1`
    fi
    return 1
  else
    if [ "$COUNT_DISABLED" = "TRUE" ];
    then
      echo $0: The SAS server configuration file '"'$SRVFILE'"'
      echo appears to be improperly formatted. The ENABLE/DISABLE flag is
      echo not at the expected file offset.
      echo This SAS server instance will be ignored.
      echo
      ERRIGNORED=`expr $ERRIGNORED + 1`
    fi
    return 1
  fi
  return 0
}

#
# generate_section - append code fragment for each server instance
#
# input:
#  $1  server instances (paths) 
#  $2  server type (e.g. METADATA, OLAP, etc.)
#  $3  template file (lives in $SCRIPTDIR)
#
#  SCRIPTDIR and SCRIPTNAME should be defined before calling this routine
#
generate_section()
{  
#echo generate_section parm1 is $1
  INSTANCE=1
  if [ -n "$1" ];
  then
  {
    for srv in $1
    do
      if [ $INSTANCE -gt $MAX_INSTANCES ];
      then
      {
        echo "Warning: There are too many instances of server type $2."
        echo "A maximum of $MAX_INSTANCES are supported per configuration."
        echo "The remaining instances of $2 will be ignored."
        break;
      }
      fi

#echo generate_section srv is $srv
      get_paths "$srv"
      if [ $? -eq 0 ];  # the parse worked, CONTROLPATH and LOGPATH valid
      then
        sed -e "{
                  s@^$2_DIR=@&\"$CONTROLPATH\"@
                  s@^$2_LOGS=@&\"$LOGPATH\"@
                  s@^$2_CONTEXT=@&\"$SCONTEXT\"@
                  s@_INSTANCE@$INSTANCE@g
                }" <$SCRIPTDIR/$3 >> $SCRIPTNAME

        INSTANCE=`expr $INSTANCE + 1`
      fi
    done
  }
  fi
}


#
# Main code path
#


#
# Determine the target system type
#

SCRIPTPROLOG=
OSTYPE=

case "`uname -s`" in

  AIX)
    OSTYPE="aix"
    SCRIPTPROLOG="$SCRIPTDIR/sas.servers_aix.prolog"
    ;;

  Linux)
    grep -i 'Red Hat' /proc/version >/dev/null 2>&1
    if [ $? -eq 0 ];
    then
      OSTYPE="rhel"
      SCRIPTPROLOG="$SCRIPTDIR/sas.servers_rhel.prolog"
    fi

    grep -i 'SUSE Linux' /proc/version >/dev/null 2>&1
    if [ $? -eq 0 ];
    then
      OSTYPE="sles"
      SCRIPTPROLOG="$SCRIPTDIR/sas.servers_sles.prolog"
    fi

    if [ -z $OSTYPE ];
    then
      echo $0: "Expected Red Hat or SUSE Linux,"
      echo 'Got "'`cat /proc/version`'"'
      echo
      echo "At present, only Red Hat and SUSE Linux are supported for SAS."
      echo "The generated script may work with other Linux distributions,"
      echo "but you should review it to insure compatibility. The Red Hat"
      echo "version of the generated script will be created as the default."

      OSTYPE="rhel"
      SCRIPTPROLOG="$SCRIPTDIR/sas.servers_rhel.prolog"
    fi
    ;;

  HP-UX)
    OSTYPE="hpux"
    SCRIPTPROLOG="$SCRIPTDIR/sas.servers_hpux.prolog"
    ;;

  SunOS)
    OSTYPE="sun"
    SCRIPTPROLOG="$SCRIPTDIR/sas.servers_sun.prolog"
    ;;

  *)
    echo $0: "Couldn't determine the OS type for processing."
    echo "Giving up..."
    echo
    exit 1
    ;;

esac

MYPATH="$LEVELDIR"
#echo MYPATH is $MYPATH

SCRIPTPRETEMPLATE="$SCRIPTDIR/sas.servers.pre.template"
SCRIPTMIDTEMPLATE="$SCRIPTDIR/sas.servers.mid.template"

SCRIPTMAIN="$SCRIPTDIR/sas.servers.mainlog"
SCRIPTEPILOG="$SCRIPTDIR/sas.servers.epilog"

#
# Minor sanity check - can we get to required directories?
#
if [ ! \( -d $SCRIPTDIR -a -x $SCRIPTDIR \) ];
then
  echo $0: 'Cannot access the required SAS script prototypes directory'
  echo '"'$SCRIPTDIR'"'
  echo
  exit 1
fi

if [ ! \( -d $LEVELDIR -a -w $LEVELDIR \) ];
then
  echo $0: 'Cannot write to the required SAS script target directory'
  echo '"'$SCRIPTDIR'"'
  echo
  exit 1
fi

#
# Minor sanity check - can we read the prolog file (exists)?
#
if [ ! -r "$SCRIPTPROLOG" ];
then
  echo $0: 'Cannot read required OS script prolog file "'$SCRIPTPROLOG'"'
  echo
  exit 1
fi

#
# Minor sanity check - can we read the native output messages file
# (exists)?
#
if [ ! -r "$SASMSGFILE" ];
then
  echo $0: 'Cannot read expected OS script messages file "'$SASMSGFILE'"'
  echo
#
# Minor sanity check - can we read the default English output messages file
# (exists)?
#
  if [ ! -r "$SASMSGFILE_EN" ];
  then
    echo $0: 'Cannot read required OS script messages file "'$SASMSGFILE_EN'"'
    echo
    exit 1
  fi
  echo 'Continuing with default English messages.'
fi

#
# Minor sanity check - can we read the main file (exists)?
#
if [ ! -r "$SCRIPTMAIN" ];
then
  echo $0: 'Cannot read required OS script main script file "'$SCRIPTMAIN'"'
  echo
  exit 1
fi

#
# Minor sanity check - can we read the epilog file (exists)?
#
if [ ! -r "$SCRIPTEPILOG" ];
then
  echo $0: 'Cannot read required OS script epilog file "'$SCRIPTEPILOG'"'
  echo
  exit 1
fi


#
# See if the user wishes to disable default invocation of the sas.server.pre
# and/or sas.servers.mid scripts.
#

SCRIPT_PRE="YES"
SCRIPT_MID="YES"
MYCMD="$0"

while [ -n "$1" ]; do
{
  case "$1" in
    -nopre)
      SCRIPT_PRE=""
      ;;

    -nomid)
      SCRIPT_MID=""
      ;;

    -pre)
      SCRIPT_PRE="YES"
      ;;

    -mid)
      SCRIPT_MID="YES"
      ;;

    *)
      echo "Usage:  $MYCMD  [OPTION ...]"
      echo "  -pre     invoke sas.servers.pre as part of sas.servers"
      echo "  -mid     invoke sas.servers.mid as part of sas.servers"
      echo "  -nopre   do not invoke sas.servers.pre as part of sas.servers"
      echo "  -nomid   do not invoke sas.servers.mid as part of sas.servers"
      echo " "
      echo "  with no options, default is $MYCMD -pre -mid"
      exit 1;
  esac

  shift;  # next arg, if any
}
done;

#echo SCRIPT_PRE is "$SCRIPT_PRE"
#echo SCRIPT_MID is "$SCRIPT_MID"
#echo MYCMD is "$MYCMD"

#
# Determine what and how many of each SAS server type are presently
# installed in this configuration (rooted at LEVELDIR).
#

#
# Accumulate a list of the .srv configuration files for each SAS server
# type. These files are emitted by the ConfigWizard during installation,
# and contain required SAS server install path information.
#
# 9.3: The list of files is bracketed with double-quotes via the enclosed
# "sed" command so that spaces in pathnames are handled correctly. Normally,
# UNIX people don't embed spaces in paths or filenames, but the SAS SDW allows
# it, so we have to expect the possibility.
#
# Metadata is a special-case: with 9.3, a "Backups" directory may be created
# within the subtree, containing a copy of the .srv file which we should ignore.
#
TMPFILE=/tmp/sas.servers.tmp

# test write to TMPFILE

echo "test write" > $TMPFILE 2>/dev/null
if [ $? -ne 0 ];
then
{
  echo $0: Cannot write to temp file '"'$TMPFILE'"'
  echo Check directory and file permissions.  Aborting.
  exit 1
}
fi

# special-case: use only the first one found to avoid duplicates from backups
find $LEVELDIR -name MetadataServer.srv -print > $TMPFILE
METADATA=`sed -n -e '1s/\ /#/g' -e '1p' $TMPFILE`
#echo METADATA $METADATA

#
find $LEVELDIR -name OLAPServer.srv -print > $TMPFILE
OLAP=`sed -e 's/\ /#/g' $TMPFILE`
#echo OLAP $OLAP

find $LEVELDIR -name ConnectSpawner.srv -print > $TMPFILE
CONNECT=`sed -e 's/\ /#/g' $TMPFILE`
#echo CONNECT $CONNECT

find $LEVELDIR -name ShareServer.srv -print > $TMPFILE
SHARE=`sed -e 's/\ /#/g' $TMPFILE`
#echo SHARE $SHARE

find $LEVELDIR -name ObjectSpawner.srv -print > $TMPFILE
OBJSPAWN=`sed -e 's/\ /#/g' $TMPFILE`
#echo OBJSPAWN $OBJSPAWN

find $LEVELDIR -name MerchIntelGridServer.srv -print > $TMPFILE
MERCHINTELGRID=`sed -e 's/\ /#/g' $TMPFILE`
#echo MERCHINTELGRID $MERCHINTELGRID

find $LEVELDIR -name TableServer.srv -print > $TMPFILE
TABLESRV=`sed -e 's/\ /#/g' $TMPFILE`
#echo TABLESRV $TABLESRV

#
# Deprecated at 9.4 - left for doc purposes
#
#find $LEVELDIR -name RemoteServices.srv -print > $TMPFILE
#REMOTE=`sed -e 's/\ /#/g' $TMPFILE`
REMOTE=
#echo REMOTE $REMOTE

find $LEVELDIR -name DeploymentTesterServer.srv -print > $TMPFILE
DEPLOYSRV=`sed -e 's/\ /#/g' $TMPFILE`
#echo DEPLOYSRV $DEPLOYSRV

find $LEVELDIR -name AnalyticsPlatform.srv -print > $TMPFILE
ANALYTICS=`sed -e 's/\ /#/g' $TMPFILE`
#echo ANALYTICS $ANALYTICS

find $LEVELDIR -name dffedsvrcfg.srv -print > $TMPFILE
FRAMEDATASRV=`sed -e 's/\ /#/g' $TMPFILE`
#echo FRAMEDATASRV $FRAMEDATASRV

find $LEVELDIR -name DIPJobRunner.srv -print > $TMPFILE
DIP=`sed -e 's/\ /#/g' $TMPFILE`
#echo DIP $DIP

#
# clean up
#
if [ -f $TMPFILE ];
then
  rm $TMPFILE
fi

#
# If the files exist, make a backup copy in Backup folder
#
BACKUP_FLD=$LEVELDIR/Backup
RUNTIME=`date +"%Y-%m-%d-%H.%M.%S"`
if [ -f $SCRIPTNAME ]; then
   if [ ! -d $BACKUP_FLD ]; then
       mkdir $BACKUP_FLD
   fi
   SCRIPTNAMEBACK="$BACKUP_FLD/$SCRIPTFILE-$RUNTIME.bak"
   mv $SCRIPTNAME $SCRIPTNAMEBACK
fi
if [ -f $SCRIPTNAMEPRE ]; then
   if [ ! -d $BACKUP_FLD ]; then
       mkdir $BACKUP_FLD
   fi
   SCRIPTNAMEPREBACK="$BACKUP_FLD/$SCRIPTFILEPRE-$RUNTIME.bak"
   mv $SCRIPTNAMEPRE $SCRIPTNAMEPREBACK
fi
if [ -f $SCRIPTNAMEMID ]; then
   if [ ! -d $BACKUP_FLD ]; then
       mkdir $BACKUP_FLD
   fi
   SCRIPTNAMEMIDBACK="$BACKUP_FLD/$SCRIPTFILEMID-$RUNTIME.bak"
   mv $SCRIPTNAMEMID $SCRIPTNAMEMIDBACK
fi

#
# Copy the machine-specific script prolog to the destination, applying
# required symbol updates.
#

sed -e "{
          s/^SERVERUSER=/&$SERVERUSER/
          s/^STARTCMD=/&$STARTCMD/
          s/^STOPCMD=/&$STOPCMD/
          s/^STATUSCMD=/&$STATUSCMD/
          s/^RESTARTCMD=/&$RESTARTCMD/
        }"  <$SCRIPTPROLOG >$SCRIPTNAME

###
# Special processing to create a sas.servers.pre script to start/stop the 
#   SAS WIP Data Server
# It is invoked by code in the "start.prolog" file.
###
sed -e "{
          s/^SERVERUSER=/&$SERVERUSER/
          s%^LEVELDIR=%&$LEVELDIR%
          s%^SCRIPTDIR=%&$SCRIPTDIR%
          s/^STARTCMD=/&$STARTCMD/
          s/^STOPCMD=/&$STOPCMD/
          s/^STATUSCMD=/&$STATUSCMD/
          s/^RESTARTCMD=/&$RESTARTCMD/
          s/^OSTYPE=/&$OSTYPE/
        }"  <$SCRIPTPRETEMPLATE >$SCRIPTNAMEPRE
# make executable
chmod 0700 $SCRIPTNAMEPRE

###
# Special processing to create a sas.servers.mid script to start/stop (if required) the
#   activeMQ
#   SAS Web App Server
#   GemFire
#   SAS Environment Manager Server
#   SAS Environment Manager Agent
# It is invoked by code in the "start.epilog" file.
###
sed -e "{
          s/^SERVERUSER=/&$SERVERUSER/
          s%^LEVELDIR=%&$LEVELDIR%
          s%^SCRIPTDIR=%&$SCRIPTDIR%
          s/^STARTCMD=/&$STARTCMD/
          s/^STOPCMD=/&$STOPCMD/
          s/^STATUSCMD=/&$STATUSCMD/
          s/^RESTARTCMD=/&$RESTARTCMD/
          s/^OSTYPE=/&$OSTYPE/
        }"  <$SCRIPTMIDTEMPLATE >$SCRIPTNAMEMID
# make executable
chmod 0700 $SCRIPTNAMEMID

#
# Copy the expected native output messages definition file to destination.
# If it is not readable, fall back to the English version of the messages.
#
if [ -r "$SASMSGFILE" ];
then
  cat $SASMSGFILE >>$SCRIPTNAME
else
#
# Copy the default English output messages definition file to the destination.
# (Since we made it past earlier sanity checks, we know that the English
# version is readable.)
#
  cat $SASMSGFILE_EN >>$SCRIPTNAME
fi

#
# Copy the main set of functional routines to the destination. 
#
cat $SCRIPTMAIN >>$SCRIPTNAME

#
# For each instance of each SAS server installed, add code snippets
# to start the particular server instance.
#

# used by the get_paths function defined above
IGNORED=0     # server instances that are ignored due to DISABLE 
ERRIGNORED=0  # server instances that are ignored due to error

### cat $SCRIPTDIR/start.prolog >>$SCRIPTNAME

sed -e "{
          s%^MYPATH=%&$MYPATH%
          s%^SCRIPT_PRE=%&$SCRIPT_PRE%
        }"  <$SCRIPTDIR/start.prolog >>$SCRIPTNAME

#
# Tell the internal routines to count DISABLEd server instances. We call
# generate_section in multiple phases for each server, so we only want to
# flag DISABLEd servers upon first discovery.
#
COUNT_DISABLED=TRUE

# SAS Metadata Servers
generate_section "$METADATA" METADATA_SERVER metadatasrv_start.template 

# SAS OLAP Servers
generate_section "$OLAP" OLAP_SERVER olapsrv_start.template

# SAS Object Spawners
generate_section "$OBJSPAWN" OBJECT_SPAWNER objspawn_start.template

# SAS Share Servers
generate_section "$SHARE" SHARE_SERVER sharesrv_start.template

# SAS Connect Servers
generate_section "$CONNECT" CONNECT_SPAWNER connectspawner_start.template

# SAS Table Servers
generate_section "$TABLESRV" TABLE_SERVER tablesrv_start.template

# SAS SAS Merchandise Intelligence Grid Server
generate_section "$MERCHINTELGRID" MERCH_INTEL_GRID merchintelgridsrv_start.template

# SAS Remote Services
generate_section "$REMOTE" REMOTE_SERVICES remotesrv_start.template

# SAS Deployment Tester Server
generate_section "$DEPLOYSRV" DEPLOYMENT_TESTSRV deptestsrv_start.template

# SAS Analytics Platform Server
generate_section "$ANALYTICS" ANALYTICS_PLATFORM analyticsplatform_start.template

# SAS Framework Data Server
generate_section "$FRAMEDATASRV" FRAMEDATA_SERVER framedatasrv_start.template

# SAS DIP Job Runner
generate_section "$DIP" DIP_JOBRUNNER dip_start.template

#
# SAS Information Retrieval Studio Server is a special-case
# It doesn't follow the convention of a <server>.srv file, but only one
# instance should exist, at a fixed path off of LEVELDIR.
#

if [ -x "$IRSS_SERVER_DIR/IRStudio.sh" ];
then
{
  sed -e "{
          s%^IRSS_SERVER_DIR=%&\"$IRSS_SERVER_DIR\"%
        }"  <$SCRIPTDIR/inforetrievstudio_start.template >>$SCRIPTNAME
}
fi

#
# SAS Federation Server is a special-case
# It doesn't follow the convention of a <server>.srv file, but only one
# instance should exist, at a fixed path off of LEVELDIR.
#

if [ -x "$FEDERATION_SERVER_DIR/bin/dfsadmin.sh" ];
then
{
  sed -e "{
          s%^FEDERATION_SERVER_DIR=%&\"$FEDERATION_SERVER_DIR\"%
        }"  <$SCRIPTDIR/fedserver_start.template >>$SCRIPTNAME
}
fi

#
# Close out the start routine
#

### cat $SCRIPTDIR/start.epilog >>$SCRIPTNAME

sed -e "{
          s%^MYPATH=%&$MYPATH%
          s%^SCRIPT_MID=%&$SCRIPT_MID%
        }"  <$SCRIPTDIR/start.epilog >>$SCRIPTNAME

#
# For each instance of each SAS server installed, add code snippets
# to stop the particular server instance. This is in reverse order
# to the start operations above.
#

### cat $SCRIPTDIR/stop.prolog >>$SCRIPTNAME

sed -e "{
          s%^MYPATH=%&$MYPATH%
          s%^SCRIPT_MID=%&$SCRIPT_MID%
        }"  <$SCRIPTDIR/stop.prolog >>$SCRIPTNAME


#
# Tell the internal routines to NOT count DISABLEd server instances. We call
# generate_section in multiple phases for each server, so we only want to
# flag DISABLEd servers upon first discovery.
#
COUNT_DISABLED=FALSE

#
# SAS Federation Server is a special-case
# It doesn't follow the convention of a <server>.srv file, but only one
# instance should exist, at a fixed path off of LEVELDIR.
#

if [ -x "$FEDERATION_SERVER_DIR/bin/dfsadmin.sh" ];
then
{
  sed -e "{
          s%^FEDERATION_SERVER_DIR=%&\"$FEDERATION_SERVER_DIR\"%
        }"  <$SCRIPTDIR/fedserver_stop.template >>$SCRIPTNAME
}
fi

#
# SAS Information Retrieval Studio Server is a special-case
# It doesn't follow the convention of a <server>.srv file, but only one
# instance should exist, at a fixed path off of LEVELDIR.
#

if [ -x "$IRSS_SERVER_DIR/IRStudio.sh" ];
then
{
  sed -e "{
          s%^IRSS_SERVER_DIR=%&\"$IRSS_SERVER_DIR\"%
        }"  <$SCRIPTDIR/inforetrievstudio_stop.template >>$SCRIPTNAME
}
fi

# SAS DIP Job Runner
generate_section "$DIP" DIP_JOBRUNNER dip_stop.template

# SAS Framework Data Server
generate_section "$FRAMEDATASRV" FRAMEDATA_SERVER framedatasrv_stop.template

# SAS Analytics Platform Server
generate_section "$ANALYTICS" ANALYTICS_PLATFORM analyticsplatform_stop.template

# SAS Deployment Tester Server
generate_section "$DEPLOYSRV" DEPLOYMENT_TESTSRV deptestsrv_stop.template

# SAS Remote Services
generate_section "$REMOTE" REMOTE_SERVICES remotesrv_stop.template

# SAS SAS Merchandise Intelligence Grid Server
generate_section "$MERCHINTELGRID" MERCH_INTEL_GRID merchintelgridsrv_stop.template

# SAS Table Servers
generate_section "$TABLESRV" TABLE_SERVER tablesrv_stop.template

# SAS Connect Servers
generate_section "$CONNECT" CONNECT_SPAWNER connectspawner_stop.template

# SAS Share Servers
generate_section "$SHARE" SHARE_SERVER sharesrv_stop.template

# SAS Object Spawners
generate_section "$OBJSPAWN" OBJECT_SPAWNER objspawn_stop.template

# SAS OLAP Servers
generate_section "$OLAP" OLAP_SERVER olapsrv_stop.template

# SAS Metadata Servers
generate_section "$METADATA" METADATA_SERVER metadatasrv_stop.template

#
# Close out the stop routine
#

### cat $SCRIPTDIR/stop.epilog >>$SCRIPTNAME

sed -e "{
          s%^MYPATH=%&$MYPATH%
          s%^SCRIPT_PRE=%&$SCRIPT_PRE%
        }"  <$SCRIPTDIR/stop.epilog >>$SCRIPTNAME

#
# For each instance of each SAS server installed, add code snippets
# to check status of the particular server instance. 
#

### cat $SCRIPTDIR/status.prolog >>$SCRIPTNAME

sed -e "{
          s%^MYPATH=%&$MYPATH%
          s%^SCRIPT_PRE=%&$SCRIPT_PRE%
        }"  <$SCRIPTDIR/status.prolog >>$SCRIPTNAME

#
# Tell the internal routines to NOT count DISABLEd server instances. We call
# generate_section in multiple phases for each server, so we only want to
# flag DISABLEd servers upon first discovery.
#
COUNT_DISABLED=FALSE

# SAS Metadata Servers
generate_section "$METADATA" METADATA_SERVER metadatasrv_status.template

# SAS OLAP Servers
generate_section "$OLAP" OLAP_SERVER olapsrv_status.template

# SAS Object Spawners
generate_section "$OBJSPAWN" OBJECT_SPAWNER objspawn_status.template

# SAS Share Servers
generate_section "$SHARE" SHARE_SERVER sharesrv_status.template

# SAS Connect Servers
generate_section "$CONNECT" CONNECT_SPAWNER connectspawner_status.template

# SAS Table Servers
generate_section "$TABLESRV" TABLE_SERVER tablesrv_status.template

# SAS SAS Merchandise Intelligence Grid Server
generate_section "$MERCHINTELGRID" MERCH_INTEL_GRID merchintelgridsrv_status.template

# SAS Remote Services
generate_section "$REMOTE" REMOTE_SERVICES remotesrv_status.template

# SAS Deployment Tester Server
generate_section "$DEPLOYSRV" DEPLOYMENT_TESTSRV deptestsrv_status.template

# SAS Analytics Platform Server
generate_section "$ANALYTICS" ANALYTICS_PLATFORM analyticsplatform_status.template

# SAS Framework Data Server
generate_section "$FRAMEDATASRV" FRAMEDATA_SERVER framedatasrv_status.template

# SAS DIP Job Runner
generate_section "$DIP" DIP_JOBRUNNER dip_status.template

#
# SAS Information Retrieval Studio Server is a special-case
# It doesn't follow the convention of a <server>.srv file, but only one
# instance should exist, at a fixed path off of LEVELDIR.
#

if [ -x "$IRSS_SERVER_DIR/IRStudio.sh" ];
then
{
  sed -e "{
          s%^IRSS_SERVER_DIR=%&\"$IRSS_SERVER_DIR\"%
        }"  <$SCRIPTDIR/inforetrievstudio_status.template >>$SCRIPTNAME
}
fi

#
# SAS Federation Server is a special-case
# It doesn't follow the convention of a <server>.srv file, but only one
# instance should exist, at a fixed path off of LEVELDIR.
#

if [ -x "$FEDERATION_SERVER_DIR/bin/dfsadmin.sh" ];
then
{
  sed -e "{
          s%^FEDERATION_SERVER_DIR=%&\"$FEDERATION_SERVER_DIR\"%
        }"  <$SCRIPTDIR/fedserver_status.template >>$SCRIPTNAME
}
fi


#
# Close out the status routine
#

### cat $SCRIPTDIR/status.epilog >>$SCRIPTNAME

sed -e "{
          s%^MYPATH=%&$MYPATH%
          s%^SCRIPT_MID=%&$SCRIPT_MID%
        }"  <$SCRIPTDIR/status.epilog >>$SCRIPTNAME

#
# Finish with the main section
#

### cat $SCRIPTDIR/sas.servers.epilog >>$SCRIPTNAME

sed -e "{
          s%^LEVELDIR=%&$LEVELDIR%
        }" <$SCRIPTDIR/sas.servers.epilog >>$SCRIPTNAME

#
# Make it executable
#

chmod 700 $SCRIPTNAME

#
# print some status
#

if [ $IGNORED -gt 0 -o $ERRIGNORED -gt 0 ];
then
  echo $IGNORED SAS servers were explicitly disabled in their .srv files.
  echo $ERRIGNORED SAS servers were disabled by an apparent error in their .srv files.
  echo
fi

# 
# clean up backups if no changes
#
if [ -f "$SCRIPTNAMEBACK" ]; then
   if `diff -b $SCRIPTNAME $SCRIPTNAMEBACK >/dev/null` ; then
     rm $SCRIPTNAMEBACK
   fi
fi
if [ -f "$SCRIPTNAMEPREBACK" ]; then
   if `diff -b $SCRIPTNAMEPRE $SCRIPTNAMEPREBACK >/dev/null` ; then
     rm $SCRIPTNAMEPREBACK
   fi
fi
if [ -f "$SCRIPTNAMEMIDBACK" ]; then
   if `diff -b $SCRIPTNAMEMID $SCRIPTNAMEMIDBACK >/dev/null` ; then
     rm $SCRIPTNAMEMIDBACK
   fi
fi

exit 0

