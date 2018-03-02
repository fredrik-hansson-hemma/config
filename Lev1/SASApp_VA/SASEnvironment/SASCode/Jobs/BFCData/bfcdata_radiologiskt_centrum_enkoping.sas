/** PREPROCESSING CODE **/
/* Steg i programmet: */
/* 1. Kollar om BFC.txt finns på FTP-servern. Finns den inte så avbryts programmet. */
/* 2. Läser in BFC.txt till temporär work-tabell. */
/* 3. Gör databearbetning. */
/* 4. Hämtar datum från BFC.txt, rensar från SASDATA.BFC samma period. */
/* 5. Appendar data till SASDATA.BFC. */
/* 6. Tar bort BFC.txt från FTP-server. */
LIBNAME BFCDATA BASE "/saswork/LUL/BFCDATA";
%let FIL=RC.csv;

/* FTP listning */
filename xpt ftp '' ls user='ASBFC' pass='iP6o0mi' host='infr-ftp-01.lul.se';

/* FTP mot fil */
filename fil ftp "&fil" user='ASBFC' pass='iP6o0mi' host='infr-ftp-01.lul.se' ENCODING="utf-8";


%global RC;
data _null_;
	infile xpt;
	input;

	if _infile_="&FIL" then do;
		call symput('RC',"FILE FOUND");
	end;
	else do;
		* Om ingen fil hittas går datasteget aldrig in i ifsatsen öht. macrovariabeln RC förblir alltså missing.	;
		call symput('RC',"FILE NOT FOUND");
	end;

run;
%put RC=&rc;


data _null_;
	if "&RC" ne "FILE FOUND" then do;
		put "INFO: Filen &FIL hittades inte på servern. Programmet avbryts.";
		abort cancel 0;
	end;
	else  do;
		put "INFO: Filen &FIL hittades på servern. Programmet fortsätter med att försöka läsa in filen.";
	end;
run;



/* Läs in data om fil finns. */

* fil som används under utveckling	;
* filename fil "/saswork/LUL/BFCDATA/RC.csv" ENCODING="utf-8" TERMSTR=CRLF;


* Specifikation av måltabell och inläsning av data i samma datasteg	;
data WORK.RC;
	infile FIL delimiter='09'x MISSOVER DSD  firstobs=2;

	* Kolumnerna specas i den ordning vi vill ha dem i utdatatabellen;
	attrib
		USPRIO			length=$13	label='Önskad prio'
		RREQNR			length=8.	label='Remissnr'	format=BEST32.
		VISITREQGR		length=$30	label='Rem.grupp'
		d_METHODS_DESC	length=$15	label='Metod'
		DBOOKNR 		length=8.	label='Bokn.nr'		format=BEST32.
		SIGNDOC1_NAME	length=$30	label='Sign1.läk'
		DLOCATION_DESC	length=$30	label='Rum / Labb'
		BOOKDATE		length=8.	label='Datum'		format=YYMMDD10.	informat=yymmdd10.
		SIGNDOC2_NAME	length=$30	label='Sign2.läk'
		BOOKTIME		length=$5	label='Tid'
		STATUS			length=$12	label='Status'
		Sign1Datum		length=8.	label='Sign1.datum'	format=YYMMDD10.	informat=yymmdd10.
		Sign2Datum		length=8.	label='Sign2.datum'	format=YYMMDD10.	informat=yymmdd10.
		RDSTUDYNR		length=8.	label='Löpnr'		format=BEST32.	
		RDRESCODE		length=$7	label='Kod'
		RESCODE_DESC	length=$60	label='Undersökningskod'
		metodgrupp		length=$20	label='Undersökn./Eftergranskn.'
		Bokningstyp		length=$40 
		Forskning		length=$1 
		KomplStatus		length=$30;

	* Kolumnerna läses i den ordning de ligger i filen;
	input
		Bokningstyp $
		USPRIO $
		RREQNR
		VISITREQGR $
		METHODS_DESC $
		Forskning $
		DBOOKNR
		SIGNDOC1_NAME $
		DLOCATION_DESC $
		BOOKDATE
		KomplStatus $
		SIGNDOC2_NAME $
		BOOKTIME $
		STATUS $
		Sign1Datum
		Sign2Datum
		RDSTUDYNR
		RDRESCODE $
		RESCODE_DESC $;
	* Initialiserar två variabler som ska få sina värden lite senare i programmet	;
	call missing(d_METHODS_DESC, metodgrupp);
