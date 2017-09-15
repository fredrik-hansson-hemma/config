#!/bin/bash

local_host="$(hostname)"
# Tar bort allt efter första punkten
local_host="${local_host%%.*}"


# Loopar igenom servrarna i filen /etc/gridhosts. Filen läses nerifrån och upp för att huvudnoden ska stängas av sist!
for hst in `tac /etc/gridhosts`
do
	echo
	if [ "$local_host" != "$hst" ]
	then
		ssh $hst "hostname; echo \ /opt/sas/config/Lev1/sas.servers stop; /opt/sas/config/Lev1/sas.servers stop;"
		echo 
		ssh $hst "hostname; echo \ /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh stop; /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh stop;"
	else
		echo "=========================================================================================================================="
		echo "Command was not run for $hst (local host). Local host should be shut down manually after running this script.";
		echo "=========================================================================================================================="
	fi
	echo 
done 


