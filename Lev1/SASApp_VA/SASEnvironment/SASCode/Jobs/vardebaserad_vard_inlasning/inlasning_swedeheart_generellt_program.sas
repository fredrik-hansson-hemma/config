
* Hämtar värdet på propertyn "hadoopserver" och lagrar den i en global macrovariabel med namnet "hadoopserver"	;
%get_property(property=hadoopserver)
* Hämtar värdet på propertyn "lasrserver" och lagrar den i en global macrovariabel med namnet "lasrserver"	;
%get_property(property=lasrserver)
* Hämtar värdet på propertyn "lasr_signer_port" och lagrar den i en global macrovariabel med namnet "lasr_signer_port"	;
%get_property(property=lasr_signer_port)



* Ansluter till standard-lasr-servern (den som används för centrala beslutsstöds data) samt till tillhörande Hadoop-instans.	;
LIBNAME HPS SASHDAT  PATH="/hps"  SERVER="&hadoopserver"  INSTALL=" /opt/sas/TKGrid";
LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="&lasrserver"  SIGNER="https://&lasrserver:&lasr_signer_port/SASLASRAuthorization";


* Skapa katalogstruktur för det metadata som ska skrivas.
* 	-Nej! Vad händer om /LUL/Akademiska sjukhuset/Värdebaseradvård/Pnr-rapporter byter namn?
	Då skapas en ny katalog med felaktiga behörigheter satta. Personnummer kan då läsas av obehöriga!
	känsliga metadatakataloger måste skapas manuellt så länge de underhålls manuellt.					;
* /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools/sas-make-folder -profile ~/.SASAppData/MetadataServerProfiles/SASAdm.swa -makeFullPath "/LUL/Akademiska sjukhuset/Värdebaseradvård/Pnr-rapporter/Data/Swedeheart/Mellanlagring_Hadoop" ;


* Hämta lista av filer på FTP-servern		;

* Klura ut vilka filnamn som ska läsas in	;

* Felmeddelande om det ligger filer med oväntade filnamn på plats	;

* Felmeddelande om det saknas någon fil								;

* Skapa filename till filen på SFTP-servern	;







* Skapa datastegsvy som läser från filenamet	;
options validvarname = any validmemname=extend;

/******* Första försöket. Textfiler. Onödigt eftersom UCR också kör SAS.	*******
filename infil "/opt/sas/RU_Utitlities/UCR-data/&FilAttLasaIn";

%put Läser in data med hjälp av proc import																	;
%put Data läggs direkt i Hadoop. Om man vill ha bättre koll på vad som händer, så kan man temporärt lägga	;
%put data i en worktabell som man sedan laddar upp till hadoop.												;
proc import file=infil out=hps.&MalTabell dbms=dlm replace;
	delimiter=';';
	* Undersöker bredd och typ för de 2 milj första raderna (MAX=2 147 483 647)		;
	GUESSINGROWS=2000000;
run;
/***********************************************************************************/

* Skapar libname till swedeheart-filerna	;
libname swedehea "/opt/sas/RU_Utitlities/UCR-data/";
proc format cntlin=swedehea.sysformat library=work;
quit;
proc format cntlin=swedehea.userformat library=work;
quit;

* Läser in data i Hadoop ;
data hps.&MalTabell(REPLACE=YES);
	set swedehea.&MalTabell;
run;


* Raderar metadata
* OBS! Raderar första bästa tabell med namnet. 
* (Egentligen vill vi inte radera metadata. Det skulle räcka att bara
* uppdatera metadatatabellen efter att vi skapat om den fysiska tabellen.
* Tyvärr fungerar inte det eftersom det skapas dubletter av metadatatabeller
* när man användet prefix (vilket vi behöver göra för att skilja på hadoop-
* tabeller och vanliga LASRtabeller).)										;
%delete_metadata_table(stg_&MalTabell);


* Registrerar Hadoop-tabellen i metadata									;
proc metalib;
	omr (	library="/Shared Data/Hadoop/Visual Analytics HDFS"
			REPNAME="Foundation" );
	folder="/LUL/Akademiska sjukhuset/Värdebaseradvård/Pnr-rapporter/Data/Swedeheart/Mellanlagring_Hadoop";
	prefix="stg_";
	select ("&MalTabell");
	update_rule=(delete);
run;





/* Drop existing table (Visual Data Builder - Delete Table)	*/
%vdb_dt(VALIBLA.&MalTabell);
* libname VALIBLA CLEAR;


* proc lasr genererar en del onödig output. Skickar ut den i cyberrymden för att slippa se den.
* Det som skrivs i loggen är tillräckligt.														;
%disablelisting()

* Ladda in tabellen i rätt LASR-server											;
/* Optimize Load with PROC LASR */
proc lasr	PORT=10011
			data=HPS.&MalTabell
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
	omr (library="/Shared Data/SAS Visual Analytics/Visual Analytics LASR");
	folder="/LUL/Akademiska sjukhuset/Värdebaseradvård/Pnr-rapporter/Data/Swedeheart";
	select ("&MalTabell");
run;

* Något i programmet är inte ordentligt avslutat. Lägger in en quit för att åtgärda...	;
quit;




* Radera filerna från lokala disken ;

* Radera filerna från SFTP-servern	;