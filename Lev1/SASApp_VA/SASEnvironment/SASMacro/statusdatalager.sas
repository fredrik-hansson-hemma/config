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
	%local loadstatus;

	%put Enter statusDatalager Statustable: &statustable VA tabell: &vatable Polla: &polla.;
	%let laddflagga = 0;	* LADDFLAGGA: Anger om datalagret är klart för att läsa;

	%let dw = %get_dwlib();
	%put MILJÖ FÖR DATALAGRET: &dw;

	%* Kontrollerar att libnamet existerar;
	%if (%sysfunc(libref(&dw))) %then %put %sysfunc(sysmsg());


	%macro get_loadstatus();
		%local loadstatus;
		%let dsid = %sysfunc(open(&dw..&statustable.));
		%let rc=%sysfunc(fetchobs(&dsid,1));
		%let loadstatus=%sysfunc(getvarn(&dsid,%sysfunc(varnum(&dsid,loadstatus))));
		%put LOADSTATUS: &loadstatus.;
		%let dsid = %sysfunc(close(&dsid));
		&loadstatus
	%mend get_loadstatus;

	%let loadstatus=%get_loadstatus();


	%* Datalagret visar loadstatus=1. Klart att ladda!	;
	%if &loadstatus eq 1 %then %do;
		%goto EXIT;
	%end;
	

	%* Datalagret visar loadstatus=0 (ej klart att ladda). Om polla=JA, så väntar vi ett tag och prövar igen.	;
	%else %if &loadstatus = 0 %then %do;

		%if %upcase("&polla") = "NEJ" %then %do;
			* Datalagret är inte klart att läsa ännu.;
			%put Loadstatus är &loadstatus..Datalagret är inte klart att läsa ännu. Programmet avbryts.;
			%abort cancel 9;
		%end;

		%else %if %upcase("&polla") = "JA" %then %do;

			* Datalagret är inte klart att läsa ännu.;
			%let count=1;


			%do %until (&count=9);

				%local sleep_time_seconds;
				%let sleep_time_seconds=3600;

				%put Loadstatus är &loadstatus..Datalagret är inte klart att läsa ännu. Försök nr &count av 8;
				%put Väntar &sleep_time_seconds sekunder innan nästa försök;


				%let rc = %sysfunc(sleep(&sleep_time_seconds,1));

				%let loadstatus=%get_loadstatus();

				%if &loadstatus = 1 %then %do;
					%goto EXIT;
				%end;
				%else %if &loadstatus = 0 %then %do;
					%let count = %eval(&count+1);
				%end;

			%end;

			%* Avbryter programmet efter ett antal försök.	;
			%abort return 9;
		%end;
		%else %do;
			%put "Oväntat fel i macrot statusdatalager. Programmet avbryts.";
			%abort cancel;
		%end;

	%end /* end: if &loadstatus = 0 */;	

	%* loadstatus har ett oväntat värde. Programmet avbryts.	;
	%else %do;
		* Fel värde för loadstatus.;
		%put Loadstatus är &loadstatus.. Värde 0 eller 1 förväntas. Programmet avbryts.;
		%abort cancel;
	%end;

	%EXIT:
	%put Datalagret är klart att läsa. Loadstatus är &loadstatus..;

%mend statusDatalager;

* Exempel på anrop;
%*statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL);
%statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL, polla=JA);