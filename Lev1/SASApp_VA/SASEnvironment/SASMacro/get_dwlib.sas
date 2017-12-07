/****************************************************
 * Macro: get_dwlib
 *
 * Hämtar libname för datalagret baserat på vilken 
 * metadataserver som körs på maskinen.
 * Om produktionsmiljö hämtas datalagret för produktionsmiljön.
 * Om testmiljö, blir det datalagret test.
 *****************************************************/
%macro get_dwlib();
	%local dwlib;
	%let metas = %sysfunc(getoption(METASERVER));
	%let env = %sysfunc(scan(&metas, 1, '-'));

	%if %upcase(&env) = BST %then
		%let dwlib=luldwt;
	%else %if %upcase(&env) = BS %then %let dwlib=luldw;
	%else %do;
		%put "%STR(ER)ROR: Macrot get_dwlib kunde inte avgöra testmiljö eller prodmiljö.";
	%end;

	&dwlib

%mend;

/* Exempel på anrop: */
%*let dw = %get_dwlib();
%*put DW: &dw;