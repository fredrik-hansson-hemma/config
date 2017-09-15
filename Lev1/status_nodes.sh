#!/bin/bash
echo "================================================================================================"
echo 
echo "Loopar igenom servrarna i filen /etc/gridhosts och anropar kommandot"
echo "/opt/sas/config/Lev1/sas.servers status"
echo 
echo "Notera att det här rogrammet inte kontrollerar status på SASDeploymentAgent"
echo "eftersom den inte verkar ha någon status-funktionalitet"
echo 
echo "================================================================================================"
for hst in `tac /etc/gridhosts`
do
	echo 
	ssh $hst "hostname; /opt/sas/config/Lev1/sas.servers status;"
	echo
done 