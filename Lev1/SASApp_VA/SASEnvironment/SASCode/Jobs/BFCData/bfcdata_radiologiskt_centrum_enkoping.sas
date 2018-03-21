/** PREPROCESSING CODE **/
/* Steg i programmet: */
/* 1. Kollar om BFC.txt finns på FTP-servern. Finns den inte så avbryts programmet. */
/* 2. Läser in BFC.txt till temporär work-tabell. */
/* 3. Gör databearbetning. */
/* 4. Hämtar datum från BFC.txt, rensar från SASDATA.BFC samma period. */
/* 5. Appendar data till SASDATA.BFC. */
/* 6. Tar bort BFC.txt från FTP-server. */
LIBNAME BFCDATA BASE "/saswork/LUL/BFCDATA";
%let FIL=BFC_LE.txt;

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
filename fil "/saswork/LUL/BFCDATA/&FIL" /* ENCODING="utf-8" TERMSTR=CRLF */;

/********* Bara för att generera upp ett inläsnings-datasteg
proc import file=fil out=BFC_LE replace dbms=tab;
	datarow=2;
	guessingrows=ALL;
run; *********/


* Specifikation av måltabell och inläsning av data i samma datasteg	;
data WORK.BFC_LE;
	infile FIL delimiter='09'x MISSOVER DSD  firstobs=2 end=last;
	attrib
		Utforande_enhet	length=$17	label="Utförande enhet"
		Bokningstyp		length=$40	/* (tidigare kallad BOOKRESP_DESC)	*/
		USPRIO			length=$13	label='Önskad prio'	format=$13.
		RREQNR			length=8.	label='Remissnr'	format=BEST32.		informat=best32.
		VISITREQGR		length=$30	label='Rem.grupp'
		METHODS_DESC	length=$15	label='Metod'
		d_METHODS_DESC	length=$15	label='Metod'
		Forskning		length=$7
		DBOOKNR 		length=8.	label='Bokn.nr'		format=BEST32.
		DLOCATION_DESC	length=$30	label='Rum / Labb'
		BOOKDATE		length=8.	label='Datum'		format=YYMMDD10.	informat=yymmdd10.
		KomplStatus 	length=$30
		BOOKTIME		length=8	label='Tid'			format=TIME.		informat=TIME.
		STATUS			length=$14	label='Status'
		SIGNDOC1_NAME	length=$70	label='Preliminärsignerad av'
		SIGNDOC2_NAME	length=$70	label='Slutsignerad av'
		Sign1Datum		length=8.	label='Preliminärsignerad datum'		format=YYMMDD10.	informat=yymmdd10.
		Sign2Datum		length=8.	label='Slutsignerad datum'				format=YYMMDD10.	informat=yymmdd10.
		RDSTUDYNR		length=8.	label='Löpnr'		format=BEST32.
		RDRESCODE		length=$7	label='Kod'
		RESCODE_DESC	length=$60	label='Undersökningskod'
		metodgrupp		length=$20	label='Undersökn./Eftergranskn.'
		sektion 		length=$35	label="Sektion"
		;
	
	input
		Bokningstyp $	USPRIO $		RREQNR				VISITREQGR $	METHODS_DESC $	Forskning $
		DBOOKNR			SIGNDOC1_NAME $	DLOCATION_DESC $	BOOKDATE		KomplStatus $	SIGNDOC2_NAME $
		BOOKTIME $		STATUS $		Sign1Datum			Sign2Datum		RDSTUDYNR		RDRESCODE $
		RESCODE_DESC $	Utforande_enhet $
		;

	* Initialiserar variabler som ska få sina värden lite senare i programmet	;
	call missing(d_METHODS_DESC, metodgrupp, sektion);
run;



proc format lib=work;
	value $sektion
		'BFC skelett' = 'Muskuloskeletal'
		'BFC barn' = 'Muskuloskeletal'
		'BFC bentäthetsmätning' = 'Muskuloskeletal'
		'BFC gastro' = 'Buk'
		'BFC perifer intervention' = 'Buk'
		'BFC ultraljud' = 'Buk'
		'BFC uro/gyn' = 'Buk'
		'BFC vaskulära anomalier' = 'Buk'
		'BFC neuro'	= 'Neuro'
		'BFC neurointervention' = 'Neuro'
		'BFC hjärta' = 'Molekulär bilddiagnostik'
		'BFC thorax' = 'Molekulär bilddiagnostik'
		'BFC nukleärmedicin' = 'Molekulär bilddiagnostik'
		'BFC onkologi' = 'Molekulär bilddiagnostik'
		'BFC PET-centrum' = 'Molekulär bilddiagnostik'
		other = 'BORT';
	value $metod
		'DT' = 'KVAR'
		'DXA' = 'KVAR'
		'NM TERAPI' = 'KVAR'
		'INTERVENTION' = 'KVAR'
		'KONV RTG' = 'KVAR'
		'MR' = 'KVAR'
		'NM' = 'KVAR'
		'PET' = 'KVAR'
		'SKYLT' = 'KVAR'
		'ULJ' = 'KVAR'
		other = 'BORT';
quit;




