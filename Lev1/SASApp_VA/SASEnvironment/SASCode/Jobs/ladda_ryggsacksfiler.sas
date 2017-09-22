/************************************
* Macro: LADDA_RYGGSACKSFILER
* 
* Läser Ryggsäcksfiler från FTP. För Akademiska och Enköping.
*
* Skapad: 2016-09-28, Mattias Moliis
************************************/


/* FTP mot fil */
filename fil_a ftp "OP_O_BEH_KÄLLDATA_KALLE.TXT"		user='ASBS' pass='gM6175g' host='infr-ftp-01.lul.se';
filename fil_b ftp "FORSTA_BESOK_KALLDATA_KALLE.TXT"	user='ASBS' pass='gM6175g' host='infr-ftp-01.lul.se';
filename fil_c ftp "RYGGSACK_BESO.TXT"					user='ASBS' pass='gM6175g' host='infr-ftp-01.lul.se';
filename fil_d ftp "RYGGSACK_OP.TXT"					user='ASBS' pass='gM6175g' host='infr-ftp-01.lul.se';

filename fil_ut_a "/tmp/OP_O_BEH_KALLDATA_KALLE.txt";
filename fil_ut_b "/tmp/FORSTA_BESOK_KALLDATA_KALLE.txt";
filename fil_ut_c "/tmp/RYGGSACK_BESO.txt";
filename fil_ut_d "/tmp/RYGGSACK_OP.txt";

/* Tar bort filer på Linux */
filename bort_a pipe "rm /tmp/OP_O_BEH_KALLDATA_KALLE.txt";
filename bort_b pipe "rm /tmp/FORSTA_BESOK_KALLDATA_KALLE.txt";
filename bort_c pipe "rm /tmp/RYGGSACK_BESO.txt";
filename bort_d pipe "rm /tmp/RYGGSACK_OP.txt";



  
* Data mellanlagras på Public Server;
libname pub "/opt/sas/config/Lev1/AppData/SASVisualAnalytics/VisualAnalyticsAdministrator/PublicDataProvider";  
* VA LASR Public; 
LIBNAME LASRLIB SASIOLA  TAG=VAPUBLIC  PORT=10031 HOST="bs-ap-20.lul.se"  SIGNER="https://bs-ap-20.lul.se:443/SASLASRAuthorization" ;

options validvarname = any validmemname=extend;

%LET VDB_GRIDHOST=bs-ap-20.lul.se;
%LET VDB_GRIDINSTALLLOC=/opt/TKGrid;
options set=GRIDHOST="bs-ap-20.lul.se";
options set=GRIDINSTALLLOC="/opt/TKGrid";



/* Register Table Macro */
%macro registertable( REPOSITORY=Foundation, REPOSID=, LIBRARY=, TABLE=, FOLDER=, TABLEID=, PREFIX= );
	/* Mask special characters */
	%let REPOSITORY=%superq(REPOSITORY);
	%let LIBRARY =%superq(LIBRARY);
	%let FOLDER =%superq(FOLDER);
	%let TABLE =%superq(TABLE);
	%let REPOSARG=%str(REPNAME="&REPOSITORY.");

	%if ("&REPOSID." ne "") %THEN %LET REPOSARG=%str(REPID="&REPOSID.");

	%if ("&TABLEID." ne "") %THEN %LET SELECTOBJ=%str(&TABLEID.);
	%else %LET SELECTOBJ=&TABLE.;

	%if ("&FOLDER." ne "") %THEN %PUT INFO: Registering &FOLDER./&SELECTOBJ. to &LIBRARY. library.;
	%else %PUT INFO: Registering &SELECTOBJ. to &LIBRARY. library.;

	proc metalib;
		omr (	library="&LIBRARY."
				%str(&REPOSARG.) );

		%if ("&TABLEID." eq "") %THEN %DO;
			%if ("&FOLDER." ne "") %THEN %DO;
				folder="&FOLDER.";
			%end;
		%end;

		%if ("&PREFIX." ne "") %THEN %DO;
			prefix="&PREFIX.";
		%end;

		select ("&SELECTOBJ.");
	run;
	quit;

%mend;



%global MINST_ETT_ERROR;
%let MINST_ETT_ERROR=NEJ;



%macro ladda_ryggsacksfiler(fil=, fil_ut=, va_ds=);

	%local AVBRYT_IMPORT;
	%let AVBRYT_IMPORT=NEJ;

	%put Hämtar fil från FTP till lokal katalog	;
	data _null_;
		rc=fcopy("&fil", "&fil_ut.");
		if rc NE 0 then do;
			put "ERROR: Något gick fel vid hämtning av fil %sysfunc(pathname(&fil)) --> %sysfunc(pathname(&fil_ut)). Returkoden blev: " rc=;
			call symputx('MINST_ETT_ERROR', 'JA', GLOBAL);
			call symputx('AVBRYT_IMPORT', 'JA', LOCAL);
		end;
	run;


	%if &AVBRYT_IMPORT=JA %then %do;
		%put ERROR: Avbryter importen av %sysfunc(pathname(&fil));
		%return;
	%end;


	%put Läser in data med hjälp av proc import	;
	proc import file=&fil_ut. out=pub.&va_ds. dbms=TAB replace;
		guessingrows=32767;
	run;


	%put Droppar existerande VA-tabell			;
	%vdb_dt(LASRLIB.&va_ds.);

	%put Laddar upp tabellen i lasr-libnamet	;
	data LASRLIB.&va_ds.;
		set PUB.&va_ds.;
	run;	

	%put Registrerar tabellen i Metadata		;
	%registerTable(
					LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR)
					, REPOSITORY=%nrstr(Foundation)
					, TABLE=&va_ds.
					, FOLDER=%nrstr(/LUL/Tillgänglighet/Data)
					);

%mend;
 
%ladda_ryggsacksfiler(fil=fil_a, fil_ut=fil_ut_a, va_ds=OP_O_BEH_KALLDATA_V2);
%ladda_ryggsacksfiler(fil=fil_b, fil_ut=fil_ut_b, va_ds=FORSTA_BESOK_KALLDATA_V2);
%ladda_ryggsacksfiler(fil=fil_c, fil_ut=fil_ut_c, va_ds=RYGGSACK_BESO_V2);
%ladda_ryggsacksfiler(fil=fil_d, fil_ut=fil_ut_d, va_ds=RYGGSACK_OP_V2);


/* Tar bort fil på Linux. */

data _null_;
	infile bort_a;
	infile bort_b;
	infile bort_c;
	infile bort_d;
run;
;




%* Ser till att programmet avslutas med en felkod om MINST_ETT_ERROR=JA	;
%macro check_for_errors;
	%if &MINST_ETT_ERROR=JA %then %abort abend;
%mend check_for_errors;

%check_for_errors