#!/bin/bash

local_host="$(hostname)"
# Tar bort allt efter första punkten
local_host="${local_host%%.*}"

# Loopar igenom servrarna i filen /etc/gridhosts. Kör inte kommandot för local host.
for hst in `tac /etc/gridhosts`
do
	echo 
	if [ "$local_host" != "$hst" ]
	then
		ssh $hst "hostname; echo \ /opt/sas/config/Lev1/sas.servers start; /opt/sas/config/Lev1/sas.servers start;"
		echo 
		ssh $hst "hostname; echo \ /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh start; /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh start;"
	else
		echo "=========================================================================================================================="
		echo "Command was not run for $hst (local host). Local host should have been started manually before running this script.";
		echo "=========================================================================================================================="
	fi
	echo 
done 
