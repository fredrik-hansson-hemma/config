%macro get_batchstatus();

%let path=/saswork/batchrun/;
%let today = %sysfunc(putn(%sysfunc(today()), yymmdd8.)); * Dagens datum i format yyyymmdd.;

filename returkod "&path.returncodes.txt" ; * Returkoder fr�n batchk�rningar.;
filename complete "&path.completejobs.html" ; * Utfil med jobb som g�tt klart.;
filename error "&path.errorjobs.html" ; * Utfil med jobb som g�tt fel.;
filename comp_ftv "&path.completejobs_FTV.html" ; * Utfil med jobb som g�tt klart (f�r FTV).;
filename err_ftv "&path.errorjobs_FTV.html" ; * Utfil med jobb som g�tt fel (f�r FTV).;
filename comp_epj "&path.completejobs_EPJ.html" ; * Utfil med jobb som g�tt klart (f�r EPJ).;
filename err_epj "&path.errorjobs_EPJ.html" ; * Utfil med jobb som g�tt fel (f�r EPJ).;

proc format lib=work;
  value batchkod
	0='OK'
	1='WARNING'
	9='AVBRUTET'
	other='ERROR'
	;
 run;

* H�mtar sas-program och returkod fr�n filen Returncodes.txt.;
data tmp1 (keep=returncode program date);
	attrib txt length=$400; 
	attrib rc length=$10;
	attrib returncode length=8.; 
	attrib program length=$40;
	attrib date length=8 informat=yymmdd8. format=yymmdd10.; 
 	infile returkod ls=400 truncover termstr=nl dlm=':';
	input txt rc date;
	* f�ruts�tter att batchkommandot har med -sysin;
	index = index(txt, '-sysin');
	* h�mtar namnet p� sas-programmet, f�ruts�tter att det st�r sist i batchkommandot.;
	stage = scan(reverse(substr(txt, index)), 1, '/');
	stage2 = left(reverse(stage));
  program = scan(stage2, 1, ' ');
  * rensar rc fr�n skr�ptecken och g�r om till numeriskt v�rde.;
	returncode =input(scan(rc,1,' '), best8.); 
run;

proc sort data=tmp1 out=tmp2 nodupkey;
  by program descending date returncode;
run;

* Varje program kan vara schemalagt att g� flera g�nger samma dygn. Vi h�mtar den senaste k�rningen
* per dygn och program. Om laddjobbet har g�tt bra ger det returkod 0, om det gett varningar ger det returkod 1 
* och om det har g�tt fel ger det en returkod st�rre �n 1.; 
data tmp3;
	set tmp2;
	by program descending date;
	if first.program then output;
	else delete;
run;

proc sql noprint;
	create table completejobs as
	select program, returncode, date
	from tmp3 where returncode =0
  and upcase(program) not contains 'FTV_LASR_' and 
  upcase(program) not contains 'EPJ_'
  order by program;

  create table errorjobs as
	select program, returncode, date
	from tmp3 where (returncode lt 0 or returncode ge 1)
	and upcase(program) not contains 'FTV_LASR_' and 
  upcase(program) not contains 'EPJ_'
  order by program;

	create table completejobs_ftv as
	select program, returncode, date
	from tmp3 where returncode =0
  and upcase(program) contains 'FTV_LASR_'
  order by program;

	create table errorjobs_ftv as
	select program, returncode, date
	from tmp3 where (returncode lt 0 or returncode ge 1)
	and upcase(program) contains 'FTV_LASR_'
  order by program;

  create table completejobs_epj as
	select program, returncode, date
	from tmp3 where returncode =0
  and upcase(program) contains 'EPJ_'
  order by program;

	create table errorjobs_epj as
	select program, returncode, date
	from tmp3 where (returncode lt 0 or returncode ge 1)
	and upcase(program) contains 'EPJ_'
  order by program;

	select count(*) into :antalerror
	from errorjobs;

	select count(*) into :antalerror_ftv
	from errorjobs_ftv;

	select count(*) into :antalerror_epj
	from errorjobs_epj;
