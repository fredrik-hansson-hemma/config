/**********************************************************************************/
/*                                                                                */
/* Copyright (c) 2013, SAS Institute Inc., Cary, NC, USA, All Rights Reserved     */
/*                                                                                */
/**********************************************************************************/

%macro apm_status_init;
  data _null_;
    dt=datetime();                 
    d=datepart(dt);                
    t=timepart(dt);        
    file "&sasusagedir./apm_status";
    put 'lastStartTime=' d yymmdd10. 'T' t e8601lz.;  
  run;  
%mend;