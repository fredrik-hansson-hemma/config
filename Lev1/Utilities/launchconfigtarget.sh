#!/bin/sh
#
# launchconfigtarget.sh
#
# Two environment variables must be set before executing this script
# 
# STDLOGNAME - path to the log file that will be created
# TWELVEBYTE - then 12byte code for the product being configured
# 
# all arguments passed on the command line are passed along as is
# minimally -f <configXML> and <target> are needed
#
# Uncomment the set -x to run in debug mode
# set -x

. $LEVEL_ROOT/level_env.sh

STDCFGPROP="$LEVEL_ROOT/Utilities/$TWELVEBYTE.configuration.properties"
export STDCFGPROP

"$LEVEL_ROOT/../Utilities/launchconfig.sh" $*
