/** PREPROCESSING CODE **/
/* Steg i programmet: */
/* 1. Kollar om BFC.txt finns p� FTP-servern. Finns den inte s� avbryts programmet. */
/* 2. L�ser in BFC.txt till tempor�r work-tabell. */
/* 3. G�r databearbetning. */
/* 4. H�mtar datum fr�n BFC.txt, rensar fr�n SASDATA.BFC samma period. */
/* 5. Appendar data till SASDATA.BFC. */
/* 6. Tar bort BFC.txt fr�n FTP-server. */
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
		* Om ingen fil hittas g�r datasteget aldrig in i ifsatsen �ht. macrovariabeln RC f�rblir allts� missing.	;
		call symput('RC',"FILE NOT FOUND");
	end;

run;
%put RC=&rc;


data _null_;
	if "&RC" ne "FILE FOUND" then do;
		put "INFO: Filen &FIL hittades inte p� servern. Programmet avbryts.";
		abort cancel 0;
	end;
	else  do;
		put "INFO: Filen &FIL hittades p� servern. Programmet forts�tter med att f�rs�ka l�sa in filen.";
	end;
run;



/* L�s in data om fil finns. */

* fil som anv�nds under utveckling	;
* filename fil "/saswork/LUL/BFCDATA/RC.csv" ENCODING="utf-8" TERMSTR=CRLF;


* Specifikation av m�ltabell och inl�sning av data i samma datasteg	;
data WORK.RC;
	infile FIL delimiter='09'x MISSOVER DSD  firstobs=2;

	* Kolumnerna specas i den ordning vi vill ha dem i utdatatabellen;
	attrib
		USPRIO			length=$13	label='�nskad prio'
		RREQNR			length=8.	label='Remissnr'	format=BEST32.
		VISITREQGR		length=$30	label='Rem.grupp'
		d_METHODS_DESC	length=$15	label='Metod'
		DBOOKNR 		length=8.	label='Bokn.nr'		format=BEST32.
		SIGNDOC1_NAME	length=$30	label='Sign1.l�k'
		DLOCATION_DESC	length=$30	label='Rum / Labb'
		BOOKDATE		length=8.	label='Datum'		format=YYMMDD10.	informat=yymmdd10.
		SIGNDOC2_NAME	length=$30	label='Sign2.l�k'
		BOOKTIME		length=$5	label='Tid'
		STATUS			length=$12	label='Status'
		Sign1Datum		length=8.	label='Sign1.datum'	format=YYMMDD10.	informat=yymmdd10.
		Sign2Datum		length=8.	label='Sign2.datum'	format=YYMMDD10.	informat=yymmdd10.
		RDSTUDYNR		length=8.	label='L�pnr'		format=BEST32.	
		RDRESCODE		length=$7	label='Kod'
		RESCODE_DESC	length=$60	label='Unders�kningskod'
		metodgrupp		length=$20	label='Unders�kn./Eftergranskn.'
		Bokningstyp		length=$40 
		Forskning		length=$1 
		KomplStatus		length=$30;

	* Kolumnerna l�ses i den ordning de ligger i filen;
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
	* Initialiserar tv� variabler som ska f� sina v�rden lite senare i programmet	;
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
		metodgrupp = 'Unders�kn.';
	end;

	* GML har ersatts med KONV RTG sedan 2015;
	if methods_desc in ('GML', 'UTG�TT GML') then d_methods_desc = 'KONV RTG';

run;

title "Koll (endast under utveckling)";
proc SQL;
	select d_methods_desc, count(*)
	from work.rc_deriverade_variabler
	group by d_methods_desc;
quit;




* Appendar noll rader (bara f�r att skapa m�ltabellen om den inte redan finns)	;
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


* Tar fram vilka perioder(m�nader) som finns i filen ;
proc SQL noprint;
	select distinct put(bookdate, yymmn6.) into :periods separated by '" "'
	from work.rc_deriverade_variabler;
quit;

%put "&periods";


* Rensa om period(er) redan �r inl�st;
proc sql noprint;
	delete from bfcdata.Enkoping_radiologiskt_centrum
	where put(bookdate, yymmn6.) in("&periods");
quit;


* "Riktiga" appenden	;
proc append base=bfcdata.Enkoping_radiologiskt_centrum data=work.rc_deriverade_variabler force;
run;




* Registrerar SAS-tabellen i metadata									;
proc metalib;
	omr (	library="/Shared Data/Datak�lla BFC/BFCDATA"
			REPNAME="Foundation" );
	folder="/Shared Data/Datak�lla BFC";
	select ("Enkoping_radiologiskt_centrum");
run;


* L�gger till en beskrivning av tabellen	;
data _null_;
	RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='Enkoping_radiologiskt_centrum'","Desc","Enk�pings Lasarett  - BFC-data fr�n Radiologiskt centrum i Enk�ping");
	if RC NE 0 then put "Misslyckades med att s�tta en beskrivning av tabellen";
run;



/* Tar bort fil p� FTP-servern. */
filename tabort ftp "&fil"
	user='ASBFC' pass='iP6o0mi' host='infr-ftp-01.lul.se'
	RCMD="DELE &fil";

data _null_;
	rc = fileref("tabort");
run;


/******************
* Fejka data f�r fler �r	;
data bfcdata.Enkoping_radiologiskt_centrum;
	set bfcdata.Enkoping_radiologiskt_centrum;
	output;
	do i = 1 to 11;
		* plusar p� tv� m�nader p� varje rad och skriver ut	;
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

* /LUL/Lasarettet i Enk�ping/Verksamhetsomr�de radiologi ;