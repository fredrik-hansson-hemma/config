#!/bin/sh
#
# launchant.sh
#
# Three environment variables must be set before executing this script
# 
# DEPLOYWIZ - path to the log file that will be created
# UTILITIES - path to the ant configuration xml file
#
# Generally, these values will be set by executing level_env.sh
#
# Uncomment the set -x to run in debug mode
# set -x

. $LEVEL_ROOT/level_env.sh

"/opt/sas/sashome/SASPrivateJavaRuntimeEnvironment/9.4/jre/bin/java" -classpath "$DEPLOYWIZ/ant-launcher.jar" org.apache.tools.ant.launch.Launcher -Dant.home="$DEPLOYWIZ" -Dinstall.cfgwizard.utilities.dir="$UTILITIES" -Dtemp.dir="$LEVEL_ROOT/Logs/Configure" $*
