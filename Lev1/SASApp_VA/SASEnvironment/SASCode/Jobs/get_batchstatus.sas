
%let path=/saswork/batchrun;

* Skapar kataloger om de inte redan finns.	;
options dlcreatedir;
libname batchsta "&path";
libname backup__ "&path/backup";
options nodlcreatedir;
libname batchsta clear;
libname backup__ clear;



%let today = %sysfunc(putn(%sysfunc(today()), yymmdd8.)); * Dagens datum i format yyyymmdd.;

filename returkod "&path./returncodes.txt" ; * Returkoder från batchkörningar.;
filename complete "&path./completejobs.html" ; * Utfil med jobb som gått klart.;
filename error "&path./errorjobs.html" ; * Utfil med jobb som gått fel.;
filename comp_ftv "&path./completejobs_FTV.html" ; * Utfil med jobb som gått klart (för FTV).;
filename err_ftv "&path./errorjobs_FTV.html" ; * Utfil med jobb som gått fel (för FTV).;
filename comp_epj "&path./completejobs_EPJ.html" ; * Utfil med jobb som gått klart (för EPJ).;
filename err_epj "&path./errorjobs_EPJ.html" ; * Utfil med jobb som gått fel (för EPJ).;

proc format lib=work;
  value batchkod
	0='OK'
	1='WARNING'
	9='AVBRUTET'
	other='ERROR'
	;
 run;

* Hämtar sas-program och returkod från filen Returncodes.txt.;
data tmp1(keep=returncode program date);
	attrib txt length=$2000;
	attrib rc length=$10;
	attrib returncode length=8.;
	attrib program length=$256;
	attrib date length=8 informat=yymmdd8. format=yymmdd10.;
	infile returkod ls=4000 truncover termstr=nl dlm=':';
	input txt rc date;

	* date=input(compress(date_string, "Datum:"), yymmdd8.);
	* förutsätter att batchkommandot har med -sysin;
	index = index(txt, '-sysin');

	* hämtar namnet på sas-programmet, förutsätter att det står sist i batchkommandot.;
	stage = scan(reverse(substr(txt, index)), 1, '/');
	stage2 = left(reverse(stage));
	program = scan(stage2, 1, ' ');

	* rensar rc från skräptecken och gör om till numeriskt värde.;
	returncode =input(scan(rc,1,' '), best8.);

	/******* Alternativt sätt att ta fram programnamnet
	* Sparar regular expression	;
	re = prxparse("/\/\w+\.sas/");
	* Hittar programnamnets position	;
	position=prxmatch(re, txt);

	programnamnX=substr(txt,position+1,index(txt, ".sas")+3-position);
	*********************/

run;




proc sort data=tmp1 out=tmp2 nodupkey;
  by program descending date returncode;
run;

* Varje program kan vara schemalagt att gå flera gånger samma dygn. Vi hämtar den senaste körningen
* per dygn och program. Om laddjobbet har gått bra ger det returkod 0, om det gett varningar ger det returkod 1 
* och om det har gått fel ger det en returkod större än 1.; 
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


**** Skickar inte längre mail till "beslutsstod@regionuppsala.se". Det blir för många. Berörda parter får ändå mailen.		****;
%let to_beslutstod_error	=	"fredrik.hansson@regionuppsala.se" "hakan.edling@regionuppsala.se" "jan.von.knorring@regionuppsala.se" "karl.alvtorn@regionuppsala.se";
%let to_ftv_error			=	"fredrik.hansson@regionuppsala.se" "ftv.it@lul.se";
%let to_ftv_ok				=	"joakim.bergquist@lul.se";
%let to_epj_error			=	"fredrik.hansson@regionuppsala.se" "fredrik.lagerqvist@regionuppsala.se" "mats.eberhardsson@regionuppsala.se" "mats.bystrom@regionuppsala.se" "irene.marx.melin@regionuppsala.se";
%let to_epj_ok 				=	"fredrik.hansson@regionuppsala.se" "fredrik.lagerqvist@regionuppsala.se" "mats.eberhardsson@regionuppsala.se" "mats.bystrom@regionuppsala.se" "irene.marx.melin@regionuppsala.se";


%macro get_batchstatus();

	%if &antalerror ne 0 %then %do;
		%let subject = Status batch - jobb i error;

		/********* Endast bifogade filer	********* 
		filename outbox email 
			to=(&to_beslutstod_error) 
			subject="&subject"
			attach=("&path./completejobs.html" "&path./errorjobs.html")
		;

		data _null_;
			file outbox;
			put "Status från batchkörning &today.";
		run;
		/********* ********* ********* ********* *********/ 

		
		/*********	HTML i mailets body	*********/
		filename outbox email
			to=(&to_beslutstod_error)
			subject="&subject"
			content_type="text/html"
			attach=("&path./completejobs.html" "&path./errorjobs.html")
		;

		data _null_;
		  file outbox;
		  infile error lrecl=32767;
		  input;
		  put _infile_;
		run;
		/********* ********* ********* ********* *********/ 

		filename outbox clear;
		

	%end;
	%else %do;
		%let subject = Status batch - jobb ok!;
	%end;

	%if &antalerror_ftv ne 0 %then %do;
		%let subject = Status batch Beslutsstöd/FTV - jobb i error;
		filename outbox email 
			to=(&to_ftv_error) 
			subject="&subject"
			attach=("&path./completejobs_FTV.html" "&path./errorjobs_FTV.html")
		;

		data _null_;
			file outbox;
			put "Status från batchkörning &today.";
		run;

	%end;
	%else %do;
		%let subject = Status batch Beslutstöd/FTV - jobb ok!;
		filename outbox email 
			to=(&to_ftv_ok) 
			subject="&subject"
			attach=("&path./completejobs_FTV.html")
		;

		data _null_;
			file outbox;
			put "Status från batchkörning &today.";
		run;

	%end;

	%if &antalerror_epj ne 0 %then %do;
		%let subject = Status batch Beslutsstöd/EPJ - jobb i error;
		filename outbox email 
			to=(&to_epj_error) 
			subject="&subject"
			attach=("&path./completejobs_EPJ.html" "&path./errorjobs_EPJ.html")
		;

		data _null_;
			file outbox;
			put "Status från batchkörning &today.";
		run;

	%end;
	%else %do;
		%let subject = Status batch Beslutstöd/EPJ - jobb ok!;
		filename outbox email 
			to=(&to_epj_ok) 
			subject="&subject"
			attach=("&path./completejobs_EPJ.html")
		;

		data _null_;
			file outbox;
			put "Status från batchkörning &today.";
		run;

	%end;
%mend;

%get_batchstatus;






* Datumstämplar Returncodes.txt och flyttar till backup.;
data _null_;
	rc=rename("&path./returncodes.txt", "&path./backup/returncodes_&today..txt", 'FILE');
	if rc NE 0 then put "ERROR: Något gick fel med kopieringen av &path./returncodes.txt";
run;


* Skapar en ny fil Returncodes.txt.;
filename _newfile "&path./returncodes.txt";
data _null_;
  file _newfile;
run;


* Ändrar rättigheter på Returncodes.txt.;
filename chmod pipe "chmod 777 &path./returncodes.txt";

data _null_;
  infile chmod;
run;
