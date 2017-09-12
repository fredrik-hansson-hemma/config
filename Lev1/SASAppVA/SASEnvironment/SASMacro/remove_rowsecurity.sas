/*****************************************************************************
* Macro: remove_RowSecurity                     
* Tar bort radbeh�righet p� en tabell i en LASR-server. 
* 
* Av: Mattias Moliis, Infotrek
* Datum: 2014-03-26
* Parametrar:
* ENV: Milj� som macrot k�rs i (PROD eller TEST) 
* PATH: S�kv�g till tabell i metadata
* TABLE: Tabell som ska beh�righetsstyras.
*
* �ndringar:
******************************************************************************/


%macro remove_rowsecurity(path=,table=);
%put Enter removeRowSecurity Path: &path Table: &table;

%let env = %get_env();
%put ENV: &env;
%if %sysfunc(upcase(&env)) = BST %then %let filepath=/SASWORK/scripts/; * S�kv�g till katalog p� server d�r skript lagras.;
%if %sysfunc(upcase(&env)) = BS %then %let filepath=/saswork/scripts/;

%get_metaserverattr;

* H�mtar inloggningsuppgifter f�r metadataservern;
%let metaserver = %sysfunc(putc(%lowcase(%get_env()), $metaserver));
%let metaport = %sysfunc(putc(%lowcase(%get_env()), $metaport));
%let metauser = %sysfunc(putc(%lowcase(%get_env()), $metauser));
%let metapass = %sysfunc(putc(%lowcase(%get_env()), $metapass));

filename textfile "&filepath.&table..sh"; * En skriptfil skapas med samma namn som tabellen som ska beh�righetstyras.; 

data _null_;
  length commando $300.; 
  file textfile encoding=utf8;
	put "#!/bin/bash -p";

  * S�kv�g d�r Sas Batch tool finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
   * Anropar Sas Batch Tool sas-set-metadata-access. - removeAll tar bort alla beh�righetsrestriktioner p� tabellen.;
  put "./sas-set-metadata-access -host &metaserver -port &metaport -user &metauser -password &metapass '&path.&table(Table)' -removeAll";
run;

/* Tar bort BOM (Byte Order Mark) tecken fr�n filen innan den k�rs p� Linux. */
filename perla pipe "perl -piw -e 's/^\xEF\xBB\xBF//' &filepath.&table..sh";

data _null_;
  infile perla;
run;

* S�tter r�ttigheter p� skriptet.;
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

* Exempel p� anrop;
%*remove_rowsecurity(PATH=/Acceptanstest/LUL/Folktandv�rden/Data/,TABLE=TEST296���);


