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
	%local loadstatus;

	%put Enter statusDatalager Statustable: &statustable VA tabell: &vatable Polla: &polla.;
	%let laddflagga = 0;	* LADDFLAGGA: Anger om datalagret �r klart f�r att l�sa;

	%let dw = %get_dwlib();
	%put MILJ� F�R DATALAGRET: &dw;

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
	

	%* Datalagret visar loadstatus=0 (ej klart att ladda). Om polla=JA, s� v�ntar vi ett tag och pr�var igen.	;
	%else %if &loadstatus = 0 %then %do;

		%if %upcase("&polla") = "NEJ" %then %do;
			* Datalagret �r inte klart att l�sa �nnu.;
			%put Loadstatus �r &loadstatus..Datalagret �r inte klart att l�sa �nnu. Programmet avbryts.;
			%abort cancel 9;
		%end;

		%else %if %upcase("&polla") = "JA" %then %do;

			* Datalagret �r inte klart att l�sa �nnu.;
			%let count=1;


			%do %until (&count=9);

				%local sleep_time_seconds;
				%let sleep_time_seconds=3600;

				%put Loadstatus �r &loadstatus..Datalagret �r inte klart att l�sa �nnu. F�rs�k nr &count av 8;
				%put V�ntar &sleep_time_seconds sekunder innan n�sta f�rs�k;


				%let rc = %sysfunc(sleep(&sleep_time_seconds,1));

				%let loadstatus=%get_loadstatus();

				%if &loadstatus = 1 %then %do;
					%goto EXIT;
				%end;
				%else %if &loadstatus = 0 %then %do;
					%let count = %eval(&count+1);
				%end;

			%end;

			%* Avbryter programmet efter ett antal f�rs�k.	;
			%abort return 9;
		%end;
		%else %do;
			%put "Ov�ntat fel i macrot statusdatalager. Programmet avbryts.";
			%abort cancel;
		%end;

	%end /* end: if &loadstatus = 0 */;	

	%* loadstatus har ett ov�ntat v�rde. Programmet avbryts.	;
	%else %do;
		* Fel v�rde f�r loadstatus.;
		%put Loadstatus �r &loadstatus.. V�rde 0 eller 1 f�rv�ntas. Programmet avbryts.;
		%abort cancel;
	%end;

	%EXIT:
	%put Datalagret �r klart att l�sa. Loadstatus �r &loadstatus..;

%mend statusDatalager;

* Exempel p� anrop;
%*statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL);
%statusDatalager(statustable=VW_SYSTEMLOAD, vatable=PERSONAL, polla=JA);