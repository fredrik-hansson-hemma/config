proc format ;
  value $MDOBJ 'AUTHDOMAIN'='Authentication Domain' 
               'EMAIL' = 'Email Address'
               'GRPMEMS'='Group Memberships'
               'IDGRPS'='Groups'
               'LOCATION'='Location'
               'LOGINS'='Logins'
               'PERSON'='Person'
               'PHONE'='Phone Numbers' ;
run;

/* Create summary information of the changes */
proc sql noprint ;
	create table work.stats as
		select put(scan(memname,1,'_'), $MDOBJ.) as type label="Category",
		      nlobs as records label="Records", 
		      propcase(scan(memname,2,'_')) as Action
		from sashelp.vtable
		where libname='METAUPD';
quit;

proc transpose data=work.stats(where=(Action ne 'Summary')) out=work.stats(drop = _name_ _label_) ;
	by type;
	id Action;
run;

ods listing close;
ods listing file=report;
title "Summary of Metadata Updates from Active Directory" ;
proc print data=work.stats noobs;
run;
ods listing close;
ods listing;


/***************************************************************/
/* Jämför AD-grupper med Path i den ekonomiska organisationen. */
/***************************************************************/
%macro jmf_ad();
%let path=/tmp/;
%let today = %sysfunc(putn(%sysfunc(today()), yymmdd8.)); * Dagens datum i format yyyymmdd.;
data ldapgrps (keep=path);
	set adext.ldapgrps (keep=name);
	length ansvar_path $50;

	name1 = left(reverse(upcase(name))); 
	if substr(name1, 1, 4) ne 'SAS-' then delete;

	if substr(name1, 1, 4) = 'SAS-' then do;
		path = left(reverse(substr(name1, 5)));
    antal = count(path, '-'); 
  end;
  
	* Räknar bort AD-grupper under nivå 3.;  
	if antal < 2 then delete;
run;

proc sort data=ldapgrps nodupkey; by path; run;
 
data ekorg (keep= path);
	set mds.ekorganisation (keep=ansvar_path);
	length path $50;
	path = left(upcase(ansvar_path));
  antal = count(path, '-'); 
	* Räknar bort AD-grupper under nivå 3.;  
	if antal < 2 then delete;	
run;

proc sort data=ekorg nodupkey; by path; run;

data finns_ad finns_mds;
	merge 
		ldapgrps (in=ad)
		ekorg (in=mds)
	;
	by path;
	if mds and ad then delete;
	if ad and not mds then output finns_ad;
	if mds and not ad then output finns_mds;
run;		

* Skriver ut till fil.;
ods listing close;
ods csv file="&path.Finns i AD och inte i EkonomiskOrganisation &today..csv";
proc print data=finns_ad noobs;
run;
ods csv close;
ods csv file="&path.Finns i EkonomiskOrganisation och inte i AD &today..csv";
proc print data=finns_mds noobs;
run;
ods csv close;
ods listing;


/* Start: Skickar mejl. */
%let day_of_week = %sysfunc(weekday(%sysfunc(today())));
* Om måndag.;
%if &day_of_week = 2 %then %do;
%let dsid_ad = %sysfunc(open(finns_ad));
%let antal_ad = %sysfunc(attrn(&dsid_ad, NOBS));
%let dsid_ad = %sysfunc(close(&dsid_ad));
%let dsid_mds = %sysfunc(open(finns_mds));
%let antal_mds = %sysfunc(attrn(&dsid_mds, NOBS));
%let dsid_mds = %sysfunc(close(&dsid_mds));

%if &antal_ad ne 0 or &antal_mds ne 0 %then %do;
        %let subject = Jämförelse AD och EkonomiskOrganisation: Avvikelser funna.;
%end;
%if &antal_ad eq 0 and &antal_mds eq 0 %then %do;
        %let subject = Jämförelse AD och EkonomiskOrganisation: Inga avvikelser funna.;
%end;

filename outbox email
        to=('mattias.moliis@infotrek.se' 'beslutsstod@support.lul.se')
        subject="&subject"
        attach=("&path.Finns i AD och inte i EkonomiskOrganisation &today..csv" 
								"&path.Finns i EkonomiskOrganisation och inte i AD &today..csv")
 ;

data _null_;
  file outbox;
         put "Avvikelserapport &today.";
run;
%end; * if day_of_week = 2;
/* Slut: Skickar mejl. */
%let pip = rm '&path.Finns i EkonomiskOrganisation och inte i AD &today..csv';
%put PIP: &pip;
filename tabort1 pipe "&pip";
data _null_;
  file tabort1;
run;
%let pip2 = rm '&path.Finns i AD och inte i EkonomiskOrganisation &today..csv';
%put PIP2: &pip2;
filename tabort2 pipe "&pip2";;
data _null_;
  file tabort2;
run;


%mend jmf_ad;

%jmf_ad;