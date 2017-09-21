/****************************************************
* Macro: get_env
*
* H�mtar milj� beroende p� 
* metadataserver som k�rs p� maskinen.
* Om produktionsmilj�, blir ENV = .
* Om testmilj�, blir ENV = BST.
*****************************************************/
%macro get_env();

%let metas = %sysfunc(getoption(METASERVER));
%let env = %sysfunc(scan(&metas, 1, '-'));

&env

%mend;

/* Exempel p� anrop: */ 
%*let env = %get_env();
%*put ENV: &env;
