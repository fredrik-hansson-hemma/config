
/***************************************************************************************************
Tidigare fanns endast filen "BFC". BFC är namnet på Uppsalas röntgen
Nu mera kommer röntgendata från både RC (Enköpings röntgen) och BFC.
Det här programmet läser in nytt data och appendar det till tabellen
BFCDATA.bfc_och_enkoping_radiologiskt_ce.

Det skapar även vyn "bfcdata.prod_UAS_BFC_och_LE_radiologi" som innehåller data från den gamla BFC-tabellen (endast Uppsala data) och
allt data i BFCDATA.bfc_och_enkoping_radiologiskt_ce. Detta för att få en vy som innehåller allt tillgängligt Uppsaladata och 
allt tillgängligt Enköpingsdata i samma.

Och lite grafiskt blir det såhär:


Nytt data från FTP	--|append|-->	BFC_OCH_ENKOPING_RADIOLOGISKT_CE	--|ingår i vyn|------>	PROD_UAS_BFC_OCH_LE_RADIOLOGI
																								   /
BFC(historiskt data som ej uppdateras)	--|ingår i vyn|-->	BFC_I_NYA_FORMATET	--|ingår i vyn|---/	


********************************************************************************************************

Steg i programmet:
1. Kollar om BFC_LE.txt finns på FTP-servern. Finns den inte så avbryts programmet.
2. Läser in BFC_LE.txt till temporär work-tabell.
3. Gör databearbetning.
4. Hämtar datum från BFC_LE.txt, rensar från bfcdata.BFC_och_Enkoping_radiologiskt_ce samma period.
5. Appendar data till bfcdata.BFC_och_Enkoping_radiologiskt_ce.
6. Tar bort BFC_LE.txt från FTP-server.
7. Skapar en vy som gör det gamla datasetet bfcdata.BFC kompatibel med det nya dataformatet
8. Slår samman gammalt och nytt data i en gemensam vy.
********************************************************************************************************/
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


%global abort_if_no_file_found;
data _null_;
	if "&RC" ne "FILE FOUND" then do;
		put "INFO: Filen &FIL hittades inte på servern. Programmet avbryts.";
		call symputx("abort_if_no_file_found", "endsas");
	end;
	else  do;
		put "INFO: Filen &FIL hittades på servern. Programmet fortsätter med att försöka läsa in filen.";
		call symputx("abort_if_no_file_found", '');
	end;
run;

* Macrovariabeln abort_if_no_file_found kan vara tom eller innehålla "endsas"		;
&abort_if_no_file_found;


/* Läs in data om fil finns. */


********************************************************************************************************
* fil som används under utveckling
* Observera att infile-statement också behöver ändras om man vill läsa från disk.	;
* filename fil "/saswork/LUL/BFCDATA/&FIL" /* ENCODING="utf-8" TERMSTR=CRLF */;
********************************************************************************************************;


* Specifikation av måltabell och inläsning av data i samma datasteg	;
data WORK.BFC_LE;
	* Raden nedan används om man ska läsa från fil på disk (ej via FTP)	;
	* infile FIL delimiter='09'x DSD firstobs=2 MISSOVER end=last  ;

	INFILE fil delimiter='09'x DSD FIRSTOBS=2 MISSOVER LRECL=504 ENCODING="LATIN9" TERMSTR=CRLF ;
	attrib
		Utforande_enhet	length=$17	label="Utförande enhet"
		Bokningstyp		length=$40	/* (tidigare kallad BOOKRESP_DESC)	*/
		USPRIO			length=$18	label='Önskad prio'
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
		RESCODE_DESC	length=$63	label='Undersökningskod'
		metodgrupp		length=$20	label='Undersökn./Eftergranskn.'
		sektion 		length=$35	label="Sektion"
		DOCTOR_NAME		length=$67	label="Dikt.läk"	/*	Den här kolumnen finns endast i gammalt BFC-data. Kanske dags att ta bort den snart?	*/
		;
	
	input
		Bokningstyp $	USPRIO $		RREQNR				VISITREQGR $	METHODS_DESC $	Forskning $
		DBOOKNR			SIGNDOC1_NAME $	DLOCATION_DESC $	BOOKDATE		KomplStatus $	SIGNDOC2_NAME $
		BOOKTIME $		STATUS $		Sign1Datum			Sign2Datum		RDSTUDYNR		RDRESCODE $
		RESCODE_DESC $	Utforande_enhet $
		;

	* Initialiserar variabler som ska få sina värden lite senare i programmet	;
	call missing(d_METHODS_DESC, metodgrupp, sektion, DOCTOR_NAME);
