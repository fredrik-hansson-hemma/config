/*****************************************************************************
* Macro: StatusDatalager                     
* Kontrollerar om datalagret �r klart f�r l�sning. 
*
* Av: Mattias Moliis, Infotrek
* Datum: 2014-02-26
* Parametrar: 
* STATUSTABLE: Loggtabell f�r datalagret.
* VATABLE: VA tabell som ska laddas.
*
* �ndringar:
* 2016-09-22 Mattias, Tagit bort k�rningsloggning.
* 2017-02-27 Mattias, lagt till parameter Polla (JA/NEJ). Om Polla=JA g�r jobbet
* i vilol�ge om datalagret inte �r klart att laddas fr�n. Jobbet vilar 60 min innan
* ny koll av statusflagga. Provar max 8 g�nger innan jobbet avbryts. 
* 
******************************************************************************/


%macro statusDatalager(statustable=, vatable=, polla=NEJ);
%put Enter statusDatalager Statustable: &statustable VA tabell: &vatable Polla: &polla.;
%let laddflagga = 0; * LADDFLAGGA: Anger om datalagret �r klart f�r att l�sa;

%let dw = %get_dwlib(); 
%put MILJ� F�R DATALAGRET: &dw;
/*
data tst;
set &dw..&statustable.;
run;
*/
%*if not %sysfunc(exist(&dw..&statustable.)) %then %do;
%*put &dw..&statustable finns inte eller �r inte �tkomlig. Programmet avbryts.;
%*abort abend;
%*end; * end: if not %sysfunc(exist(&dw..&statustable));

%*if not %sysfunc(exist(LOG.&vatable)) %then %do;
	%*put LOG.&vatable finns inte och kommer att skapas.;
	*data LOG.&vatable.;
	*	attrib vatable length=$30. label="VA Tabell";
	*	attrib loadtime length=8. format=datetime20.;
  *  stop;
 	*run;
%*end; * end: if not %sysfunc(exist(LOG.&vatable));

%let dsid = %sysfunc(open(&dw..&statustable.));
%let rc=%sysfunc(fetchobs(&dsid,1));
%let loadstatus=%sysfunc(getvarn(&dsid,%sysfunc(varnum(&dsid,loadstatus))));
%put LOADSTATUS: &loadstatus.;
%let dsid = %sysfunc(close(&dsid));

%if (&loadstatus ne 0 and &loadstatus ne 1) %then %do;
 * Fel v�rde f�r loadstatus.;
 %put Loadstatus �r &loadstatus..V�rde 0 eller 1 f�rv�ntas. Programmet avbryts.;
 %abort abend;
%end;

%if &loadstatus = 0 and %upcase("&polla") = "NEJ" %then %do;
 * Datalagret �r inte klart att l�sa �nnu.;
 %put Loadstatus �r &loadstatus..Datalagret �r inte klart att l�sa �nnu. Programmet avbryts.;
 %abort return 9;
%end; * end: if &loadstatus = 0;

%if &loadstatus = 0 and %upcase("&polla") = "JA" %then %do;
 * Datalagret �r inte klart att l�sa �nnu.;
 %let count=1;

 %do %until (&count=9);
   %put Loadstatus �r &loadstatus..Datalagret �r inte klart att l�sa �nnu. F�rs�k nr &count av 8;

	 %let rc = %sysfunc(sleep(3600,1));

	 %let dsid = %sysfunc(open(&dw..&statustable.));
   %let rc=%sysfunc(fetchobs(&dsid,1));
   %let loadstatus=%sysfunc(getvarn(&dsid,%sysfunc(varnum(&dsid,loadstatus))));
   %let dsid = %sysfunc(close(&dsid));

   %if &loadstatus = 1 %then %goto EXIT;
   %else %if &loadstatus = 0 %then %do;
     %let count = %eval(&count+1);
	 %end;	  

  %end;
 
  %abort return 9;
%end; * end: if &loadstatus = 0;

%*if &loadstatus = 1 %then %do;

	* proc sql noprint;
	*  select datepart(max(loadtime)) into: loadtime
  *		from LOG.&vatable.;
	* quit;


  %*let today = %sysfunc(today()); * Dagens datum;
  %*if &today eq &loadtime %then %do;
		%*put Senaste laddtid i LOG.&vatable. �r %sysfunc(putn(&loadtime., yymmdd10.)). Tabellen &vatable har redan laddats f�r %sysfunc(putn(&today., yymmdd10.)).; 
		%*put Programmet avbryts.;
  	%*abort abend;
  %*end;

	%*else %goto EXIT; 
 
%*end; * end: if &loadstatus = 1;

%EXIT:
%put Datalagret �r klart att l�sa. Loadstatus �r &loadstatus..;/* Senaste laddtid i LOG.&vatable. �r %sysfunc(putn(&loadtime., yymmdd10.)).;*/
%mend;

* Exempel p� anrop;
%*statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL);
%*statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL, polla=JA);



