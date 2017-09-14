#!/bin/bash

# Loopar igenom servrarna i filen /etc/gridhosts. Filen läses nerifrån och upp för att huvudnoden ska stängas av sist!
i=1
for hst in `tac /etc/gridhosts`
do
	echo 
	ssh $hst "hostname; echo \ /opt/sas/config/Lev1/sas.servers stop; /opt/sas/config/Lev1/sas.servers stop;"
	echo 
	ssh $hst "hostname; echo \ /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh stop; /opt/sas/sashome/SASDeploymentAgent/9.4/agent.sh stop;"
	echo
	i=$((i + 1))
done 