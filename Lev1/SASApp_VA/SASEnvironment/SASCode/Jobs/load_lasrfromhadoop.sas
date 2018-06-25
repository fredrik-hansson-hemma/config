/*********************************************
 * Macro: Load_LASRfromHadoop
 * Laddar tabeller från Hadoop in i LASR servern.
 * Skriver ut de tabeller som ska laddas till Hadoop i tabell
 * LOG
 * VATABLE: Tabell som ska laddas in i LASR-server. 
 * Om blankt laddas alla tabeller som finns i Hadoop.
 *********************************************/
%macro load_lasrfromhadoop(VATABLE=, TAG=, PATH=, PORT=, SIGNER=);
	%put ENTER: load_lasrfromhadoop;

	%put &=VATABLE;
	%put &=TAG;
	%put &=PATH;
	%put &=PORT;
	%put &=SIGNER;



	%if "VATABLE" = "" %then %do;
		%put Alla tabeller från Hadoop kommer att laddas in i LASR-minnet.;
	%end;

	%if "VATABLE" ne "" %then %do;
		%put Tabell &vatable från Hadoop kommer att laddas in i LASR-minnet.;
	%end;

	%LET VDB_GRIDHOST=&lasrserver;
	%LET VDB_GRIDINSTALLLOC=/opt/sas/TKGrid;
	options set=GRIDHOST="&lasrserver";
	options set=GRIDINSTALLLOC="/opt/sas/TKGrid";
	options validvarname=any validmemname=extend noerrorabend;

	proc printto print='/tmp/load_lasrfromhadoop_&tag._&sysdate._&systime..lst';
	run;

	
	LIBNAME HADOOP SASHDAT  PATH="&path"  SERVER="&lasrserver"  INSTALL="/opt/sas/TKGrid";
	%if &SYSLIBRC NE 0 %then %do;
		%put ====================================================================================================================================	;
		%put %str(ER)ROR: Misslyckades att skapa libname. Kontrollera om hadoop-libnamet existerar i den här miljön. (SERVER="&lasrserver" PATH="&path")	;
		%put ====================================================================================================================================	;
		%return;
	%end;

	LIBNAME LASR SASIOLA  TAG=&tag  PORT=&port HOST="&lasrserver"  SIGNER="&signer";
	%if &SYSLIBRC NE 0 %then %do;
		%put ====================================================================================================================================	;
		%put %str(ER)ROR: Misslyckades att skapa libname. Kontrollera om LASR-servern existerar i den här miljön. (HOST="&lasrserver" PORT=&port)	;
		%put ====================================================================================================================================	;
		%return;
	%end;


	

	* Delete:ar eventuella gamla tabeller	;
	%deltable(tables=	work.hadooptables
						work.lasrtables
						work.loadtablesfromhadoop_&tag)

	* Hämtar alla tabeller som finns i Hadoop.																		;
	%* Det här skulle kunna gå att göra mycket enklare med hjälp av en SQL mot dictionary.tables, men det ta		;
	%* av någon anledning väldigt lång tid att köra en sådan fråga i vår miljö. 									;
	ods output Members=work.hadooptables;
	proc datasets library=hadoop memtype=data;
	run;
	quit;
	ods _all_ close;


	data work.hadooptables(rename=(name=memname));
		%* Sätter längden till 32 för att vara säker på att få samma längd som i lasrtables	;
		length name $32;
		set work.hadooptables(keep=name);
		%if "&vatable" ne "" %then %do;
			where upcase(name) = "&vatable"
		%end;
	run;



	%* Skapar en tom LASR-tabell för att slippa få felmeddelande om 
	%* ingen tabell skapas av proc datasets nedan (för att det inte finns några LASR-tabeller).		;
	data work.lasrtables(rename=(memname=name));
		set work.hadooptables(OBS=0);
	run;

	* Hämtar alla tabeller som finns i LASR servern.;
	ods output Members=work.lasrtables;
	proc datasets library=LASR memtype=data;
	run;
	quit;
	ods _all_ close;

	%put **&sysdate._&systime**;


	* Inget viktigt ska skrivas ut, men öppnar en ods-destination i alla fall för att slippa onödiga varningar om att ingen "output destination" är öppen.	;
	ods html path="/tmp" file="load_lasrfromhadoop_&tag._&sysdate._&systime..html" gpath="/tmp";



	data work.lasrtables(rename=(name=memname));
		length name $32;
		set work.lasrtables(keep=name);
		%if "&vatable" ne "" %then %do;
			where upcase(name) = "&vatable"
		%end;
	run;



	%local antal_tabeller;
	* Sparar de tabeller som finns i Hadoop och som inte finns i LASR servern.;
	proc sql noprint;
		create table loadtablesfromhadoop_&tag as
		select hadoop.memname
		from hadooptables as hadoop
		where hadoop.memname not in (select memname from lasrtables);
	quit;

	%let antal_tabeller=&SQLOBS;


	%let dsid = %sysfunc(open(loadtablesfromhadoop_&tag));

	* Räknare för att kunna ge en lite indikation åt en stressad SAS-admin	;
	%local tabell_nr;
	%let tabell_nr=0;

	%do %while ((%sysfunc(fetch(&dsid))) = 0);
		
		%let tabell_nr=%eval(&tabell_nr+1);
		
		%let loadtable=%upcase(%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,memname)))));
		%put NOTE: ======= Laddar tabellen &loadtable som är nummer &tabell_nr av totalt &antal_tabeller i Hadoop-katalogen "&PATH".;

		%* Om man först vill radera tabellen (ska aldrig behövas, eftersom programmet endast laddar tabeller som inte fredan finns i LASR-minnet)	;
		%* vdb_dt(LASR.&loadtable);

		proc lasr port=&port.
			data=HADOOP.&loadtable
			signer="&signer"
			add noclass;
    		performance host="&lasrserver";
		run;

	%end;

	%let dsid = %sysfunc(close(&dsid));

	ods _all_ close;

	proc printto;
	run;


	LIBNAME LASR clear;
	LIBNAME HADOOP clear;

	%put EXIT: load_lasrfromhadoop_bst;


