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
# Version V1.1 for z/OS
#
# This script assumes that all listed SAS servers will be run on this
# same platform. We do not check for, nor start SAS servers on remote
# platforms.
#
# If installed local to this machine, the SAS Metadata Server(s) must start 
# successfully before attempts are made to start the other dependent servers. 
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
WHOAMI="/bin/whoami"
TAIL="/bin/tail -n "        # the trailing space is important
GREP="grep"
