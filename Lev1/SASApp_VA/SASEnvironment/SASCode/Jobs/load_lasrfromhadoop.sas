/*********************************************
 * Macro: Load_LASRfromHadoop_bst
 * Laddar tabeller från Hadoop in i LASR servern.
 * Skriver ut de tabeller som ska laddas till Hadoop i tabell
 * LOG
 * VATABLE: Tabell som ska laddas in i LASR-server. 
 * Om blankt laddas alla tabeller som finns i Hadoop.
 *********************************************/
%macro load_lasrfromhadoop(VATABLE=, TAG=, PATH=, PORT=, SIGNER=);
	%put ENTER: load_lasrfromhadoop;

	%if "VATABLE" = "" %then %do;
		%put Alla tabeller från Hadoop kommer att laddas in i LASR-minnet.;
	%end;

	%if "VATABLE" ne "" %then %do;
		%put Tabell &vatable från Hadoop kommer att laddas in i LASR-minnet.;
	%end;

	%LET VDB_GRIDHOST=bs-ap-20.lul.se;
	%LET VDB_GRIDINSTALLLOC=/opt/sas/TKGrid;
	options set=GRIDHOST="bs-ap-20.lul.se";
	options set=GRIDINSTALLLOC="/opt/sas/TKGrid";
	options validvarname=any validmemname=extend noerrorabend;

	proc printto print='/tmp/procoutput.lst';
	run;

	* Olika Signer per LASR-server.;
	LIBNAME LASR SASIOLA  TAG=&tag  PORT=&port HOST="bs-ap-20.lul.se"  SIGNER="&signer";
	LIBNAME HADOOP SASHDAT  PATH="&path"  SERVER="bs-ap-20.lul.se"  INSTALL="/opt/sas/TKGrid";

	* Hämtar alla tabeller som finns i Hadoop.;
	proc sql noprint;
		create table hadooptables as
		select memname from dictionary.tables
		where upcase(libname) = "HADOOP"
		%if "&vatable" ne "" %then %do;
			and upcase(memname) = "&vatable"
		%end;
	;
	quit;

	* Hämtar alla tabeller som finns i LASR servern.;
	proc sql noprint;
		create table lasrtables as
		select memname from dictionary.tables
		where upcase(libname) = "LASR"
		%if "&vatable" ne "" %then %do;
			and upcase(memname) = "&vatable"
		%end;
	;
	quit;

	* Sparar de tabeller som finns i Hadoop och som inte finns i LASR servern.;
	proc sql noprint;

		create table loadtablesfromhadoop as
		select hadoop.memname
		from hadooptables as hadoop
		where hadoop.memname not in (select memname from lasrtables);
	quit;

	%let dsid = %sysfunc(open(loadtablesfromhadoop));


	%do %while ((%sysfunc(fetch(&dsid))) = 0);

		%let loadtable=%upcase(%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,memname)))));
		%put LOADTABLE= &loadtable;

		proc lasr port=&port.
			data=HADOOP.&loadtable
			signer="&signer"
			add noclass;
    		performance host="bs-ap-20.lul.se";
		run;

	%end;

	%let dsid = %sysfunc(close(&dsid));

	proc printto;
	run;


	LIBNAME LASR clear;
	LIBNAME HADOOP clear;

	%put EXIT: load_lasrfromhadoop_bst;

%mend;



* ===============================================================================	;
* Verkar inte alltid vara nödvändigt, men kan behövas för att slippa
* "ER ROR: Unable to connect to Metadata Server"
* ===============================================================================	;
options metaserver="bs-ap-20.lul.se"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="{sas002}7D55EB1F27B29BC354FD035416238B741C2BF86732381F40"
	metarepository="Foundation";


* mprint underlättar copy-paste från loggen om man skulle behöva köra om något	;
options mprint;

* Anrop	;
%load_lasrfromhadoop(VATABLE=, TAG=hps, PATH=/hps, PORT=10011, SIGNER=https://bs-ap-20.lul.se:443/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=epj, PATH=/epj, PORT=10015, SIGNER=https://bs-ap-20.lul.se:443/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=lrc, PATH=/lrc, PORT=10016, SIGNER=https://bs-ap-20.lul.se:443/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=ftv, PATH=/ftv, PORT=10017, SIGNER=https://bs-ap-20.lul.se:443/SASLASRAuthorization);







* ===============================================================================	;
* Hårdkodat för att köra en enskild tabell
* ===============================================================================	;
/*
%let VATABLE=lul_kvalitet_levnadsvanor_pv;
%let TAG=hps;
%let PATH=/hps;
%let PORT=10011;
%let SIGNER=https://bs-ap-20.lul.se:443/SASLASRAuthorization;

LIBNAME LASR SASIOLA  TAG=&tag  PORT=&port HOST="bs-ap-20.lul.se"  SIGNER="&signer";
LIBNAME HADOOP SASHDAT  PATH="&path"  SERVER="bs-ap-20.lul.se"  INSTALL="/opt/sas/TKGrid";

proc lasr port=&port
	data=HADOOP.&VATABLE
	signer="&signer"
	add noclass;
	performance host="bs-ap-20.lul.se";
run;
*********/