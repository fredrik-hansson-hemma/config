#!/bin/bash

# Loopar igenom servrarna i filen /etc/gridhosts.
echo 
echo "======== Notera att det här rogrammet inte kontrollerar status på SASDeploymentAgent eftersom den inte verkar ha någon status-funktionalitet"
echo 
i=1
for hst in `tac /etc/gridhosts`
do
	echo 
	ssh $hst "hostname; echo \ /opt/sas/config/Lev1/sas.servers status; /opt/sas/config/Lev1/sas.servers status;"
	echo
	i=$((i + 1))
done 