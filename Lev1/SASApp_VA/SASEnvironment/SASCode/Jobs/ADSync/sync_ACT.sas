
/*********************************************
* Macro: list_ACT.sas
* Listar alla ACT:er som heter något på "LUL-". Skriver resultat till sastabell.
*********************************************/

%macro list_ACT();
%put ENTER: list_ACT;

%let filepath=/saswork/scripts/; * Sökväg till katalog på server där skript lagras.;

* Tar bort tempfil om  den finns.;
filename tabort pipe "rm /tmp/act.txt";

data _null_;
  infile tabort;
run;


data _null_;
  * length commando $300.; 
  file "&filepath.listACT.sh";

  * Sökväg där sas-list-objects finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
  * listar alla ACT:er som heter något på LUL-;
  put './sas-list-objects -host  bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE -types ACT -name "LUL-" > /tmp/act.txt';
run;

* Sätter rättigheter på skriptet.;
filename chmod pipe "chmod 777 &filepath.listACT.sh";

data _null_;
  infile chmod;
run;

* Exekverar skriptet och skriver standard output till loggfil.;
filename exec pipe ". &filepath.listACT.sh >& &filepath.listACT.log";

data _null_;
  infile exec;
run;

proc import file="/tmp/act.txt" out=_lista_act replace; getnames=no; guessingrows=500;
run;

* Texthantering, för att spara bara namnet på ACT;
data lista_act (keep=name);
  length name $60;
  set _lista_act;
	act_namn1 = tranwrd(var1,"(ACT)","");
	act_namn2 = tranwrd(act_namn1,"ACT","");
	name = tranwrd(act_namn2,"/System/Security/Access Control Templates/","");
run;
 
%put EXIT: list_ACT;

%mend;

/*********************************************
* Macro: create_ACT.sas
* Skapar ACT:er utifrån en lista av grupper.
* Skapar read-ACT som förval. Om gruppnamnet slutar på -W skapas write_ACT.
*********************************************/

%macro create_ACT();
%put ENTER: create_ACT;

%let filepath=/saswork/scripts/; * Sökväg till katalog på server där skript lagras.;
libname adExt "/saswork/LUL/ADSync/ADExtract"; * Sökväg till tabeller från ADSynk.;

* jämför befintliga ACT:er med nya grupper, skapar ACT om den inte finns;
data _idgrps;
	set adext.idgrps;
	name = compress(name);
run;

proc sort data=_idgrps (keep=name) out=idgrps nodupkey;
by name;
run;

data _lista_act;
	set lista_act;
	name = compress(name);
run;

proc sort data=_lista_act (keep=name) nodupkey;
by name;
run;

data nya_grupper;
	merge 
		idgrps (in=idgrps)
		_lista_act (in=lista_act);
  by name;
	if name =: 'LUL-SYSTEM' then delete;
	if idgrps and not lista_act then output;
	else delete;
run;	

* Tar bort tempfil om  den finns.;
filename tabort pipe "rm &filepath.createACT.sh";

data _null_;
  infile tabort;
run;

data _null_;
  * length commando $300.; 
  file "&filepath.createACT.sh";
  * Sökväg där sas-list-objects finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
run;

data _null_ (encoding=utf8);
  length text $300.; 
  file "&filepath.createACT.sh" mod;
  set nya_grupper (keep=name); 

	if substr(left(reverse(name)), 1, 2) = 'W-' and count(name, '-') <4 then do;
	text = compress(name||':ReadMetadata,WriteMetadata,CheckInMetadata,WriteMemberMetadata,ManageMemberMetadata,ManageCredentialsMetadata,Read,Write,Create,Delete,Select,Insert,Update,');
  
  put './sas-make-act -host  bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE "' name 'ACT" -create -grant ' text;
  end;
	if substr(left(reverse(name)), 1, 2) ^= 'W-' then  do;
	text = compress(name||':Read,ReadMetadata,Select');
  
	put './sas-make-act -host  bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE "' name 'ACT" -create -grant ' text;
  end;
run;

* Sätter rättigheter på skriptet.;
filename chmod pipe "chmod 777 &filepath.createACT.sh";

data _null_;
  infile chmod;
run;

* Exekverar skriptet och skriver standard output till loggfil.;
filename exec pipe ". &filepath.createACT.sh >& &filepath.createACT.log";

data _null_;
  infile exec;
run;

%put EXIT: create_ACT;

%mend;


/*********************************************
* Macro: delete_ACT.sas
* Tar bort ACT:er som det inte finns AD-grupper för.
*********************************************/

%macro delete_ACT();
%put ENTER: delete_ACT;

%let filepath=/saswork/scripts/; * Sökväg till katalog på server där skript lagras.;

* jämför befintliga ACT:er med nya grupper;
data _idgrps;
	set adext.idgrps;
	name = compress(name);
run;

proc sort data=_idgrps (keep=name) out=idgrps nodupkey;
by name;
run;

data _lista_act;
	set lista_act;
	name = compress(name);
run;

proc sort data=_lista_act (keep=name) nodupkey;
by name;
run;

data tabort_act;
	merge 
		idgrps (in=idgrps)
		_lista_act (in=lista_act);
  by name;
	if name ^=: 'LUL-' then delete;
	if lista_act and not idgrps then output;
	else delete;
run;	

* Tar bort tempfil om  den finns.;
filename tabort pipe "rm &filepath.deleteACT.sh";

data _null_;
  infile tabort;
run;

data _null_;
  * length commando $300.; 
  file "&filepath.deleteACT.sh";
  * Sökväg där sas-list-objects finns.;
  put "cd /opt/sas/sashome/SASPlatformObjectFramework/9.4/tools"; 
run;

data _null_ (encoding=utf8);
  length text $300.; 
  file "&filepath.deleteACT.sh" mod;
  set tabort_act (keep=name); 
	text = '"/System/Security/Access Control Templates/' || compress(name || '(ACT)"');
  put './sas-delete-objects -host  bs-ap-20.lul.se -port 8561 -user sasadm@saspw -password {SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE ' text;
run;

* Sätter rättigheter på skriptet.;
filename chmod pipe "chmod 777 &filepath.deleteACT.sh";

data _null_;
  infile chmod;
run;

* Exekverar skriptet och skriver standard output till loggfil.;
filename exec pipe ". &filepath.deleteACT.sh >& &filepath.deleteACT.log";

data _null_;
  infile exec;
run;

%put EXIT: delete_ACT;

%mend;


%list_ACT();

%create_ACT();

%delete_ACT();

