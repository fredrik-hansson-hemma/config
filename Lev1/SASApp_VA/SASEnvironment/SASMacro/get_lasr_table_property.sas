

%macro get_lasr_table_property(	Libname=,
								table=,
								property=/*	MemType (Member Type)
											NROWS (Number of Rows)
											NCOLS (Number of Columns)
											TAG (Server Tag)
											CEI (Data Encoding)
											OWNER (Owner)
											MDATE NLDATMS27. (Last Modified) */,
								keep_work_table=NO
								);

	ods output Members=work.lasr_tabeller;
		proc datasets library=&Libname memtype=data;
		run; quit;
	ods output close;

	%local format;
	%if &property=MDATE %then %do;
		* Tar bort formatet f�r MDATE eftersom det d� blir l�ttare att anv�nda resultatet i j�mf�relser.	;
		%let format=format=best32.;
		%put NOTE: =====================================================================================;
		%put NOTE: &property �r en datetime-tidsst�mpel. Den beh�ver formatteras f�r att bli l�sbar.	;
		%put NOTE: =====================================================================================;
	%end;

	* H�mta timestamp f�r den aktuella tabellen, Lagra svaret i ut-macrovariabeln	;
	%global &property;
	proc SQL noprint;
		select &property &format into :&property
		from work.lasr_tabeller
		where upcase(name)=upcase("&table");

	%if &keep_work_table=NO %then %do;
		drop table work.lasr_tabeller;
	%end;

	quit;

	%put Resultatet (&&&property) �r sparat i den globala macrovariabeln "&property";
%mend get_lasr_table_property;


/******************** F�r provk�rning **************************

LIBNAME VALIBLA SASIOLA  TAG=HPS  PORT=10011 HOST="bst-apx-20.lul.se"  SIGNER="https://bst-apx-20.lul.se:8343/SASLASRAuthorization" ;


options nomprint;
%get_lasr_table_property(	Libname=VALIBLA,
							table=PRODUKTION_LE_RADIOLOGI,
							property=MDATE,
							keep_work_table=YES)

%put Senast modifierad den %sysfunc(datepart(&MDATE), yymmdd10.);

/****************************************************************/