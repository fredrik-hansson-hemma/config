
* H�mtar v�rdet p� propertyn "hadoopserver" och lagrar den i en global macrovariabel med namnet "hadoopserver"	;
%get_property(property=hadoopserver)
* H�mtar v�rdet p� propertyn "lasrserver" och lagrar den i en global macrovariabel med namnet "lasrserver"	;
%get_property(property=lasrserver)
* H�mtar v�rdet p� propertyn "lasr_signer_port" och lagrar den i en global macrovariabel med namnet "lasr_signer_port"	;
%get_property(property=lasr_signer_port)
* H�mtar metadatas�kv�gen till libnamet som motsvarar LASR-servern p� port 10011	;
%get_property(property=path_to_lasr_libname_10011)


* Ansluter till standard-lasr-servern (den som anv�nds f�r centrala beslutsst�ds data) samt till tillh�rande Hadoop-instans.	;
LIBNAME HPS SASHDAT  PATH="/hps"  SERVER="&hadoopserver"  INSTALL=" /opt/sas/TKGrid";
LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="&lasrserver"  SIGNER="https://&lasrserver:&lasr_signer_port/SASLASRAuthorization";


* Skapa katalogstruktur f�r det metadata som ska skrivas.
* 	-Nej! Vad h�nder om /LUL/Akademiska sjukhuset/V�rdebaseradv�rd/Pnr-rapporter byter namn?
	D� skapas en ny katalog med felaktiga beh�righeter satta. Personnummer kan d� l�sas av obeh�riga!
	k�nsliga metadatakataloger m�ste skapas manuellt s� l�nge de underh�lls manuellt.					;
* /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools/sas-make-folder -profile ~/.SASAppData/MetadataServerProfiles/SASAdm.swa -makeFullPath "/LUL/Akademiska sjukhuset/V�rdebaseradv�rd/Pnr-rapporter/Data/Swedeheart/Mellanlagring_Hadoop" ;


* H�mta lista av filer p� FTP-servern		;

* Klura ut vilka filnamn som ska l�sas in	;

* Felmeddelande om det ligger filer med ov�ntade filnamn p� plats	;

* Felmeddelande om det saknas n�gon fil								;

* Skapa filename till filen p� SFTP-servern	;







* Skapa datastegsvy som l�ser fr�n filenamet	;
options validvarname = any validmemname=extend;

/******* F�rsta f�rs�ket. Textfiler. On�digt eftersom UCR ocks� k�r SAS.	*******
filename infil "/opt/sas/RU_Utitlities/UCR-data/&FilAttLasaIn";

%put L�ser in data med hj�lp av proc import																	;
%put Data l�ggs direkt i Hadoop. Om man vill ha b�ttre koll p� vad som h�nder, s� kan man tempor�rt l�gga	;
%put data i en worktabell som man sedan laddar upp till hadoop.												;
proc import file=infil out=hps.&MalTabell dbms=dlm replace;
	delimiter=';';
	* Unders�ker bredd och typ f�r de 2 milj f�rsta raderna (MAX=2 147 483 647)		;
	GUESSINGROWS=2000000;
run;
/***********************************************************************************/

* Skapar libname till swedeheart-filerna						;
libname swedehea "/opt/sas/RU_Utitlities/UCR-data/";
* Libname till den katalog som VA som default letar format i 	;
libname formats "/opt/sas/config/Lev1/SASApp_VA/SASEnvironment/SASFormats/";

* Kopierar formaten till SAS-katalogen formats(.sas7bcat) i libnamet formats.		;
proc format cntlin=swedehea.sysformat library=formats.formats;
quit;
proc format cntlin=swedehea.userformat(where=(fmtname NE "TESTID"))
			library=formats.formats;
quit;

* L�ser in data i Hadoop ;
data hps."AS_v�rdebaserad_v_sht_&MalTabell"n(REPLACE=YES);
	set swedehea.&MalTabell;
run;



* Raderar metadata
* OBS! Raderar f�rsta b�sta tabell med namnet. 
* (Egentligen vill vi inte radera metadata. Det skulle r�cka att bara
* uppdatera metadatatabellen efter att vi skapat om den fysiska tabellen.
* Tyv�rr fungerar inte det eftersom det skapas dubletter av metadatatabeller
* n�r man anv�ndet prefix (vilket vi beh�ver g�ra f�r att skilja p� hadoop-
* tabeller och vanliga LASRtabeller).)										;
%delete_metadata_table(stg_AS_v�rdebaserad_v_sht_&MalTabell);


* Registrerar Hadoop-tabellen i metadata									;
proc metalib;
	omr (	library="/Shared Data/Hadoop/Visual Analytics HDFS"
			REPNAME="Foundation" );
	folder="/LUL/Akademiska sjukhuset/V�rdebaseradv�rd/Pnr-rapporter/Data/Swedeheart/Mellanlagring_Hadoop";
	prefix="stg_";
	select ("AS_v�rdebaserad_v_sht_&MalTabell");
	update_rule=(delete);
run;


/* Drop existing table (Visual Data Builder - Delete Table)	*/
%vdb_dt(VALIBLA."AS_v�rdebaserad_v_sht_&MalTabell"n);
* libname VALIBLA CLEAR;


* proc lasr genererar en del on�dig output. Skickar ut den i cyberrymden f�r att slippa se den.
* Det som skrivs i loggen �r tillr�ckligt.														;
%disablelisting()

* Ladda in tabellen i r�tt LASR-server											;
/* Optimize Load with PROC LASR */
proc lasr	PORT=10011
			data=HPS."AS_v�rdebaserad_v_sht_&MalTabell"n
			hdfs (direct)
			signer="https://&lasrserver:&lasr_signer_port/SASLASRAuthorization"
			add
			noclass
			;
	performance host="&lasrserver";
run;

%disablelisting(RESTORE)


* Registrerar/Uppdaterar LASR-tabellen i metadata		;
proc metalib;
	omr (library="&path_to_lasr_libname_10011");
	folder="/LUL/Akademiska sjukhuset/V�rdebaseradv�rd/Pnr-rapporter/Data/Swedeheart";
	select ("AS_v�rdebaserad_v_sht_&MalTabell");
run;

* N�got i programmet �r inte ordentligt avslutat. L�gger in en quit f�r att �tg�rda...	;
quit;


* L�gger till en beskrivning av tabellen	;
data _null_;
	RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='stg_AS_v�rdebaserad_v_sht_&MalTabell'","Desc","Akademiska Sjukhuset - V�rdebaserad v�rd - Data fr�n kvalitetsregistret Swedeheart - &MalTabell");
	if RC NE 0 then put "Mislyckades med att s�tta en beskrivning av tabellen";
	RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='AS_v�rdebaserad_v_sht_&MalTabell'",	"Desc","Akademiska Sjukhuset - V�rdebaserad v�rd - Data fr�n kvalitetsregistret Swedeheart - &MalTabell");
	if RC NE 0 then put "Mislyckades med att s�tta en beskrivning av tabellen";
run;






* Radera filerna fr�n lokala disken ;

* Radera filerna fr�n SFTP-servern	;