/****************************************************
* Macro: get_env
*
* Hämtar miljö beroende på 
* metadataserver som körs på maskinen.
* Om produktionsmiljö, blir ENV = .
* Om testmiljö, blir ENV = BST.
*****************************************************/
%macro get_env();

%let metas = %sysfunc(getoption(METASERVER));
%let env = %sysfunc(scan(&metas, 1, '-'));

&env

%mend;

/* Exempel på anrop: */ 
%*let env = %get_env();
%*put ENV: &env;