run;



proc format lib=work;
	* Format som används för urval	;
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

	* Från och med 2018-06-01 finns en ny sektion. Skapar därför ett nytt format.	;
	value $sektion_2018_06_01_v
		'BFC hjärta' = 'Thorax'
		'BFC thorax' = 'Thorax'
		other = [$sektion30.];
quit;




data work.BFC_LE_deriverade_variabler;
	set work.BFC_LE;

	methods_desc=upcase(methods_desc);

	* Beräknar kolumnerna d_methods_desc och metodgrupp		;
	if bokningstyp in('Eftergranskning med arkivering' 'Eftergranskning utan arkivering') then do;
		* Eftergranskning kallas "SKYLT" för BFC			;
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

		* Från och med 2018-06-01 finns en ny sektion.	;
		if bookdate LT '01JUN2018'd then do;
			sektion = put(visitreqgr, $sektion.);
		end;
		else do;
			sektion = put(visitreqgr, $sektion_2018_06_01_v.);
		end;
	end;

	drop METHODS_DESC;

run;





/********************************************************
title "Koll (endast under utveckling)";
proc SQL;
	select	put(BOOKDATE, yymmD7.) as book_month,
			d_methods_desc,
			count(*)
	from work.BFC_LE_deriverade_variabler
	group by calculated book_month, d_methods_desc;
quit;
********************************************************/





* Appendar noll rader (bara för att skapa måltabellen om den inte redan finns)	;
proc append
	base=bfcdata.BFC_och_Enkoping_radiologiskt_ce
	data=work.BFC_LE_deriverade_variabler(OBS=0)
	force;
run;


* Tar fram vilka perioder(månader) som finns i den nya filen	;
proc SQL noprint;
	select distinct put(bookdate, yymmn6.) into :periods separated by '" "'
	from work.BFC_LE_deriverade_variabler;
quit;
%put "&periods";


***********************************************************	;
* Rensa om period(er) redan är inläst.
* ---------------------------------------------------------  
* Observera att tabellen bfcdata.BFC inte rensas! 
* Det går alltså inte att rätta historiskt data.
* Om man vill kunna göra det, får man helt enkelt göra en
* till SQL som liknar den nedan. Ersättningsdata skrivs
* sedan till bfcdata.BFC_och_Enkoping_radiologiskt_ce, inte
* till bfcdata.BFC.
***********************************************************	;
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







*******************************************************************************************	;
* Appendar data från den gamla BFC-filen
*******************************************************************************************	;

* Skapar en vy där den gamla BFC-filen får samma format som den nya filen	;
data bfcdata.BFC_i_nya_formatet / view=bfcdata.BFC_i_nya_formatet;
	attrib
		RREQNR	format=BEST32.
		DBOOKNR format=BEST32.
		BOOKTIME format=TIME.
		RDSTUDYNR format=BEST32.
		Utforande_enhet length=$17
		bokningstyp length=$40
		USPRIO length=$18
		methods_desc length=$15
		DLOCATION_DESC length=$30
		Forskning length=$7
		STATUS length=$14
		SIGNDOC1_NAME  length=$70
		SIGNDOC2_NAME length=$70
		ADM_CODE  length=$30
		RDRESCODE length=$7
		metodgrupp length=$20;

	set bfcdata.BFC(rename=(DLOCATION_DESC=DLOCATION_DESC_old
							METHODS_DESC=METHODS_DESC_old));
	rename
		
		methods_desc=d_methods_desc
		ADM_CODE=KomplStatus;

	* Om man bara satte om längden på de här variblerna, blev det felmeddelanden i loggen.
	* Går därför omvägen med att skapa helt nya variabler.									;
	DLOCATION_DESC=DLOCATION_DESC_old;
	drop DLOCATION_DESC_old;
	METHODS_DESC=METHODS_DESC_old;
	drop METHODS_DESC_old;

	* bookresp_desc innehåller inget värde med mer än 40 tecken, så den är kompatibel med längden på bokningstyp	;
	bokningstyp=substr(bookresp_desc,1,40);
	drop bookresp_desc;

	* Skapar variabel som visar att data hör till BFC. Den fanns inte tidigare eftersom allt data då hörde till BFC	;
	Utforande_enhet="BFC historik";

	if metodgrupp = 'Undersökn.' then do;
		metodgrupp = 'Undersökning';
	end;

	* Initialiserar variabel för att slippa meddelande i loggen	;
	call missing(Forskning);
	
	drop
		did
		REQGR_ANSVAR
		;
