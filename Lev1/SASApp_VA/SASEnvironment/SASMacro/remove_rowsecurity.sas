/*****************************************************************************
* Macro: remove_RowSecurity                     
* Tar bort radbehörighet på en tabell i en LASR-server. 
* 
* Av: Mattias Moliis, Infotrek
* Datum: 2014-03-26
* Parametrar:
* ENV: Miljö som macrot körs i (PROD eller TEST) 
* PATH: Sökväg till tabell i metadata
* TABLE: Tabell som ska behörighetsstyras.
*
* Ändringar:
******************************************************************************/


%macro remove_rowsecurity(path=,table=);
%put Enter removeRowSecurity Path: &path Table: &table;

%let env = %get_env();
%put ENV: &env;
%if %sysfunc(upcase(&env)) = BST %then %let filepath=/SASWORK/scripts/; * Sökväg till katalog på server där skript lagras.;
%if %sysfunc(upcase(&env)) = BS %then %let filepath=/saswork/scripts/;

%get_metaserverattr;

* Hämtar inloggningsuppgifter för metadataservern;
%let metaserver = %sysfunc(putc(%lowcase(%get_env()), $metaserver));
%let metaport = %sysfunc(putc(%lowcase(%get_env()), $metaport));
%let metauser = %sysfunc(putc(%lowcase(%get_env()), $metauser));
%let metapass = %sysfunc(putc(%lowcase(%get_env()), $metapass));

filename textfile "&filepath.&table..sh"; * En skriptfil skapas med samma namn som tabellen som ska behörighetstyras.; 

data _null_;
  length commando $300.; 
  file textfile encoding=utf8;
	put "#!/bin/bash -p";

  * Sökväg där Sas Batch tool finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
   * Anropar Sas Batch Tool sas-set-metadata-access. - removeAll tar bort alla behörighetsrestriktioner på tabellen.;
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -removeAll";
run;

/* Tar bort BOM (Byte Order Mark) tecken från filen innan den körs på Linux. */
filename perla pipe "perl -piw -e 's/^\xEF\xBB\xBF//' &filepath.&table..sh";

data _null_;
  infile perla;
run;

* Sätter rättigheter på skriptet.;
filename chmod pipe "chmod 777 &filepath.&table..sh";

data _null_;
  infile chmod;
run;

* Exekverar skriptet och skriver standard output till logfil.;
filename exec pipe ". &filepath.&table..sh >& &filepath.&table..log";

data _null_;
  infile exec;
run;

%put Exit removeRowSecurity;
%mend;

* Exempel på anrop;
%*remove_rowsecurity(PATH=/Acceptanstest/LUL/Folktandvården/Data/,TABLE=TEST296ÅÄÖ);