run;



data work.rc_deriverade_variabler;
	set work.rc;

	methods_desc=upcase(methods_desc);

	if bokningstyp in('Eftergranskning med arkivering' 'Eftergranskning utan arkivering') then do;
		d_methods_desc='Eftergranskning';
		metodgrupp = 'Eftergranskn.';
	end;
	else do;
		d_methods_desc=methods_desc;
		metodgrupp = 'Undersökn.';
	end;

	* GML har ersatts med KONV RTG sedan 2015;
	if methods_desc in ('GML', 'UTGÅTT GML') then d_methods_desc = 'KONV RTG';

run;

title "Koll (endast under utveckling)";
proc SQL;
	select d_methods_desc, count(*)
	from work.rc_deriverade_variabler
	group by d_methods_desc;
quit;




* Appendar noll rader (bara för att skapa måltabellen om den inte redan finns)	;
proc append
	base=bfcdata.Enkoping_radiologiskt_centrum
	data=work.rc_deriverade_variabler(OBS=0)
	force;
run;


/*** Omstart (endast under utveckling!)
proc SQL;
	drop table bfcdata.Enkoping_radiologiskt_centrum;
quit;
****/


* Tar fram vilka perioder(månader) som finns i filen ;
proc SQL noprint;
	select distinct put(bookdate, yymmn6.) into :periods separated by '" "'
	from work.rc_deriverade_variabler;
quit;

%put "&periods";


* Rensa om period(er) redan är inläst;
proc sql noprint;
	delete from bfcdata.Enkoping_radiologiskt_centrum
	where put(bookdate, yymmn6.) in("&periods");
quit;


* "Riktiga" appenden	;
proc append base=bfcdata.Enkoping_radiologiskt_centrum data=work.rc_deriverade_variabler force;
run;




* Registrerar SAS-tabellen i metadata									;
proc metalib;
	omr (	library="/Shared Data/Datakälla BFC/BFCDATA"
			REPNAME="Foundation" );
	folder="/Shared Data/Datakälla BFC";
	select ("Enkoping_radiologiskt_centrum");
run;


* Lägger till en beskrivning av tabellen	;
data _null_;
	RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='Enkoping_radiologiskt_centrum'","Desc","Enköpings Lasarett  - BFC-data från Radiologiskt centrum i Enköping");
	if RC NE 0 then put "Misslyckades med att sätta en beskrivning av tabellen";
run;



/* Tar bort fil på FTP-servern. */
filename tabort ftp "&fil"
	user='ASBFC' pass='iP6o0mi' host='infr-ftp-01.lul.se'
	RCMD="DELE &fil";

data _null_;
	rc = fileref("tabort");
run;


/******************
* Fejka data för fler år	;
data bfcdata.Enkoping_radiologiskt_centrum;
	set bfcdata.Enkoping_radiologiskt_centrum;
	output;
	do i = 1 to 11;
		* plusar på två månader på varje rad och skriver ut	;
		bookdate=intnx('MONTH', bookdate, 2, 'SAME');
		output;
	end;
	drop i;
run;

* Tar bort fejk-data	;
proc sql noprint;
	delete from bfcdata.Enkoping_radiologiskt_centrum
	where put(bookdate, yymmn6.) not in("201606" "201607");
quit;
/******************/

* /LUL/Lasarettet i Enköping/Verksamhetsområde radiologi ;