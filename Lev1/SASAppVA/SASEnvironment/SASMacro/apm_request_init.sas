/**********************************************************************************/
/*                                                                                */
/* Copyright (c) 2011, SAS Institute Inc., Cary, NC, USA, All Rights Reserved     */
/*                                                                                */
/**********************************************************************************/

%macro apm_request_init;

/*
 *  Define the execution of the ARM to specific userid versus "sas server" userid.
 */

%global _armexec;

%let _armexec=1;

%let clientname = %scan(%sysfunc(getoption(METAUSER)),1,'@');

%if "&serverClass"="StoredProcessServer" %then %do;
    %let txtvalue=STOREDPROCESS;
    %let pgmvalue=&_program.;
    %end;
%else %do;
    %let txtvalue=PLWK_SESSION;
    %let pgmvalue=PooledWorkspaceServer;
    %end;

%ARMINIT(appname="&pgmvalue.",appuser="&clientname.",maconly=yes);

%ARMSTRT(getid=yes,maconly=yes,txnname="&txtvalue.");

%mend;

%apm_request_init;
