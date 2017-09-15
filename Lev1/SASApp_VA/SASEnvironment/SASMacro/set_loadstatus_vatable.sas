/*****************************************************************************
* Macro: set_loadstatus_vatable                     
* Kontrollerar om datalagret �r klart f�r l�sning. 
*
* Av: Mattias Moliis, Infotrek
* Datum: 2014-04-03
* Parametrar: 
* VATABLE: Tabell som har laddats in i VA.
*
* �ndringar:
******************************************************************************/


%macro set_loadstatus_vatable(vatable=);
%put Enter set_loadstatus_vatable: VATABLE: &vatable;

%let vatable = %upcase(&vatable.);

%if not %sysfunc(exist(LOG.&vatable)) %then %do;
	%put LOG.&vatable finns inte och kommer att skapas.;
	data LOG.&vatable.;
		attrib vatable length=$30. label="VA Tabell";
		attrib loadtime length=8. format=datetime20.;
    stop;
 	run;
%end;

%let loadtime = %sysfunc(datetime());

proc sql noprint;
	insert into LOG.&vatable. values ("&vatable.", &loadtime.);
quit;

%put Exit set_loadstatus_vatable.;
%mend;

* Exempel p� anrop;
%*set_loadstatus_vatable(vatable=VARDKONTAKT);


