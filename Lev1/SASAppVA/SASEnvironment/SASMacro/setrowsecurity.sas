/*****************************************************************************
* Macro: setRowSecurity                     
* S�tter radbeh�righet p� en tabell i en LASR-server. 
* Macrot ger l�sr�ttigheter f�r hela tabellen till grupperna:
* SASAdministrators, SAS VA Administrat�r, SAS General Servers, SAS Batch och Systemutvecklare.
* L�sr�ttigheter begr�nsas f�r gruppen Sassusers, dvs �vriga anv�ndare med metadatakonto i Sas. 
* Radbeh�righet s�tts med ett filter p� kolumnen som skickas med som namn i parametern COLUMN.  
*
* Av: Mattias Moliis, Infotrek
* Datum: 2014-03-26
* Parametrar:
* PATH: S�kv�g till tabell i metadata
* TABLE: Tabell som ska beh�righetsstyras. Om inget v�rde f�r parameter TABLE, k�rs macrot f�r alla tabeller under PATH.
*
* �ndringar:
* Datum: 2015-03-06 Mattias Moliis
* Skapat logik f�r att hantera blankt v�rde f�r parameter TABLE.
*
* Datum: 2015-03-13 Mattias Moliis
* Tabellen  m�ste inneh�lla b�gge kolumnerna BEHORIGHET1 och BEHORIGHET2 annars kan inte gruppen SASUSERS l�sa tabellen.
*
* Datum: 2017-01-23 Mattias Moliis
* Rensat skript fr�n koll att r�tt kolumner finns med.
******************************************************************************/


%macro setrowsecurity(path=,table=);
%put Enter setRowSecurity Path: &path Table: &table;

%let env = %get_env();
%put ENV: &env;
%if %sysfunc(upcase(&env)) = BST %then %let filepath=/SASWORK/scripts/; * S�kv�g till katalog p� server d�r skript lagras.;
%if %sysfunc(upcase(&env)) = BS %then %let filepath=/saswork/scripts/;

%if "&TABLE" = "" %then %do;
  %put Macrot setRowSecurity kommer att kolla alla tabeller under &path..;
%end;
%if "&TABLE" ne "" %then %do;
  %put Macrot setRowSecurity kommer att kolla tabell &path.&table..;
%end;

%get_metaserverattr;

/* H�mtar inloggningsuppgifter f�r metadataservern */
%let metaserver = %sysfunc(putc(%lowcase(%get_env()), $metaserver));
%let metaport = %sysfunc(putc(%lowcase(%get_env()), $metaport));
%let metauser = %sysfunc(putc(%lowcase(%get_env()), $metauser));
%let metapass = %sysfunc(putc(%lowcase(%get_env()), $metapass));

/* Om parametern table �r tom ska alla tabeller i path h�mtas in. */ 
%if "&TABLE" = "" %then %do;

%mdsecds(folder="&path", membertypes="Table", includesubfolders=no);
 /* Tar ocks� bort de tabeller som inneh�ller _STG i namnet, dessa �r Hadoop-tabeller. */
 Proc sort data=work.mdsecds_objs (where=(not index(upcase(objname), "_STG"))) out=tables(keep=objname);
  by location objname;
  where publicType = 'Table';
 run; 
%end; /* end: %if "TABLE" = "" */

/* Om parametern table har ett v�rde ska beh�righet s�ttas bara p� den tabellen. */ 
%if "&TABLE" ne "" %then %do;
  data tables;
  	memname="&table";
  run;
%end; /* end: %if "TABLE" ne ""*/

/* S�tt radbeh�righeten. */

%let dsid = %sysfunc(open(TABLES));
%if &dsid %then %let nobs = %sysfunc(attrn(&dsid, NOBS));


%do %while (%sysfunc(fetch(&dsid)) = 0);

 	%let table = %sysfunc(getvarc(&dsid, 1));
	%put TABLE= &table;

  filename textfile "&filepath.&table..sh" termstr=LF; * En skriptfil skapas med samma namn som tabellen som ska beh�righetstyras.; 

data _null_;
  length commando $400.; 
  file textfile encoding=utf8;
  put "#!/bin/bash -p";
  /* S�kv�g d�r Sas Batch tool finns. */
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
  /* Anropar Sas Batch Tool sas-set-metadata-access. - removeAll tar bort alla beh�righetsrestriktioner p� tabellen. */
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -removeAll";
  /* L�sr�ttigheter s�tts f�r de grupper som ska undantas fr�n beh�righetsrestriktioner. */
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant SASAdministrators:Read";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant 'SAS VA Administrator:Read'";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant 'SAS General Servers:Read'";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant 'SAS Batch:Read'";
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant Systemutvecklare:Read";
  /* S�tt villkorlig beh�righet till gruppen Sasusers. */
  commando=
  "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -grant sasusers:Read -condition "||'"'||"behorighet1 IN ('SUB::SAS.IdentityGroups') or behorighet2 IN ('SUB::SAS.IdentityGroups')"||'"';
  put commando;
run;

/* Tar bort BOM (Byte Order Mark) tecken fr�n filen innan den k�rs p� Linux. */
filename perla pipe "perl -piw -e 's/^\xEF\xBB\xBF//' &filepath.&table..sh";

data _null_;
  infile perla;
run;

/* S�tter r�ttigheter p� skriptet. */
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

/* Exempel p� anrop;
 EX1: s�tter radbeh�righet p� tabell /Acceptanstest/LUL/Ekonomi_budget */
%*setRowSecurity(PATH=/Acceptanstest/LUL/Folktandv�rden/Data/,TABLE=TEST296���);

/* EX2: s�tter radbeh�righet p� alla tabeller under /Acceptanstest/LUL/FTV; */
%*setRowSecurity(PATH=/Acceptanstest/LUL/FTV/);