quit;

* Skriver ut till fil.;
ods listing close;
ods html file=complete style=styles.plateau;
proc print data=completejobs noobs;
format returncode batchkod.;
run;
ods html close;
ods html file=error style=styles.plateau;
proc print data=errorjobs noobs;
format returncode batchkod.;
run;
ods html close;
ods html file=comp_ftv style=styles.plateau;
proc print data=completejobs_ftv noobs;
format returncode batchkod.;
run;
ods html close;
ods html file=err_ftv style=styles.plateau;
proc print data=errorjobs_ftv noobs;
format returncode batchkod.;
run;
ods html close;
ods html file=comp_epj style=styles.plateau;
proc print data=completejobs_epj noobs;
format returncode batchkod.;
run;
ods html close;
ods html file=err_epj style=styles.plateau;
proc print data=errorjobs_epj noobs;
format returncode batchkod.;
run;
ods html close;
ods listing;

%if &antalerror ne 0 %then %do;
	%let subject = Status batch - jobb i error; 

	filename outbox email 
	to=("mattias.moliis@infotrek.se" "beslutsstod@support.lul.se" "hakan.edling@regionuppsala.se" "jan.von.knorring@regionuppsala.se") 
	subject="&subject"
	attach=("&path.completejobs.html" "&path.errorjobs.html")
 ;

data _null_;
  file outbox;
	 put "Status fr�n batchk�rning &today.";
run;

%end;
%else %do;
	%let subject = Status batch - jobb ok!;
%end;

%if &antalerror_ftv ne 0 %then %do;
	%let subject = Status batch Beslutsst�d - jobb i error; 

	filename outbox email 
	to=("mattias.moliis@infotrek.se" "ftv.it@lul.se") 
	subject="&subject"
	attach=("&path.completejobs_FTV.html" "&path.errorjobs_FTV.html")
 ;

data _null_;
  file outbox;
	 put "Status fr�n batchk�rning &today.";
run;

%end;
%else %do;
	%let subject = Status batch Beslutst�d - jobb ok!;

	filename outbox email 
	to=("joakim.bergquist@lul.se") 
	subject="&subject"
	attach=("&path.completejobs_FTV.html")
 ;

data _null_;
  file outbox;
	 put "Status fr�n batchk�rning &today.";
run;
%end;

%if &antalerror_epj ne 0 %then %do;
	%let subject = Status batch Beslutsst�d - jobb i error; 

	filename outbox email 
	to=("mattias.moliis@infotrek.se" "fredrik.lagerqvist@regionuppsala.se" "mats.eberhardsson@regionuppsala.se"
  "mats.bystrom@regionuppsala.se" "irene.marx.melin@regionuppsala.se") 
	subject="&subject"
	attach=("&path.completejobs_EPJ.html" "&path.errorjobs_EPJ.html")
 ;


data _null_;
  file outbox;
	 put "Status fr�n batchk�rning &today.";
run;

%end;
%else %do;
	%let subject = Status batch Beslutst�d - jobb ok!;

	filename outbox email 
	to=("mattias.moliis@infotrek.se" "fredrik.lagerqvist@regionuppsala.se" "mats.eberhardsson@regionuppsala.se"
  "mats.bystrom@regionuppsala.se" "irene.marx.melin@regionuppsala.se") 
	subject="&subject"
	attach=("&path.completejobs_EPJ.html")
 ;

data _null_;
  file outbox;
	 put "Status fr�n batchk�rning &today.";
run;
%end;


* Datumst�mplar Returncodes.txt och flyttar till backup.;

filename move pipe "mv &path.returncodes.txt &path.backup/retuncodes_&today..txt";

data _null_;
  infile move;
run;

* Skapar en ny fil Returncodes.txt.;

filename create pipe "touch &path.returncodes.txt";

data _null_;
  infile create;
run;

* �ndrar r�ttigheter p� Returncodes.txt.;

filename chmod pipe "chmod 777 &path.returncodes.txt";

data _null_;
  infile chmod;
run;

%mend;

%get_batchstatus;

