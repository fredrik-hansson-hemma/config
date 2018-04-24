/* The AUDITout.audit_visualanalytics SAS data set is referred to as "the audit table" in comments below. */

/* Create the interval in seconds as a macro variable that will be used to create the refresh date */
/* Audit record timestamps are in GMT.  Update the clients offset to GMT. */
data _null_;
   format auditinterval $10.;
   format gmtoffset     $5.;
   
   /* 15 minutes = 900 seconds     */
   /* 1  day     = 86400 seconds   */      
   /* 30 days    = 2592000 seconds */
   /* 366 days   = 31622400 seconds*/
   auditinterval = 31622400;
   
   /* GMT offset in seconds */
   gmtoffset     = 0;
   
   call symput ('gmtoffset',     gmtoffset);
   call symput ('auditinterval', auditinterval);
   run;
   
   
/* Create the libref that is the location of the audit table. */   
libname AUDITout '/opt/sas/config/Lev1/AppData/SASVisualAnalytics/VisualAnalyticsAdministrator/AutoLoad/EVDMLA';

/* Edits below this line are not necessary. */

/* Create the refresh interval as a macro variable that is used as the WHERE clause that will truncate or refresh the audit table. */
data _null_;
 
   /* Start with today, and go back the given auditinterval seconds to get the refresh date. */
   today = round (datetime (), 1) + &gmtoffset;
   refreshinterval = today - &auditinterval;
      
   /* Create the refresh interval as a macro variable for the WHERE clause. */   
   call symput ('refreshinterval', refreshinterval);
   run;

/* Truncate, or refresh, the audit table. */ 
data AUDITout.audit_visualanalytics;
   set AUDITout.audit_visualanalytics
     (where = (timestamp_dttm > &refreshinterval));
   run;