%mend load_lasrfromhadoop;




* Hämtar värden från en property-fil, för att kunna använda det här programmet i både test- och prodmiljöer	;
%get_property(property=metaserver)
%get_property(property=lasrserver)
%get_property(property=sasadm_pass)
%get_property(property=lasr_signer_port)
%get_property(property=lasr_signer_server)

* Verifierar att värden har hämtats		;
%put &=metaserver;
%put &=lasrserver;
%put &=lasr_signer_port;
%put &=lasr_signer_server;



* ===============================================================================	;
* Verkar inte alltid vara nödvändigt, men kan behövas för att slippa
* "ER ROR: Unable to connect to Metadata Server"
* ===============================================================================	;
options metaserver="&metaserver"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="&sasadm_pass"
	metarepository="Foundation";








/*
%let TAG=epj;
%let PATH=/epj;
%let PORT=10015;
%let SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization;
*/




* mprint underlättar copy-paste från loggen om man skulle behöva köra om något	;
options mprint;



* Anrop (Flera av lasr-servrarna finns inte i testmiljön ännu. Det kommer att resultera i errors.)	;
%load_lasrfromhadoop(VATABLE=, TAG=hps,			PATH=/hps,			PORT=10011, SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=epj,			PATH=/epj,			PORT=10015, SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=lrc,			PATH=/lrc,			PORT=10016, SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=ftv,			PATH=/ftv, 			PORT=10017, SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization);
%load_lasrfromhadoop(VATABLE=, TAG=metavision,	PATH=/metavision,	PORT=10018, SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization);


options nomprint;


* ===============================================================================	;
* Hårdkodat för att köra en enskild tabell
* ===============================================================================	;
/*
%let VATABLE=lul_kvalitet_levnadsvanor_pv;
%let TAG=hps;
%let PATH=/hps;
%let PORT=10011;
%let SIGNER=https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization;

LIBNAME LASR SASIOLA  TAG=&tag  PORT=&port HOST="&lasrserver"  SIGNER="&signer";
LIBNAME HADOOP SASHDAT  PATH="&path"  SERVER="&lasrserver"  INSTALL="/opt/sas/TKGrid";

proc lasr port=&port
	data=HADOOP.&VATABLE
	signer="&signer"
	add noclass;
	performance host="&lasrserver";
run;
/*********/