data work.BFC_LE_deriverade_variabler;
	set work.BFC_LE;

	methods_desc=upcase(methods_desc);

	* Beräknar kolumnerna d_methods_desc och metodgrupp		;
	if bokningstyp in('Eftergranskning med arkivering' 'Eftergranskning utan arkivering') then do;
		if substr(Utforande_enhet, 1,3)="BFC" then do;
			d_methods_desc='SKYLT';
			metodgrupp = 'Skylt';
		end;
		else do;
			d_methods_desc='Eftergranskning';
			metodgrupp = 'Eftergranskning';
		end;
	end;
	else do;
		d_methods_desc=methods_desc;
		metodgrupp = 'Undersökning';
	end;

	* GML har ersatts med KONV RTG sedan 2015;
	if methods_desc in ('GML', 'UTGÅTT GML') then d_methods_desc = 'KONV RTG';

	* Gäller endast BFC		;
	if substr(Utforande_enhet, 1,3)="BFC" then do;
		sektion = put(visitreqgr, $sektion.);
		* Ta bort värden som inte har giltig Sektion;
		if upcase(sektion) = 'BORT' then delete;
		* Ta bort avvikande värden för Methods_desc;
		if put(upcase(d_methods_desc), $metod.) = 'BORT' then delete;	
	end;
	drop METHODS_DESC;

run;



title "Koll (endast under utveckling)";
proc SQL;
	select d_methods_desc, count(*)
	from work.BFC_LE_deriverade_variabler
	group by d_methods_desc;
quit;



* Appendar noll rader (bara för att skapa måltabellen om den inte redan finns)	;
proc append
	base=bfcdata.BFC_och_Enkoping_radiologiskt_ce
	data=work.BFC_LE_deriverade_variabler(OBS=0)
	force;
run;
/*****
proc append
	base=bfcdata.BFC
	data=work.BFC_LE_deriverade_variabler(OBS=0)
	force;
run;
*******/

/******
proc SQL;
	select bookresp_desc, put(bookdate, yymm7.) as manad, count(*)
	from bfcdata.bfc
	group by bookresp_desc, manad;
quit;


data test;
	set bfcdata.bfc;
	where adm_code NE "";
run;


/********* Ändrar i målfilen (endast under utveckling
data bfcdata.Enkoping_radiologiskt_centrum;
	attrib
		BOOKRESP_DESC	length=$41	label= 'Bokn.ansvar'
		DID				length=$12	label='(Inaktuell kolumn) Personnr'
		ADM_CODE		length=$22	label= 'Admin.typ'
		REQGR_ANSVAR 	length=8	label='(Inaktuell kolumn) Ansvar Rem.grp'
		DOCTOR_NAME		length=$67	label='(Inaktuell kolumn) Dikt.läk'
		Utforande_enhet	length=$17
		sektion 		length=$35	label="Sektion"
		BOOKTIME		length=8	label='Tid'			format=TIME.		informat=TIME.;
	length 
		SIGNDOC1_NAME $45
		SIGNDOC2_NAME $45
		STATUS $14
		Forskning $7
		;
	set bfcdata.Enkoping_radiologiskt_centrum(drop=BOOKTIME methods_desc);
run;
*************/


/*** Omstart (endast under utveckling!)
proc SQL;
	drop table bfcdata.BFC_och_Enkoping_radiologiskt_ce;
quit;
****/


* Tar fram vilka perioder(månader) som finns i filen ;
proc SQL noprint;
	select distinct put(bookdate, yymmn6.) into :periods separated by '" "'
	from work.BFC_LE_deriverade_variabler;
quit;

%put "&periods";


* Rensa om period(er) redan är inläst;
proc sql noprint;
	delete from bfcdata.BFC_och_Enkoping_radiologiskt_ce
	where put(bookdate, yymmn6.) in("&periods");
quit;


* "Riktiga" appenden	;
proc append base=bfcdata.BFC_och_Enkoping_radiologiskt_ce
			data=work.BFC_LE_deriverade_variabler force;
run;




* Registrerar SAS-tabellen i metadata									;
proc metalib;
	omr (	library="/Shared Data/Datakälla BFC/BFCDATA"
			REPNAME="Foundation" );
	folder="/Shared Data/Datakälla BFC";
	select ("BFC_och_Enkoping_radiologiskt_ce");
run;


* Lägger till en beskrivning av tabellen	;
data _null_;
	RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='BFC_och_Enkoping_radiologiskt_ce'","Desc","Data från BFC i Uppsala samt Radiologen på Enköpings Lasarett");
	if RC NE 0 then put "Misslyckades med att sätta en beskrivning av tabellen";
run;



/* Tar bort fil på FTP-servern. */
filename tabort ftp "&fil"
	user='ASBFC' pass='iP6o0mi' host='infr-ftp-01.lul.se'
	RCMD="DELE &fil";

data _null_;
	rc = fileref("tabort");
run;


/****************

* Test			;
data work.test;
	set bfcdata.BFC_och_Enkoping_radiologiskt_ce;
	where bookdate between '01JUN2016'd and '30JUN2016'd
	  and Bokningstyp IN('Akut', 'Drop-in', 'Generell')
	  and VISITREQGR = "LE Radiologiskt centrum"; *
	  and d_METHODS_DESC in('DT', 'INTERVENTION', 'KONV RTG', 'MR', 'ULJ' 'Eftergranskning') ;
run;


********************/



/******************
* Fejka data för fler år	;
data bfcdata.BFC_och_Enkoping_radiologiskt_ce;
	set bfcdata.BFC_och_Enkoping_radiologiskt_ce;
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