run;

* Provläser en rad från vyn	(Bättre att det smäller nu än senare)	;
data _null_;
	set &syslast(obs=1) end=last;
run;

* Testar att göra en append endast för att se att tabellerna är kompatibla	;
proc append base=bfcdata.bfc_och_enkoping_radiologiskt_ce
	data=bfcdata.BFC_i_nya_formatet(obs=0);
run;

* Om append ovan går igenom utan varningar eller fel, är det fritt fram att skapa en vy där man 
* slår ihop de båda dataseten.																	;
data bfcdata.prod_UAS_BFC_och_LE_radiologi(label="BFC historiskt data + BFC-data och Lasarettet i Enköping Radiologiskt centrum-data") / view=bfcdata.prod_UAS_BFC_och_LE_radiologi;
	set bfcdata.bfc_i_nya_formatet
		bfcdata.bfc_och_enkoping_radiologiskt_ce;
run;

* Provläser en rad från vyn	(Bättre att det smäller nu än senare när vi försöker använda vyn i VA)	;
data _null_;
	set &syslast(obs=1) end=last;
run;





* Registrerar SAS-vyn i metadata									;
proc metalib;
	omr (	library="/Shared Data/Datakälla BFC/BFCDATA"
			REPNAME="Foundation" );
	folder="/Shared Data/Datakälla BFC";
	select ("prod_UAS_BFC_och_LE_radiologi");
run;


* Lägger till en beskrivning av vyn									;
data _null_;
	RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='prod_UAS_BFC_och_LE_radiologi'","Desc","Data från BFC i Uppsala samt Radiologen på Enköpings Lasarett");
	if RC NE 0 then put "Misslyckades med att sätta en beskrivning av tabellen";
run;



/****************

* Test			;
data work.test;
	set bfcdata.BFC_och_Enkoping_radiologiskt_ce;
	where bookdate between '01JUN2016'd and '30JUN2016'd
	  
	  and VISITREQGR = "LE Radiologiskt centrum"; *
	  and d_METHODS_DESC in('DT', 'INTERVENTION', 'KONV RTG', 'MR', 'ULJ' 'Eftergranskning') ;
	  * and Bokningstyp IN('Akut', 'Drop-in', 'Generell');
run;


********************/



/******************
* Fejka data för fler år	;
data bfcdata.BFC_och_Enkoping_radiologiskt_ce;
	set bfcdata.BFC_och_Enkoping_radiologiskt_ce;

	* Om det inte är Enköping, så plusar vi på två år (eftersom 201606 och 201607 redan finns i BFC-datat)	;
	if VISITREQGR NE "LE Radiologiskt centrum" then do;
		bookdate=intnx('YEAR', bookdate, 2, 'SAME');
	end;
	output;

	* Om det är enköping, så kopierar vi test-data så att det fyller ut ett par år	;
	if VISITREQGR = "LE Radiologiskt centrum" then do;
		do i = 1 to 11;
			* plusar på två månader på varje rad och skriver ut	;
			bookdate=intnx('MONTH', bookdate, 2, 'SAME');
			output;
		end;
	end;
	drop i;
run;


* Tar bort LE:s fejk-data	;
proc sql noprint;
	delete from bfcdata.BFC_och_Enkoping_radiologiskt_ce
	where VISITREQGR = "LE Radiologiskt centrum" and put(bookdate, yymmn6.) not in("201606" "201607");
quit;
/******************/

* /LUL/Lasarettet i Enköping/Verksamhetsområde radiologi ;
