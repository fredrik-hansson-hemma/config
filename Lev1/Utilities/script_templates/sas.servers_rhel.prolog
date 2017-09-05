#!/bin/sh
#
# Copyright 2008,2010,2013 SAS Institute Inc.
# SAS Campus Drive, Cary, North Carolina 27513, USA. 
# All rights reserved.
#
#set -v
#echo "running sas.servers"
#
# Boot-time script for SAS 9.4+ BI Servers and mid-tier
# Version V1.2 for RHEL (LAX/LNX)
#
# This script assumes that all listed SAS servers will be run on this
# same platform. We do not check for, nor start SAS servers on remote
# platforms.
#
# If installed local to this machine, the SAS Metadata Server(s) must start 
# successfully before attempts are made to start the other dependent servers. 
#
# The following voodoo is used by RHEL to install the script in the init.d
# configuration for the appropriate runlevels.
#
###
# chkconfig: 35 90 01
# description: Bring up the local SAS BI servers in sequence, starting with \
#       SAS Metadata Server.
###
#
# As user "root", copy the sas.servers script (not .pre or .mid) to /etc/init.d:
#
#   # cd <sasconfigdir>/Lev1
#   # cp sas.servers /etc/init.d
#   # chmod 0755 /etc/init.d/sas.servers
#
# To install this script as bootable, as user "root", invoke:
#
#   # /sbin/chkconfig --add sas.servers
#   # /sbin/chkconfig --level 35 sas.servers on
#   # /sbin/chkconfig --list sas.servers
#
# The "--add" (the double-dash is correct) tells chkconfig to add this boot
# service type to the system. The "--level 35" with the "on" tells chkconfig
# to arrange for this service to start at run levels 3 and 5.
#
# To verify that the installation succeeded, invoke:
#
#   /sbin/chkconfig --list sas.servers
#
# This should show which run levels the sas.servers script will start under.
#
# See
#     man 8 chkconfig
# for more details.
#
# To remove the script from all runlevels, as user "root", invoke:
#
#   /sbin/chkconfig --del sas.servers
#
# This script is intended to run upon entering runlevels 3 and/or 5.
#
# Under RHEL, runlevels 3 and 5 are multi-user with network support. Level 5
# adds X display manager support. Level 0 is system halt, level 1 is
# single-user mode, and 6 is system reboot. Levels 2 and 4 are unassigned.
#
# Version 1.1 - added some support for NLS
# Version 1.2 - added instructions to copy script to init.d
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

