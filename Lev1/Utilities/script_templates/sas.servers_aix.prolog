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
# Version V1.1 for AIX (R64)
#
# This script assumes that all listed SAS servers will be run on this
# same platform. We do not check for, nor start SAS servers on remote
# platforms.
#
# If installed local to this machine, the SAS Metadata Server(s) must start 
# successfully before attempts are made to start the other dependent servers. 
#
# The script is intended to run at boot run level 2. Note that this level
# is roughly equivalent to run level 3 on SunOS and HP-UX.
#
# Install as follows:
#
#    cp ./sas.servers /etc/rc.d/rc2.d/S99sas.servers
#    cp ./sas.servers /etc/rc.d/rc2.d/K01sas.servers
#    chown root /etc/rc.d/rc2.d/S99sas.servers
#    chown root /etc/rc.d/rc2.d/K01sas.servers
#    chmod 0744 /etc/rc.d/rc2.d/S99sas.servers
#    chmod 0744 /etc/rc.d/rc2.d/K01sas.servers
# 
# AIX behaves somewhat differently with respect to handling rc scripts
# as compared to SunOS, HP-UX, and Linux. Run level "2" is the normal
# multi-user level for AIX. When transitioning into a run level, AIX will
# execute the "K" scripts it finds at the current level to shut down related 
# processes, usually in "sort" order, and will then execute the "S" scripts 
# it finds at the new level to start those related processes. Unlike Linux 
# and HP-UX which transition to a new run level 6 for a reboot and execute 
# related scripts at that level, during a shutdown AIX will execute the "K" 
# scripts at the current level to shut down related processes. Then, the 
# AIX "init" task itself issues SIGTERM to all processes at the current 
# level that will not exist at the new level, waits twenty seconds, then 
# issues SIGKILL to any remaining processes.
# It so happens that SAS servers typically respond to SIGTERM as a
# shutdown request, so this is actually OK.
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
TAIL="/usr/bin/tail -n "          # the trailing space is important
GREP="grep"

