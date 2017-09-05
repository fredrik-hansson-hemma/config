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
# Version V1.1 for SLES (LAX/LNX)
#
# This script assumes that all listed SAS servers will be run on this
# same platform. We do not check for, nor start SAS servers on remote
# platforms.
#
# If installed local to this machine, the SAS Metadata Server(s) must start 
# successfully before attempts are made to start the other dependent servers. 
#
# The following voodoo is used by SLES to install the script in the init.d
# configuration for the appropriate runlevels.
#
### BEGIN INIT INFO
# Provides: sas-bi
# Required-Start: $local_fs $network $remote_fs $named $syslog
# Required-Stop: $local_fs $network $remote_fs $named $syslog
# Default-Start:  3 5
# Default-Stop:   0 1 2 6
# Short-Description: SAS BI servers
# Description:    Bring up the local SAS BI servers in sequence, starting with
#       SAS Metadata Server. The other SAS BI servers depend upon it. The
#       script contains logic to probe the server logfiles to insure that
#       they have come up to a functional state.
### END INIT INFO
#
#
# To install this script, as user "root", invoke:
#
#   cp sas.servers /etc/init.d
#   /sbin/insserv -d sas.servers
#
# The -d option tells the system to use the runlevels as defined in the INIT
# comment block above. You can also explictly set the runlevels. See
#     man 8 insserv
# for more details.
#
# To remove the script from all runlevels, as user "root", invoke:
#
#   insserv -r sas.servers
#
# This script is intended to run upon entering runlevels 3 and/or 5.
#
# SUSE Linux implements a system command that uses the BEGIN INIT INFO
# comment block above to determine how to configure service start scripts and
# at what runlevels they should be invoked.
#
# Under SLES, runlevels 3 and 5 are multi-user with network support. Level 5
# adds X display manager support. Level 0 is system halt, level 1 is
# single-user mode, 2 is local multi-user (no network), and 6 is system reboot.
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
TAIL="/usr/bin/tail -n "   # the trailing space is important
GREP="grep -a"

