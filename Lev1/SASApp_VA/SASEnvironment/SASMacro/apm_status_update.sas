/**********************************************************************************/
/*                                                                                */
/* Copyright (c) 2013, SAS Institute Inc., Cary, NC, USA, All Rights Reserved     */
/*                                                                                */
/**********************************************************************************/

%macro apm_status_update;
  data _null_;
    dt=datetime();                 
    d=datepart(dt);                
    t=timepart(dt);
    file "&sasusagedir./apm_status" mod;
    put 'lastEndTime=' d yymmdd10. 'T' t e8601lz.;                                           
    do dir='artifacts','archive','status';                 
      total=0;                                             
      dir_path="&sasusagedir."||'/Data/'||trim(dir);       
      rc=filename('dir',dir_path);                         
      if rc eq 0 then do;                                  
        did=dopen('dir');                                  
        if did gt 0 then do i=1 to dnum(did);              
          name=dread(did,i);                               
          if index(name,'sas7bdat') then do;               
            rc=filename('file',trim(dir_path)||'/'||name); 
            fid=fopen('file');                             
            infonum=foptnum(fid);                          
            do j=1 to infonum;                             
              infoname=foptname(fid,j);                    
              kbytes=0;                                    
              if infoname eq 'File Size (bytes)' then do;  
                kbytes=input(finfo(fid,infoname),32.)/1024;
                total+kbytes;                              
              end;                                         
            end;                                           
            close=fclose(fid);                             
          end;                                             
        end;                                               
        put 'librarySize.' dir +(-1) '=' total;      
        rc=dclose(did);                                    
      end;                                                 
      rc=filename('data');                                 
    end;
    errorCount=(sysget('ReturnCode') eq '2');
    _error_=0;
    put errorCount=;   
  run;  
%mend;