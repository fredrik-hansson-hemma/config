#!/bin/sh
#
# launchconfig.sh
#
# Two environment variables must be set before executing this script
# 
# STDLOGNAME - path to the log file that will be created
# STDCFGPROP - path to ant properties
#
# Additional environment variables are required launchant.sh
#
# Uncomment the set -x to run in debug mode
# set -x

. $LEVEL_ROOT/level_env.sh

`dirname $0`/launchant.sh -l "$STDLOGNAME" -Dconfiguration.properties.file="$STDCFGPROP" $*
