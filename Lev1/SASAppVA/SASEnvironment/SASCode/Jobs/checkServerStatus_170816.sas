/****************************************************
* Program: checkServerStatus.sas
*
* L�ser av resultat fr�n "sas.servers status" och mejlar om n�gon av processerna �r "NOT running".
*****************************************************/

%macro checkServerStatus();
filename status "/tmp/SASServerStatus.txt";

data statusds;
  length rad $200;
  infile status lrecl=200 dsd missover ;
	input rad $;
run;

data checkstatus;
  set statusds;
	if index(rad, 'NOT') and not index(rad, 'SAS Web Server') then flagga = 1;
run; 

proc sql noprint;
  select count(*) into :flagga
	from checkstatus
	where flagga = 1;
quit;

%if &flagga > 0 %then %do;
  
filename outbox email 
	to=("mattias.moliis@infotrek.se" "bjorn.rengerstam@akademiska.se" "magnus.knopf@akademiska.se") 
	subject="SAS Servers not running"
	attach=("/tmp/SASServerStatus.txt")
 ;

data _null_;
  file outbox;
	 put "Status fr�n sas.servers.";
run;

%end;

%mend;

%checkServerStatus;