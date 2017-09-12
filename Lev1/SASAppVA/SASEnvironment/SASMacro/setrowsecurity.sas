/*****************************************************************************
* Macro: setRowSecurity                     
* Sätter radbehörighet på en tabell i en LASR-server. 
* Macrot ger läsrättigheter för hela tabellen till grupperna:
* SASAdministrators, SAS VA Administratör, SAS General Servers, SAS Batch och Systemutvecklare.
* Läsrättigheter begränsas för gruppen Sassusers, dvs övriga användare med metadatakonto i Sas. 
* Radbehörighet sätts med ett filter på kolumnen som skickas med som namn i parametern COLUMN.  
*
* Av: Mattias Moliis, Infotrek
* Datum: 2014-03-26
* Parametrar:
* PATH: Sökväg till tabell i metadata
* TABLE: Tabell som ska behörighetsstyras. Om inget värde för parameter TABLE, körs macrot för alla tabeller under PATH.
*
* Ändringar:
* Datum: 2015-03-06 Mattias Moliis
* Skapat logik för att hantera blankt värde för parameter TABLE.
*
* Datum: 2015-03-13 Mattias Moliis
* Tabellen  måste innehålla bägge kolumnerna BEHORIGHET1 och BEHORIGHET2 annars kan inte gruppen SASUSERS läsa tabellen.
*
* Datum: 2017-01-23 Mattias Moliis
* Rensat skript från koll att rätt kolumner finns med.
******************************************************************************/


%macro setrowsecurity(path=,table=);
%put Enter setRowSecurity Path: &path Table: &table;

%let env = %get_env();
%put ENV: &env;
%if %sysfunc(upcase(&env)) = BST %then %let filepath=/SASWORK/scripts/; * Sökväg till katalog på server där skript lagras.;
%if %sysfunc(upcase(&env)) = BS %then %let filepath=/saswork/scripts/;

%if "&TABLE" = "" %then %do;
  %put Macrot setRowSecurity kommer att kolla alla tabeller under &path..;
%end;
%if "&TABLE" ne "" %then %do;
  %put Macrot setRowSecurity kommer att kolla tabell &path.&table..;
%end;

%get_metaserverattr;

/* Hämtar inloggningsuppgifter för metadataservern */
%let metaserver = %sysfunc(putc(%lowcase(%get_env()), $metaserver));
%let metaport = %sysfunc(putc(%lowcase(%get_env()), $metaport));
%let metauser = %sysfunc(putc(%lowcase(%get_env()), $metauser));
%let metapass = %sysfunc(putc(%lowcase(%get_env()), $metapass));

/* Om parametern table är tom ska alla tabeller i path hämtas in. */ 
%if "&TABLE" = "" %then %do;

%mdsecds(folder="&path", membertypes="Table", includesubfolders=no);
 /* Tar också bort de tabeller som innehåller _STG i namnet, dessa är Hadoop-tabeller. */
 Proc sort data=work.mdsecds_objs (where=(not index(upcase(objname), "_STG"))) out=tables(keep=objname);
  by location objname;
  where publicType = 'Table';
 run; 
%end; /* end: %if "TABLE" = "" */

/* Om parametern table har ett värde ska behörighet sättas bara på den tabellen. */ 
%if "&TABLE" ne "" %then %do;
  data tables;
  	memname="&table";
  run;
%end; /* end: %if "TABLE" ne ""*/

/* Sätt radbehörigheten. */

%let dsid = %sysfunc(open(TABLES));
%if &dsid %then %let nobs = %sysfunc(attrn(&dsid, NOBS));


%do %while (%sysfunc(fetch(&dsid)) = 0);

 	%let table = %sysfunc(getvarc(&dsid, 1));
	%put TABLE= &table;

  filename textfile "&filepath.&table..sh" termstr=LF; * En skriptfil skapas med samma namn som tabellen som ska behörighetstyras.; 

data _null_;
  length commando $400.; 
  file textfile encoding=utf8;
  put "#!/bin/bash -p";
  /* Sökväg där Sas Batch tool finns. */
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
  /* Anropar Sas Batch Tool sas-set-metadata-access. - removeAll tar bort alla behörighetsrestriktioner på tabellen. */
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -removeAll";
  /* Läsrättigheter sätts för de grupper som ska undantas från behörighetsrestriktioner. */
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant SASAdministrators:Read";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant 'SAS VA Administrator:Read'";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant 'SAS General Servers:Read'";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant 'SAS Batch:Read'";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant Systemutvecklare:Read";
  /* Sätt villkorlig behörighet till gruppen Sasusers. */
  commando=
  "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant sasusers:Read -condition "||'"'||"behorighet1 IN ('SUB::SAS.IdentityGroups') or behorighet2 IN ('SUB::SAS.IdentityGroups')"||'"';
  put commando;
run;

/* Tar bort BOM (Byte Order Mark) tecken från filen innan den körs på Linux. */
filename perla pipe "perl -piw -e 's/^\xEF\xBB\xBF//' &filepath.&table..sh";

data _null_;
  infile perla;
run;

/* Sätter rättigheter på skriptet. */
filename chmod pipe "chmod 777 &filepath.&table..sh";

data _null_;
  infile chmod;
run;

/* Exekverar skriptet och skriver standard output till logfil. */
filename exec pipe ". &filepath.&table..sh >& &filepath.&table..log";

data _null_;
  infile exec;
run;
 
%end; /* end: %do %while */
 
%let dsid = %sysfunc(close(&dsid));



%put Exit setRowSecurity;
%mend;

/* Exempel på anrop;
 EX1: sätter radbehörighet på tabell /Acceptanstest/LUL/Ekonomi_budget */
%*setRowSecurity(PATH=/Acceptanstest/LUL/Folktandvården/Data/,TABLE=TEST296ÅÄÖ);

/* EX2: sätter radbehörighet på alla tabeller under /Acceptanstest/LUL/FTV; */
%*setRowSecurity(PATH=/Acceptanstest/LUL/FTV/);


