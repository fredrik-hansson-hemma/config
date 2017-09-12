/**********************************************************************************/
/*                                                                                */
/* Copyright (c) 2011, SAS Institute Inc., Cary, NC, USA, All Rights Reserved     */
/*                                                                                */
/**********************************************************************************/

%macro apm_armsetup;

/*
 *  Set up default ARM logging 
 */

/* Setup the default logging for ARM records will be to pass through
   the Log4SAS facility.
*/

options armagent=log4sas;
 
/*
 *  Determine the server and set the ServerClass appropriately
 *
 *    -set serverClass "xxxx"
 *
 *
 *
 */

%global serverClass;

%if %sysfunc(envlen(serverClass)) gt -1 %then
  %let serverClass=%sysget(serverClass);

%if "&serverClass."="" %then %do;

    /*
     *  ServerClass not set explicitly, figure it out.
     */

   data _null_;

      set sashelp.voption(where=(optname='LOG' or optname="DMR" or optname="OBJECTSERVER"));
   
      found=0;
      
      if optname="DMR" then do;
      
         /*
          *  A Grid Server and a Connect Server both have this option set, enable ConnectServer  */
      
         if trim(left(setting))="DMR" then do;

  	     /*put "NOTE: Setting ServerClass=ConnectServer";*/

 	     call symput('serverClass',"ConnectServer");
 	     found=1;
         
             end;
      
         end;
         
      else if optname="LOG" then do;
             /* Look at the AUTOEXEC to determine a new setting 
                value to determine the server type.             */
              setting=getoption("AUTOEXEC");
      
	      if index(setting,"OLAPServer")>0 then do;

		 /*put "NOTE: Setting ServerClass=OLAPServer";*/

		 call symput('serverClass',"OLAPServer");
		 found=1;

	      end;

	      else if index(setting,"StoredProcessServer")>0 then do;

		 /*put "NOTE: Setting ServerClass=StoredProcessServer";*/

		 call symput('serverClass',"StoredProcessServer");
		 found=1;

	      end;
	      
	      else if index(setting,"PooledWorkspaceServer")>0 then do;
	      
	      	 /*put "NOTE: Setting ServerClass=PooledWorkspaceServer";*/
	      
	      	 call symput('serverClass',"PooledWorkspaceServer");
	      	 found=1;
	      
	      end;

	      else if index(setting,"BatchServer")>0 then do;

		 /*put "NOTE: Setting ServerClass=BatchServer";*/

		 call symput('serverClass',"BatchServer");
		 found=1;

	      end;

	      else if index(setting,"ShareServer")>0 then do;

		 /*put "NOTE: Setting ServerClass=ShareServer";*/

		 call symput('serverClass',"ShareServer");
		 found=1;

	      end;

	      else if index(setting,"MetadataServer")>0 then do;

		 /*put "NOTE: Setting ServerClass=MetadataServer";*/

		 call symput('serverClass',"MetadataServer");
		 found=1;

	      end;
      
	end;   
	else if (optname="OBJECTSERVER") then do;
	
	     /*
	      *  Note that many of the servers will have this value set.  Thus, we won't mark it found here so that we
	      *  will process the other options (which may override this setting to a workspace server).
	      *  If no other checks turn out to be true, this will still be set at the end of the data step and it will
	      *  default to a workspace server.
	      */

             call symput('serverClass',"WorkspaceServer");
	
	     end;
	
	/*
	 *  If we found the info, stop.
	 */
	 
	if found=1 then stop;
	
   run;

     
    %end;

/*%put NOTE: serverClass=&serverClass;*/

/*
 *  If we have a current ServerClass value, then continue setting up the rest of ARM
 *  If we don't, then skip the ARM set up.
 */
 
%if "&serverClass" ne "" %then %do;

	/*
	 *  Create the ARM Log name.
	 *  Assume that the combation of ServerClass/Userid/CurrentTime will make a unique name.
	 */

	data _null_;

	   call symput('currentTime',putn(datetime(),'datetime.'));

	run;

	%global armlog;

	%let armlog=&serverClass./PerfLogs/arm_&sysuserid._%sysfunc(translate(&currentTime.,"x",":"))_&sysjobid..log;

	/*
	 *  Set the arm options based on the type of server being invoked
	 *
	 *  Note: we could have set the armloc option outside of any given server type.  However, this would force an
	 *  armlog on even if no arm options would be turned on for that specific server type.  Thus, we have duplicated
	 *  the armloc option line into each of the appropriate servers, and this allows for it to be completely turned off
	 *  (or controlled through another mechanism) by server type.
	 */

	/* 
	 *   Since the default for WorkspaceServer and Stored Process Server is the same as the general default, we could just
	 *   let them fall into the "else" clause at the bottom, but they seem important enough to be more explicit.
	 */

	%if "&serverClass."="WorkspaceServer" %then %do;

            %log4sas();
            %log4sas_logger(Perf.ARM,"level=info");
	    options armsubsys=(arm_dsio openclose, arm_proc);

	    %end;

	%else %if "&serverClass"="StoredProcessServer" %then %do;

	    /*
	     *  By default, we are just going to do individual stored process ARM instrumentation (by modifying the stpxxx macros).
	     *  However, if we want to see the procs and tables used by the stp server, which may be
	     *  interesting from an overal usage perspective, uncomment the following line.
	     */

	    /**options armsubsys=(arm_dsio openclose, arm_proc);**/

	    %end;
	    
	%else %if "&serverClass"="PooledWorkspaceServer" %then %do;
	
	    /**options armsubsys=(arm_dsio openclose, arm_proc);**/
	
	    %end;

	%else %if "&serverClass"="OLAPServer" %then %do;

	    /**options armsubsys=(arm_olap_session olap_session mdx_query);**/

	    %end;

	%else %if "&serverClass"="MetadataServer" %then %do;

	    /*  No ARM on by default for Metadata Server */

	    %end;

	%else %do;

	    /*
	     *  This should catch batch sessions, connect sessions, share, etc.
	     *
	     */

            /*options armloc="&armlog.";*/
            %log4sas();
            %log4sas_logger(Perf.ARM,"level=info");
	    options armsubsys=(arm_dsio openclose, arm_proc);

	    %end;

	%end;

%mend;
