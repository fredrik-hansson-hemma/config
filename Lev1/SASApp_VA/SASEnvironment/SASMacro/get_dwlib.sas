/****************************************************
 * Macro: get_dwlib
 *
 * H�mtar libname f�r datalagret baserat p� vilken 
 * metadataserver som k�rs p� maskinen.
 * Om produktionsmilj� h�mtas datalagret f�r produktionsmilj�n.
 * Om testmilj�, blir det datalagret test.
 *****************************************************/
%macro get_dwlib();
	%local dwlib;
	%let metas = %sysfunc(getoption(METASERVER));
	%let env = %sysfunc(scan(&metas, 1, '-'));

	%if %upcase(&env) = BST %then
		%let dwlib=luldwt;
	%else %if %upcase(&env) = BS %then %let dwlib=luldw;
	%else %do;
		%put "%STR(ER)ROR: Macrot get_dwlib kunde inte avg�ra testmilj� eller prodmilj�.";
	%end;

	&dwlib

%mend;

/* Exempel p� anrop: */
%*let dw = %get_dwlib();
%*put DW: &dw;