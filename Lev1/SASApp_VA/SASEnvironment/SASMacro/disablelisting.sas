

%macro disablelisting(mode);

	%put === Region uppsalas egen version av disablelisting-macrot	=== ;

	%if %upcase(&mode) = DISABLE or "&mode" = "" %then %do;
		%put Inaktiverar output.				;
		filename nulpath dummy; 
		proc printto print = nulpath; 
		run;
	%end;
	%else %if %upcase(&mode) = RESTORE %then %do;
		proc printto; 
		run;
		filename nulpath clear;
		%put NOTE: Återställde output och loggning.	;
	%end;
	%else %do;
		%put %STR(ER)ROR: Macrot "disablelisting" kan endast ta DISABLE eller RESTORE som inparametrar. ;
		%put %STR(ER)ROR: Du angav "&mode".;
	%end;
%mend;