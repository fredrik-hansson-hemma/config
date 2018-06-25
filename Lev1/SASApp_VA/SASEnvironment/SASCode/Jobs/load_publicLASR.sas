/*********************************************
* Program: load_publicLASR
* Laddar tabeller fr�n VAPUBLIC in i LASR servern.
*********************************************/


%put ENTER: load_publicLASR;



* H�mtar v�rden fr�n en property-fil, f�r att kunna anv�nda det h�r programmet i b�de test- och prodmilj�er	;
%get_property(property=metaserver)
%get_property(property=lasrserver)
%get_property(property=sasadm_pass)
%get_property(property=lasr_signer_port)
%get_property(property=lasr_signer_server)

* Verifierar att v�rden har h�mtats		;
%put &=metaserver;
%put &=lasrserver;
%put &=lasr_signer_port;
%put &=lasr_signer_server;








%LET VDB_GRIDHOST=&lasrserver;
%LET VDB_GRIDINSTALLLOC= /opt/sas/TKGrid;
options set=GRIDHOST="&lasrserver";
options set=GRIDINSTALLLOC=" /opt/sas/TKGrid";
options validvarname=any validmemname=extend;

LIBNAME VAPUBLIC BASE "/opt/sas/config/Lev1/AppData/SASVisualAnalytics/VisualAnalyticsAdministrator/PublicDataProvider";
LIBNAME LASRLIB SASIOLA  TAG=VAPUBLIC  PORT=10031 HOST="&lasrserver"  SIGNER="https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization";

* H�mtar alla tabeller som finns i Public Data Provider.;
proc sql noprint;
	create table work.pdptables(index=(memname)) as
	select memname from dictionary.tables
	where upcase(libname) = "VAPUBLIC";
quit;





%* Skapar en tom tabell f�r att slippa f� felmeddelande om att
%* ingen tabell skapats av proc datasets nedan (f�r att det inte finns n�gra LASR-tabeller).		;
data work.lasrtables(rename=(memname=name));
	set work.pdptables(OBS=0);
run;

* H�mtar alla tabeller som finns i LASR servern.;
ods _all_ close;
ods output Members=work.lasrtables;
proc datasets library=LASRLIB memtype=data;
run;
quit;
ods _all_ close;





data work.lasrtables(rename=(name=memname) index=(memname));
	length name $32;
	set work.lasrtables(keep=name);
	%if "&vatable" ne "" %then %do;
		where upcase(name) = "&vatable"
	%end;
run;





* Sparar de tabeller som finns p� disk men inte i LASR servern.	;
data work.load_publicLASR;
	merge	work.pdptables(in=in_pdp)
			work.lasrtables(in=in_lasr);
	if in_pdp and not in_lasr;
run;






* Genererar ett program som l�ser in alla public-tabeller p� nytt.	;
* Detta program inkluderas sedan.									;


filename publ_pgm "/tmp/load_publicLASR_genererat_program.sas";

data _null_;
	file publ_pgm encoding='utf-8';
	put 'options validvarname=any validmemname=extend;';
	put 'LIBNAME VAPUBLIC BASE "/opt/sas/config/Lev1/AppData/SASVisualAnalytics/VisualAnalyticsAdministrator/PublicDataProvider";';
	put 'options noerrabend;';

	* ===============================================================================	;
	* Verkar inte alltid vara n�dv�ndigt, men kan beh�vas f�r att slippa
	* "ER ROR: Unable to connect to Metadata Server"
	* ===============================================================================	;
	put "options metaserver=""&metaserver""";
	put '	metaport=8561';
	put '	metauser="sasadm@saspw"';
	put "	metapass=""&sasadm_pass""";
	put '	metarepository="Foundation";';

run;

%macro load_publicLASR();
	%let dsid = %sysfunc(open(work.load_publicLASR));

	%do %while ((%sysfunc(fetch(&dsid))) = 0);
		%let loadtable=%upcase(%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,memname)))));
		%put LOADTABLE= &loadtable;

		%let oo= %str(%'&loadtable%'n);

		data _null_;
			file publ_pgm mod encoding='utf-8';
			put ' ';
			put ' ';
			put '/* Drop existing table from lasr */';
			put "%nrstr(%%)vdb_dt(LASRLIB.&oo);";

			put "proc lasr port=10031";
			put "data=VAPUBLIC.&oo";
			put     "signer=""https://&lasr_signer_server:&lasr_signer_port/SASLASRAuthorization""";
			put     "add noclass;";
			put 	  "performance host=""&lasrserver"";";
			put  "run;";
		run;

	%end;

	%let dsid = %sysfunc(close(&dsid));
	%put EXIT: load_publicLASR;
%mend load_publicLASR;

* Anrop;
%load_publicLASR










* ===============================================================================	;
* Verkar inte alltid vara n�dv�ndigt, men kan beh�vas f�r att slippa
* "ER ROR: Unable to connect to Metadata Server"
* ===============================================================================	;
options metaserver="&metaserver"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="&sasadm_pass"
	metarepository="Foundation";






%put Inkluderar programmet som genererades ovan: ;
%include '/tmp/load_publicLASR_genererat_program.sas' /source2;




%put Om n�got gick galet med programmet Anropa s�h�r:;
%put '/opt/sas/config/Lev1/SASApp_VA/BatchServer/sasbatch.sh -batch -noerrabend -noterminal -log /tmp/load_publicLASR_genererat_program_ altlog=/dev/stdout -print /SASLOG/BatchServer/Output/load_publicLASR_genererat_program.lst -sysin /tmp/load_publicLASR_genererat_program.sas &';



