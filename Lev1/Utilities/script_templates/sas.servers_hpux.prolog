#!/bin/sh
#
# Copyright 2008,2010 SAS Institute Inc.
# SAS Campus Drive, Cary, North Carolina 27513, USA. 
# All rights reserved.
#
#set -v
#echo "running sas.servers"
#
# Boot-time script for SAS 9.2 BI Servers
# Version V1.1 for HP-UX (H64/H6I)
#
# This script assumes that all listed SAS servers will be run on this
# same platform. We do not check for, nor start SAS servers on remote
# platforms.
#
# If installed local to this machine, the SAS Metadata Server(s) must start 
# successfully before attempts are made to start the other dependent servers. 
#
# The script is intended to run at boot level 3.
#
# Install as follows:
#
#    cp ./sas.servers /sbin/rc/sas.servers
#    chown root /sbin/rc/sas.servers
#    chmod 0744 /sbin/rc/sas.servers
#    ln /sbin/rc/sas.servers /sbin/rc3.d/S999sas.servers
#    ln /sbin/rc/sas.servers /sbin/rc2.d/K100sas.servers
# 
# Under HP-UX, the rcN.d "S" scripts are run when transitioning from a
# lower run level to level N, and the rc(N-1).d "K" scripts are run when
# transitioning from run level N to N-1. The scripts are run in alphabetical
# order, so the leading digits control when in the series of scripts 
# particular ones will run. The above numbers for SAS were chosen so that
# the start "S" script will be one of the last to run when entering this level,
# allowing NFS, etc. to be started before the SAS servers, and the stop "K" 
# script will be one of the first to run when going to a lower run level.
#
# Version 1.1 - added some support for NLS
#*****

#*****
# To avoid protection issues with installs mounted over NFS, this
# script has to run under the same UID as that which owns the installed
# SAS code. Define that UID here.
#*****
SERVERUSER=

#*****
# Commands passed to the server control scripts
#*****
STARTCMD=
STOPCMD=
RESTARTCMD=
STATUSCMD=

#*****
# Specify certain commands explicitly
#*****
WHOAMI="/usr/bin/whoami"
TAIL="/usr/bin/tail -n "        # the trailing space is important
GREP="grep"

