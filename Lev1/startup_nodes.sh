#!/bin/bash

# Loopar igenom servrarna i filen /etc/gridhosts.
i=1
for hst in `cat /etc/gridhosts`
do
	echo 
	ssh $hst "hostname; echo \ /opt/sas/config/Lev1/sas.servers start; /opt/sas/config/Lev1/sas.servers start;"
	echo 
	ssh $hst "hostname; echo \ /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh start; /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh start;"
	echo
	i=$((i + 1))
done 