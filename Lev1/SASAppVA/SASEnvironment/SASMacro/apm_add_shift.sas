/**********************************************************************************/
/*                                                                                */
/* Copyright (c) 2013, SAS Institute Inc., Cary, NC, USA, All Rights Reserved     */
/*                                                                                */
/**********************************************************************************/
%macro apm_add_shift(data_set=artifact.artifactusagedetails);

%let weekend1=Saturday;
%let weekend2=Sunday;

proc format;
  value day_name 1='Sunday'
                 2='Monday'
                 3='Tuesday'
                 4='Wednesday'
                 5='Thursday'
                 6='Friday'
                 7='Saturday';
run;

data shiftmap (drop=day_name weekend:);
  length shift_num $1 shift_text $9 weekend1 weekend2 $9;
  retain eexcl 'y' weekend1 "&weekend1." weekend2 "&weekend2.";
  do dow=1 to 7;
    day_name=put(dow,day_name.);
    if (day_name ne weekend1) and
       (day_name ne weekend2) then do; /* weekdays */
      shift_num  ="2";
      shift_text ="OFFHOUR";
      shift_start="00:00"t;
      shift_end  ="09:00"t;
      output;

      shift_num  ="1";
      shift_text ="PRIMETIME";
      shift_start="09:00"t;
      shift_end  ="17:00"t;
      output;

      shift_num  ="2";
      shift_text ="OFFHOUR";
      shift_start="17:00"t;
      shift_end  ="24:00"t;
      output;
    end;     /* weekdays */
    else do; /* weekends */
      shift_num  ="3";
      shift_text ="WEEKEND";
      shift_start="00:00"t;
      shift_end  ="24:00"t;
      output;
    end; /* weekends */
  end;   /* dow loop */
run;

data cntlin (drop=dow shift_start shift_end);
  retain fmtname "shift" fmtname2 "shifttxt" fmttype "c";
  set shiftmap end=lastrec;
  start=dow+(shift_start/100000);
  end=dow+(shift_end/100000);
  output;
  if lastrec then do; /* output an OTHER record */
    hlo="O";
    shift_num="X";
    shift_text="UNDEFINED";
    output;
  end; /* output an OTHER record */
run;

proc format library=work cntlin=cntlin(rename=(shift_num=label));
run;

proc format library=work cntlin=cntlin(drop=fmtname
                                       rename=(fmtname2=fmtname
                                               shift_text=label));
run;

data &data_set. (drop=shift_val);
  set &data_set.;  
  localtime=datetime+&logGMT.;
  shift_val=weekday(datepart(localtime))+((timepart(localtime))/100000);
  shift=put(shift_val,shift.);
  shifttxt=put(shift_val,shifttxt.);
run;

%mend;