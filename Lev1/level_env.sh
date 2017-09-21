#!/bin/sh
#
# level_env.sh
#
#   Set environment variables relative to the configuration level structure
#

LEVEL_ROOT=/opt/sas/config/Lev1
UTILITIES=/opt/sas/sashome/SASDeploymentManager/9.4/products/cfgwizard__94486__prt__xx__sp0__1/Utilities
DEPLOYWIZ=/opt/sas/sashome/SASDeploymentManager/9.4/products/deploywiz__94486__prt__xx__sp0__1/deploywiz
SAS_HOME=/opt/sas/sashome
JAVA_JRE_COMMAND=/opt/sas/sashome/SASPrivateJavaRuntimeEnvironment/9.4/jre/bin/java

SASVJR_HOME=/opt/sas/sashome/SASVersionedJarRepository
SASVJR_REPOSITORYPATH=/opt/sas/sashome/SASVersionedJarRepository/eclipse
SASWebInfrastructurePlatform_HOME=/opt/sas/sashome/SASWebInfrastructurePlatform/9.4
SASROOT=/opt/sas/sashome/SASFoundation/9.4
SAS_COMMAND=$SASROOT/sas





. $LEVEL_ROOT/level_env_usermods.sh

# source hadoop_env.sh if available
if [ -f $LEVEL_ROOT/hadoop_env.sh ]; then
    . $LEVEL_ROOT/hadoop_env.sh
fi

#
# These environment variables allow sas.servers and server component
# scripts to find the correct pid file.
#
SHOSTNAME=`hostname | awk -F. '{ printf $1 }'`
SERVER_PID_FILE_NAME="server.$SHOSTNAME.pid"
export SERVER_PID_FILE_NAME
