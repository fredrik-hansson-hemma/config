/************************************
* Macro: LADDA_RYGGSACKSFILER
* 
* L�ser Ryggs�cksfiler fr�n FTP. F�r Akademiska och Enk�ping.
*
* Skapad: 2016-09-28, Mattias Moliis
************************************/


  
* Data mellanlagras p� Public Server;
libname pub "/opt/sas/config/Lev1/AppData/SASVisualAnalytics/VisualAnalyticsAdministrator/PublicDataProvider";  
* VA LASR Public; 
LIBNAME LASRLIB SASIOLA  TAG=VAPUBLIC  PORT=10031 HOST="bs-ap-20.lul.se"  SIGNER="https://bs-ap-20.lul.se:443/SASLASRAuthorization" ;


options validvarname = any validmemname=extend;

%LET VDB_GRIDHOST=bs-ap-20.lul.se;
%LET VDB_GRIDINSTALLLOC=/opt/sas/TKGrid;
options set=GRIDHOST="bs-ap-20.lul.se";
options set=GRIDINSTALLLOC="/opt/sas/TKGrid";



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



%global MINST_ETT_ERR;
%let MINST_ETT_ERR=NEJ;



%macro ladda_ryggsacksfiler(filnamn=, namn_i_VA=);

	%put ;
	%put ;
	%put ;
	%put ;
	%put P�b�rjar inl�sning av &filnamn;
	%put ;
	%put ;

	filename fil_ftp ftp "&filnamn"	user='ASBS' pass='gM6175g' host='infr-ftp-01.lul.se';
	filename fil_locl "/tmp/&filnamn";
	filename fil_rm pipe "rm %sysfunc(pathname(fil_locl))";


	%* Flagga som avg�r om textfilen ska/kan importeras eller ej.	;
	%local AVBRYT_IMPORT;
	%let AVBRYT_IMPORT=NEJ;

	%put H�mtar fil fr�n FTP till lokal katalog	;
	data _null_;
		rc=fcopy("fil_ftp", "fil_locl");
		if rc NE 0 then do;
			put "%str(ER)ROR: N�got gick fel vid h�mtning av fil %sysfunc(pathname(fil_ftp)) --> %sysfunc(pathname(fil_locl)). Returkoden blev: " rc=;
			call symputx('MINST_ETT_ERR', 'JA', GLOBAL);
			call symputx('AVBRYT_IMPORT', 'JA', LOCAL);
		end;
		else do;
			put "�verf�ringen lyckades!";
		end;
	run;


	%if &AVBRYT_IMPORT=JA %then %do;
		%put %str(ER)ROR: Avbryter importen av &filnamn;
		%return;
	%end;


	%put L�ser in data med hj�lp av proc import	;
	proc import file=fil_locl out=pub.&namn_i_VA. dbms=TAB replace;
		guessingrows=32767;
	run;

	
	%put Tar bort lokal fil	;
	data _null_;
		infile fil_rm;
	run;



	%put Droppar existerande VA-tabell			;
	%vdb_dt(LASRLIB.&namn_i_VA.);

	%put Laddar upp tabellen i lasr-libnamet	;
	data LASRLIB.&namn_i_VA.;
		set PUB.&namn_i_VA.;
	run;	

	%put Registrerar tabellen i Metadata		;
	%registerTable(
					LIBRARY=%nrstr(/Shared Data/SAS Visual Analytics/Public/Visual Analytics Public LASR)
					, REPOSITORY=%nrstr(Foundation)
					, TABLE=&namn_i_VA.
					, FOLDER=%nrstr(/LUL/Tillg�nglighet/Data)
					);

	%put Sl�pper filenames	;
	filename fil_ftp clear;
	filename fil_locl clear;
	filename fil_rm clear;

%mend ladda_ryggsacksfiler;




%ladda_ryggsacksfiler(	filnamn=OP_O_BEH_K�LLDATA_KALLE.TXT,
						namn_i_VA=OP_O_BEH_KALLDATA_V2);
%ladda_ryggsacksfiler(	filnamn=FORSTA_BESOK_KALLDATA_KALLE.TXT,
						namn_i_VA=FORSTA_BESOK_KALLDATA_V2);
%ladda_ryggsacksfiler(	filnamn=RYGGSACK_BESO.TXT,
						namn_i_VA=RYGGSACK_BESO_V2);
%ladda_ryggsacksfiler(	filnamn=RYGGSACK_OP.TXT,
						namn_i_VA=RYGGSACK_OP_V2);





%* Ser till att programmet avslutas med en felkod om MINST_ETT_ERR=JA	;
%macro check_for_errors;
	%if &MINST_ETT_ERR=JA %then %abort abend;
%mend check_for_errors;

%check_for_errors