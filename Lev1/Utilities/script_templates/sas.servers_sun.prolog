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
# Version V1.1 for Solaris (S64/SAX)
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
#    cp ./sas.servers /etc/init.d/sas.servers
#    chown root /etc/init.d/sas.servers
#    chmod 0744 /etc/init.d/sas.servers
#    ln /etc/init.d/sas.servers /etc/rc3.d/S99sas.servers
#    ln /etc/init.d/sas.servers /etc/rc0.d/K99sas.servers
#
# Under Solaris, when entering a run level, the "K" scripts are run for
# that level, then the "S" scripts are run for that level.
# The "99sas" above insures that the SAS Servers script is one of the last to
# execute at boot, allowing NFS, etc. to start up first. The "S" link
# will be executed at startup and the "K" link will be executed at shutdown.
#
# Level 3 (rc3.d) is the normal multi-user run state for Solaris with NFS
# resources available.
# Level 0 (rc0.d) is the level the system transitions to during a shutdown
# and/or restart.
#
# You may wish to add additional "K" file links to the rc.d directories
# for the single-user levels rcS.d and rc1.d, and for the power-down and reboot
# levels rc5.d and rc6.d to insure that the SAS servers are only running
# in multi-user/NFS mode.
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
WHOAMI="/usr/ucb/whoami"
TAIL="/usr/xpg4/bin/tail -n "  # syntax different from deprecated /usr/bin/tail
                               # the trailing space is important
GREP="grep"

