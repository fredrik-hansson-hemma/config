
* H�mtar v�rdet p� propertyn "hadoopserver" och lagrar den i en global macrovariabel med namnet "hadoopserver"	;
%get_property(property=hadoopserver)
* H�mtar v�rdet p� propertyn "lasrserver" och lagrar den i en global macrovariabel med namnet "lasrserver"	;
%get_property(property=lasrserver)
* H�mtar v�rdet p� propertyn "lasr_signer_port" och lagrar den i en global macrovariabel med namnet "lasr_signer_port"	;
%get_property(property=lasr_signer_port)




LIBNAME HPS SASHDAT  PATH="/hps"  SERVER="&hadoopserver"  INSTALL=" /opt/sas/TKGrid";
LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="&lasrserver"  SIGNER="https://&lasrserver:&lasr_signer_port/SASLASRAuthorization";


* H�mta lista av filer p� FTP-servern		;

* Klura ut vilka filnamn som ska l�sas in	;

* Felmeddelande om det ligger filer med ov�ntade filnamn p� plats	;

* Felmeddelande om det saknas n�gon fil								;

* Skapa filename till filen p� SFTP-servern	;







* Skapa datastegsvy som l�ser fr�n filenamet	;
options validvarname = any validmemname=extend;

filename infil "/opt/sas/RU_Utitlities/UCR-data/&FilAttLasaIn";

%put L�ser in data med hj�lp av proc import																	;
%put Data l�ggs direkt i Hadoop. Om man vill ha b�ttre koll p� vad som h�nder, s� kan man tempor�rt l�gga	;
%put data i en worktabell som man sedan laddar upp till hadoop.												;
proc import file=infil out=hps.&MalTabell dbms=dlm replace;
	delimiter=';';
	* Unders�ker bredd och typ f�r de 2 milj f�rsta raderna (MAX=2 147 483 647)		;
	GUESSINGROWS=2000000;
run;





* Raderar metadata
* OBS! Raderar f�rsta b�sta tabell med namnet. 
* (Egentligen vill vi inte radera metadata. Det skulle r�cka att bara
* uppdatera metadatatabellen efter att vi skapat om den fysiska tabellen.
* Tyv�rr fungerar inte det eftersom det skapas dubletter av metadatatabeller
* n�r man anv�ndet prefix (vilket vi beh�ver g�ra f�r att skilja p� hadoop-
* tabeller och vanliga LASRtabeller).)										;
%delete_metadata_table(stg_&MalTabell);


* Registrerar Hadoop-tabellen i metadata									;
proc metalib;
	omr (	library="/Shared Data/Hadoop/Visual Analytics HDFS"
			REPNAME="Foundation" );
	folder="/LUL/Akademiska sjukhuset/V�rdebaseradv�rd/Pnr-rapporter/Data/Swedeheart/Mellanlagring_Hadoop";
	prefix="stg_";
	select ("&MalTabell");
	update_rule=(delete);
run;





/* Drop existing table (Visual Data Builder - Delete Table)	*/
%vdb_dt(VALIBLA.&MalTabell);
* libname VALIBLA CLEAR;


* proc lasr genererar en del on�dig output. Skickar ut den i cyberrymden f�r att slippa se den.
* Det som skrivs i loggen �r tillr�ckligt.														;
%disablelisting()

* Ladda in tabellen i r�tt LASR-server											;
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
	omr (library="/Shared Data/SAS Visual Analytics/Acceptans/Visual Analytics Acceptans LASR");
	folder="/LUL/Akademiska sjukhuset/V�rdebaseradv�rd/Pnr-rapporter/Data/Swedeheart";
	select ("&MalTabell");
run;


