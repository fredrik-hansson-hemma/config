#!/bin/sh -p
#
# ObjectSpawner_usermods.sh
#
# This script extends ObjectSpawner.sh  Add local environment variables
# to this file so they will be preserved.
#
 
# These options can be extended as needed.

# The following section pertains to establishing JREOPTIONS for use by the
# Spawner. These options are not enabled by default but are present here to 
# allow for customer activation.

# JREOPTIONS will be processed and passed directly to the Object Spawner if active
JREOPTIONS=
# JREOPTIONS="-jreoptions '(           -DPFS_TEMPLATE=/opt/sas/sashome/SASFoundation/9.4/misc/tkjava/qrpfstpt.xml         -Djava.class.path=/opt/sas/sashome/SASVersionedJarRepository/eclipse/plugins/sas.launcher.jar         -Djava.security.auth.login.config=/opt/sas/sashome/SASFoundation/9.4/misc/tkjava/sas.login.config         -Djava.security.policy=/opt/sas/sashome/SASFoundation/9.4/misc/tkjava/sas.policy         -Djava.system.class.loader=com.sas.app.AppClassLoader         -Dlog4j.configuration=file:/opt/sas/sashome/SASFoundation/9.4/misc/tkjava/sas.log4j.properties         -Dsas.app.class.path=/opt/sas/sashome/SASVersionedJarRepository/eclipse/plugins/tkjava.jar         -Dsas.ext.config=/opt/sas/sashome/SASFoundation/9.4/misc/tkjava/sas.java.ext.config         -Dtkj.app.launch.config=/opt/sas/sashome/SASVersionedJarRepository/picklist          )'"

# The following options are passed to the Object Spawner. Note, they must be
# valid options.
USERMODS=$JREOPTIONS
