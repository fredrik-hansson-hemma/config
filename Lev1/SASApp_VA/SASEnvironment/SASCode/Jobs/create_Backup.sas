/*********************************************
* Macro: create_Backup.sas
* Skapar backup av SAS Metatdata genom att göra .spk paket.
* .Spk paket skapas av foldrarna User folders, Generella rapporter, LUL, Shared data.
*********************************************/


%put NOTE: Det här borde vara enklare att ha som ett skript direkt, istället för att gå omvägen via SAS... ;


%* macro create_Backup();

* Tar bort meddelande i loggen om långa strängar.	;
options noquotelenmax;



%put ENTER: create_Backup;

%let filepath=/saswork/scripts/; * Sökväg till katalog på server där skript lagras.;
%let backuppath=/opt/sas/backup/; * Sökväg till katalog på server där backuperna lagras.;
%let datum = %sysfunc(putn(%sysfunc(today()), yymmdd6.)); * Datum som används i namnet på .spk paketen.;


* Försöker skapa kataloger där skriptet ska skapas och backup:er ska lagras.	;
options dlcreatedir;
libname _dummy_ "&filepath";
libname _dummy_ "&backuppath";
libname _dummy_ clear;
options nodlcreatedir;

*filename textfile "&filepath.backup.sh"; * En skriptfil skapas med samma namn som tabellen som ska behörighetstyras.; 

data _null_;
  * length commando $300.; 
  file "&filepath.backup.sh";
  * Sökväg där Export Package tool finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4"; 
  * Anropar Export Package Tool. - Allt under folder User Folders. Exkluderar tomma kataloger;
  put "./ExportPackage -host bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}7D55EB1F27B29BC354FD035416238B741C2BF86732381F40 -package  '&backuppath.UserFolders_&datum..spk' -objects  '/User Folders' -types 'Folder,Report,Table,Project,InformationMap,Cube' -includeDep -disableX11";

  * Folder Utveckling.;	
  put "./ExportPackage -host bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}7D55EB1F27B29BC354FD035416238B741C2BF86732381F40 -package  '&backuppath.LUL_&datum..spk' -objects  '/LUL' -types 'Folder,Report,Table,Project,InformationMap,Cube' -includeDep -disableX11";
  
	* Folder Acceptanstest.;	
  put "./ExportPackage -host bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}7D55EB1F27B29BC354FD035416238B741C2BF86732381F40 -package  '&backuppath.LULgemensam_&datum..spk' -objects  '/LUL gemensam' -types 'Folder,Report,Table,Project,InformationMap,Cube' -includeDep -disableX11";
	
	* Folder Shared Data.;
	/*
  put "./ExportPackage -host bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}7D55EB1F27B29BC354FD035416238B741C2BF86732381F40 -package  '&backuppath.SharedData_&datum..spk' -objects  '/Shared Data' -types Folder Report Table Project InformationMap Cube -includeDep";
	*/
run;

* Sätter rättigheter på skriptet.;
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


/************
%mend;

* Exempel på anrop;
%create_Backup();

***********/