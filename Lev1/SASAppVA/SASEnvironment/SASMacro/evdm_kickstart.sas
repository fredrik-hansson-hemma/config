/***************************************************/
/* Copyright (c) 2014 SAS Institute Inc.           */
/* SAS Campus Drive, Cary, NC, USA                 */
/* All Rights Reserved                             */
/***************************************************/

%macro EVHSTTYP;
   %let scp = %substr(&sysscp.1,1,3);
   %goto LAB&scp;

%* Homogenize all UNIX systems;
   %LABLIN:                                        %* Linux;
   %LABHP:                                         %* HP;
   %LABSUN:                                        %* SUNOS;
   %LABAIX:                                        %* AIX;
   %UNIX:
      %do; OSYS %end;
      %goto EXIT;
   %LABOS:                                         %* z/OS;
      %do; MVS %end;
      %goto EXIT;
   %LABWIN:                                        %* WIN;
      %do; WIN %end;
      %goto EXIT;
	%EXIT:
%mend evhsttyp;

 /*---------------------------------------------------------------------------
  * NAME: %evrunautoexec
  *                             
  * DESC: Macro to support running stp programs in batch, via EG or via STP Server
  *       Skips the autoexec call if running in batch
  *-------------------------------------------------------------------------*/
%macro evrunautoexec;
   %global EVAUTOEXECTRUE;
   data null;
      if upcase("&EVAUTOEXECTRUE") ne "TRUE" then
         call execute('%include "&SASEVCONFIGDIR/Datamart/EVDMAUTOEXEC_STP.sas";');
   run;
%mend evrunautoexec;

%macro evdm_kickstart(propfile=%str(../Web/SASEnvironmentManager/emi-framework/sasev.properties),prefix=sasevdm);
   
   %put NOTE: *** EVDM_KICKSTART Called ***;
   %if %sysfunc(envlen(SASEVCONFIGDIR)) gt 0 %then %goto EXIT;
   
   %put NOTE: *** EVDM_KICKSTART Loading properties (Host Type:[%EVHSTTYP]) ***;

   filename props "&propfile";

   data _null_;
      length line $512 propname propvalue $256;
      infile props lrecl=512 missover pad;
      input line &;

      if line ne: "#" and line ne "";

      propname=compress(scan(line,1,"="),".");
    
      propvalue=scan(line,2,"=");
 	 %if "%EVHSTTYP" = "WIN" %then %do;
      	propvalue=tranwrd(propvalue,'\\','\');
      %end;
      call symputx(propname,propvalue,'G');
      
      *put propname= propvalue=; /* remove for debugging */
   run;
   
   %EXIT:
   
%mend evdm_kickstart;
