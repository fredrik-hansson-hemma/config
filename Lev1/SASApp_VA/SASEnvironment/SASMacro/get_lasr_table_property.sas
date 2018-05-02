

%macro get_lasr_table_property(	Libname=,
								table=,
								property=/*	MemType (Member Type)
											NROWS (Number of Rows)
											NCOLS (Number of Columns)
											TAG (Server Tag)
											CEI (Data Encoding)
											OWNER (Owner)
											MDATE NLDATMS27. (Last Modified) */,
								keep_work_table=NO
								);

	ods output Members=work.lasr_tabeller;
		proc datasets library=&Libname memtype=data;
		run; quit;
	ods output close;

	%local format;
	%if &property=MDATE %then %do;
		* Tar bort formatet för MDATE eftersom det då blir lättare att använda resultatet i jämförelser.	;
		%let format=format=best32.;
		%put NOTE: =====================================================================================;
		%put NOTE: &property är en datetime-tidsstämpel. Den behöver formatteras för att bli läsbar.	;
		%put NOTE: =====================================================================================;
	%end;

	* Hämta timestamp för den aktuella tabellen, Lagra svaret i ut-macrovariabeln	;
	%global &property;
	%let &property=;
	proc SQL noprint;
		select &property &format into :&property
		from work.lasr_tabeller
		where upcase(name)=upcase("&table");

	%if &keep_work_table=NO %then %do;
		drop table work.lasr_tabeller;
	%end;

	quit;

	%put Resultatet (&&&property) är sparat i den globala macrovariabeln "&property";
%mend get_lasr_table_property;


/*********
proc SQL;
	drop table VALIBLA.Produktion_UAS_BFC;
quit;
*********/





/******************** För provkörning **************************

LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="bst-apx-20.lul.se"  SIGNER="https://bst-apx-20.lul.se:8343/SASLASRAuthorization" ;

%get_lasr_table_property(	Libname=VALIBLA,
							table=PRODUKTION_UAS_BFC,
							property=MDATE)

options nomprint;
%get_lasr_table_property(	Libname=VALIBLA,
							table=PRODUKTION_LE_RADIOLOGI,
							property=MDATE,
							keep_work_table=YES)

%put Senast modifierad den %sysfunc(datepart(&MDATE), yymmdd10.);

/****************************************************************/





/****************************************************************
Exempel på användning i LASR-laddning-sammanhang
Avbryt laddningen om LASR-tabellen är nyare än källtabellen
/****************************************************************

* Observera att den här koden kan ge upphov till märkliga felmeddelanden när
* den körs med playknappen i databuilder i VA.
* Den bör fungera bra när den är deployad/schemalagd.							;

* Hämtar källtabellens senast-uppdaterad-datum		;

LIBNAME BFCDATA BASE "/saswork/LUL/BFCDATA";

%let dsid=%sysfunc(open(BFCDATA.PROD_UAS_BFC_OCH_LE_RADIOLOGI));
%let source_table_modified_timestamp=%sysfunc(attrn(&dsid,modte));
%let rc=%sysfunc(close(&dsid));



* Hämtar LASR-tabellens senast-uppdaterad-datum		;

* Hämtar värdet på propertyn "lasrserver" och "lasr_signer_port". Lagrar i en globala macrovariabler.	;
%get_property(property=lasrserver)
%get_property(property=lasr_signer_port)

* Ansluter till standard-lasr-servern (den som används för centrala beslutsstöds data).	;
LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="&lasrserver"  SIGNER="https://&lasrserver:&lasr_signer_port/SASLASRAuthorization";


%get_lasr_table_property(	Libname=VALIBLA, table=PRODUKTION_LE_RADIOLOGI, property=MDATE)
/* %get_lasr_table_property(	Libname=VALIBLA, table=PRODUKTION_UAS_BFC, property=MDATE) */


/**************
%let LASR_table_modified_timestamp=&MDATE;
/**************/


/**************


* Avbryter om LASR-tabellen är nyare än källtabellen	;
%macro abort_if_source_not_updated;
	%put NOTE: =====================================================================================================;
	%if &LASR_table_modified_timestamp > &source_table_modified_timestamp %then %do;
		%put NOTE: LASR-tabellen är nyare än källtabellen, och behöver därför inte uppdateras. SAS-sessionen avbryts.	;
		endsas;
	%end;
	%else %do;
		%put NOTE: &=LASR_table_modified_timestamp < &=source_table_modified_timestamp;
		%put NOTE: Det betyder att LASR-tabellen behöver laddas med nytt data			;
	%end;
	%put NOTE: =====================================================================================================;
%mend abort_if_source_not_updated;

%abort_if_source_not_updated

/****************************************************************/
