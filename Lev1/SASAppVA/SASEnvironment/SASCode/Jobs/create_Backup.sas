/*********************************************
* Macro: create_Backup.sas
* Skapar backup av SAS Metatdata genom att g�ra .spk paket.
* .Spk paket skapas av foldrarna User folders, Generella rapporter, LUL, Shared data.
*********************************************/

%macro create_Backup();
%put ENTER: create_Backup;

%let filepath=/saswork/scripts/; * S�kv�g till katalog p� server d�r skript lagras.;
%let backuppath=/opt/sas/backup/; * S�kv�g till katalog p� server d�r backuperna lagras.;
%let datum = %sysfunc(putn(%sysfunc(today()), yymmdd6.)); * Datum som anv�nds i namnet p� .spk paketen.;

*filename textfile "&filepath.backup.sh"; * En skriptfil skapas med samma namn som tabellen som ska beh�righetstyras.; 

data _null_;
  * length commando $300.; 
  file "&filepath.backup.sh";
  * S�kv�g d�r Export Package tool finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4"; 
  * Anropar Export Package Tool. - Allt under folder User Folders. Exkluderar tomma kataloger;
  put "./ExportPackage -host bs-ap-02.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE -package  '&backuppath.UserFolders_&datum..spk' -objects  '/User Folders' -types 'Folder,Report,Table,Project,InformationMap,Cube' -includeDep -disableX11";
  * Folder Utveckling.;	
  put "./ExportPackage -host bs-ap-02.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE -package  '&backuppath.LUL_&datum..spk' -objects  '/LUL' -types 'Folder,Report,Table,Project,InformationMap,Cube' -includeDep -disableX11";
  
	* Folder Acceptanstest.;	
  put "./ExportPackage -host bs-ap-02.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE -package  '&backuppath.LULgemensam_&datum..spk' -objects  '/LUL gemensam' -types 'Folder,Report,Table,Project,InformationMap,Cube' -includeDep -disableX11";
	
	* Folder Shared Data.;
	/*
  put "./ExportPackage -host bs-ap-02.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE -package  '&backuppath.SharedData_&datum..spk' -objects  '/Shared Data' -types Folder Report Table Project InformationMap Cube -includeDep";
	*/
run;

* S�tter r�ttigheter p� skriptet.;
filename chmod pipe "chmod 777 &filepath.backup.sh";

data _null_;
  infile chmod;
run;

* Exekverar skriptet och skriver standard output till logfil.;
filename exec pipe ". &filepath.backup.sh >& &filepath.backup.log";

data _null_;
  infile exec;
run;

%put EXIT: create_Backup;

%mend;

* Exempel p� anrop;
%create_Backup();

