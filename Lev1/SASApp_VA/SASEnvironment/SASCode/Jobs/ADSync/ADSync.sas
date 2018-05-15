/*
 * Updated Date: 2 Aug, 2012
 * Author: Paul Northrop, Alex Tang
 *
 * Description: Sync metadata users with Active Directory
 * This program is based on the synchronization sample in the Security Admin Guide. It supports these additional features   * that the sample does not yet provide:
 *   1. Automatically calculating the User's AD BaseDN depending on the fetched users
 *   2. Handle groups within groups (unlimited levels)
 *   3. More error handling
 *   4. Generate a report of changes
 * 
 *
 *
 * 2014-04-25 Mattias Moliis
 * Anpassning av koden för att passa LUL.
 *
 * 2015-01-22 Mattias Moliis
 * AD-gruppmedlemmar som inte har konton undantas från metadataupdateringen.
 *
 * 2015-04-20 Mattias Moliis
 * Aktiverat att Superanvändare läggs till "-W" grupperna . 
 *
 * 2015-09-29 Mattias Moliis
 * Stöd för att hantera vanliga AD-grupper (typ -Users -Users-FIM) i AD-grupper med ändelsen -SAS.
 *
 * 2015-12-07 Mattias Moliis
 * Lägger till en dag på fimObjects.enddate för att överbrygga ev glapp mellan anställningsperioder i AD.;
 *
 * 2016-01-20 Mattias Moliis
 * Vänder behörighetsstrukturen. Obs. detta är gjort bara för PV. 
 
*/


%let ADSyncPgm=/opt/sas/config/Lev1/SASApp_VA/SASEnvironment/SASCode/Jobs/ADSync;

* Ser till att katalogen nedan skapas automatiskt om den inte redan finns	;
options dlcreatedir;
libname create "/saswork/LUL";
libname create "/saswork/LUL/ADSync";
libname create clear;
%let ADSyncStaging = /saswork/LUL/ADSync;


%include "&ADSyncPgm/0_passwords.sas" /source2;
options nomprint nosymbolgen;
%include "&ADSyncPgm/1_Settings.sas" /source2;
%include "&ADSyncPgm/2_Macros.sas";

/* Step 1: Extract users, groups and memberships from Active Directory */
%mduimpc(libref=adExt, maketable=0);

%include "&ADSyncPgm/3_Recursion.sas";
%include "&ADSyncPgm/4_Normalize.sas";
%include "&ADSyncPgm/5_Indexing.sas";

/* Step 2: Extract users, groups and memberships from Metadata */
%mduextr(libref=metaExt);



/* Step 3: Compare #1 and #2 to generate the difference */
data work.exceptions;
    input tablename:$10. filter:$255.;
    datalines;
logins userid="&WindowsDomain.\sassrv"
logins userid="&WindowsDomain.\sasdemo"
logins userid="&WindowsDomain.\lasradm"
run;
%mducmp(master=adExt, target=metaExt, change=metaUpd, externonly=1, exceptions=work.exceptions);

/* Step 4: Check the difference for errors */
%mduchgv(change=metaUpd, target=metaExt, temp=work, errorsds=work.mduchgverrors);

/* Start: Anpassning LUL */
* Rensar logintabellen.;
data metaUpd.logins_delete;
	set metaUpd.logins_delete;
	stop;
run; 
* Skapar logins för nya konton;

data logins_add (keep=keyid userid password authdomkeyid objid externalkey);
	set 
	metaUpd.logins_add (obs=0)
	metaUpd.person_add
	;
	authdomkeyid = "domkeyDEFAULTAUTH";
	userid=keyid;
	output;
	authdomkeyid = "domkeyWEB";
	userid=keyid;
	output;

run;

data metaUpd.logins_add;
	set logins_add;
run;

/* Rensar de personer som inte finns som konton i AD. De ska inte läsas in som gruppmedlemar. */
data metaupd.grpmems_add;
	set metaupd.grpmems_add;
	if upcase(memobjtype) = 'PERSON' and missing(memobjid) then delete;
run; 

/* Slut: Anpassning LUL */


%include "&ADSyncPgm./6_Report.sas";

/* Step 5: Import the differences to the Metadata */
%macro exec_mduchglb;
	%if (&MDUCHGV_ERRORS ^= 0) %then %do;
		%put ERROR: Validation errors detected by %nrstr(%mduchgv). Load not attempted.;

    
		filename outbox email 
	  to=("magnus.knopf@akademiska.se" "peter.ostrom@akademiska.se" "fredrik.hansson@regionuppsala.se") 
	  subject="ADSynk stoppad. Rensa bland SAS-grupper och användarkonton";

    data _null_;
      file outbox;
	    set work.mduchgverrors (keep=errmsg name userid);
			put "Felkod: " errmsg "Gruppnamn: " name "Användarkonto: " userid;
    run;

		%abort abend;
	%end;
	%mduchglb(change=metaUpd, temp=work, failedobjs=work.mduchglb_failedobjs, extidtag=IdentityImport);
	/* LUL anpassning: skriv över varningar som ok. */
  %if &SYSCC = 4 %then %let SYSCC = 0;
	/* Slut: LUL anpassning. */
%mend;
%exec_mduchglb;




