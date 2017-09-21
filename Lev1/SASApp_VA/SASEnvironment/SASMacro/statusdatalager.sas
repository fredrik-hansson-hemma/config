/*****************************************************************************
* Macro: StatusDatalager                     
* Kontrollerar om datalagret är klart för läsning. 
*
* Av: Mattias Moliis, Infotrek
* Datum: 2014-02-26
* Parametrar: 
* STATUSTABLE: Loggtabell för datalagret.
* VATABLE: VA tabell som ska laddas.
*
* Ändringar:
* 2016-09-22 Mattias, Tagit bort körningsloggning.
* 2017-02-27 Mattias, lagt till parameter Polla (JA/NEJ). Om Polla=JA går jobbet
* i viloläge om datalagret inte är klart att laddas från. Jobbet vilar 60 min innan
* ny koll av statusflagga. Provar max 8 gånger innan jobbet avbryts. 
* 
******************************************************************************/


%macro statusDatalager(statustable=, vatable=, polla=NEJ);
%put Enter statusDatalager Statustable: &statustable VA tabell: &vatable Polla: &polla.;
%let laddflagga = 0; * LADDFLAGGA: Anger om datalagret är klart för att läsa;

%let dw = %get_dwlib(); 
%put MILJÖ FÖR DATALAGRET: &dw;
/*
data tst;
set &dw..&statustable.;
run;
*/
%*if not %sysfunc(exist(&dw..&statustable.)) %then %do;
%*put &dw..&statustable finns inte eller är inte åtkomlig. Programmet avbryts.;
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
 * Fel värde för loadstatus.;
 %put Loadstatus är &loadstatus..Värde 0 eller 1 förväntas. Programmet avbryts.;
 %abort abend;
%end;

%if &loadstatus = 0 and %upcase("&polla") = "NEJ" %then %do;
 * Datalagret är inte klart att läsa ännu.;
 %put Loadstatus är &loadstatus..Datalagret är inte klart att läsa ännu. Programmet avbryts.;
 %abort return 9;
%end; * end: if &loadstatus = 0;

%if &loadstatus = 0 and %upcase("&polla") = "JA" %then %do;
 * Datalagret är inte klart att läsa ännu.;
 %let count=1;

 %do %until (&count=9);
   %put Loadstatus är &loadstatus..Datalagret är inte klart att läsa ännu. Försök nr &count av 8;

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
		%*put Senaste laddtid i LOG.&vatable. är %sysfunc(putn(&loadtime., yymmdd10.)). Tabellen &vatable har redan laddats för %sysfunc(putn(&today., yymmdd10.)).; 
		%*put Programmet avbryts.;
  	%*abort abend;
  %*end;

	%*else %goto EXIT; 
 
%*end; * end: if &loadstatus = 1;

%EXIT:
%put Datalagret är klart att läsa. Loadstatus är &loadstatus..;/* Senaste laddtid i LOG.&vatable. är %sysfunc(putn(&loadtime., yymmdd10.)).;*/
%mend;

* Exempel på anrop;
%*statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL);
%*statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL, polla=JA);



