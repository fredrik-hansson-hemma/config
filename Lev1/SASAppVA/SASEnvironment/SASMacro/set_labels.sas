/************************************
* Macro: SET_LABELS
* 
* Läser kolumnbeskrivningar från tabell ViewDefinitions
* i datalagret. Uppdaterar metadata om VA-tabellen.
*
* VATABLE: Tabell som har laddats.
* ex på anrop: 
* %set_labels(VATABLE=EKONOMI) (sätter rubriker på tabell Ekonomi.)
* %set_labels(VATABLE=) (sätter rubriker på alla tabeller på LASR servern.)
* %set_labels(VATABLE=EKONOMI, TABLEDESCRIPTION=Ekonomin) 
* (sätter rubriker samt beskrivning på tabell Ekonomi.)  
************************************/

%macro set_labels(vatable=, tabledescription=NULL);

%put ENTER: set_labels;
%if "VATABLE" = "" %then %do;
  %put Alla tabeller i LASR-minnet kommer att uppdatera kolumnrubriker.;
%end;
%if "VATABLE" ne "" %then %do;
  %put Tabell &vatable kommer att uppdatera kolumnrubriker.;
%end;

* DWLIB: Libref för datalager.; 
%let dwlib = %get_dwlib();
* VATABLE: Den tabell som ska uppdateras med nya kolumnbeskrivningar.;
%let vatable = %upcase(&vatable); 

* Hämtar alla tabeller som finns i LASR servern.;
proc sql noprint;
create table lasrtables as
select memname from dictionary.tables
where (upcase(libname) = "VALIBLA" or upcase(libname) = "VAUTVLA" or upcase(libname) = "VALASR") 

%if "&vatable" ne "" %then %do;
and compress(upcase(memname)) = "&vatable"
%end;
;
quit;

%let dsid = %sysfunc(open(lasrtables));
%do %while ((%sysfunc(fetch(&dsid))) = 0);

%let vatable=%upcase(%sysfunc(getvarc(&dsid,%sysfunc(varnum(&dsid,memname)))));
%put VATABLE= &vatable;


data meta_info;
	Length uri c_uri l_uri t_uri lib_uri sch_uri publicType $50
  TableID $20
	LibraryID $20
	DatabaseSchemaID $20
	Vy $40
	TableDesc $100
	SASTableName $50
	ColumnID $20
	ColumnName $50
	ColumnDesc $100
	SASColumnLength $5
	SASColumnType $1
	SASFormat $20
	SASInformat $20
	;
	Keep
	TableID
	LibraryID
	DatabaseSchemaID
	Vy
	TableDesc
	SASTableName
	ColumnID
	ColumnName
	ColumnDesc
	SASColumnLength
	SASColumnType
	SASFormat
	SASInformat

	;
	NOBJ=1;
	N=1;
do while(nobj >= 0);
*LibraryID='';DatabaseSchemaID='';
nobj=metadata_getnobj("omsobj:PhysicalTable?@Name='&vatable'",n,uri);
n=n+1;
index = metadata_getnasn(uri,"TablePackage",1,t_uri);
if nobj>0 and index>0 then do;
rc = metadata_getattr(uri, "ID", TableID);
rc = metadata_getattr(uri, "TableName", Vy);
rc = metadata_getattr(uri, "Desc", TableDesc);
rc = metadata_getattr(uri, "SASTableName", SASTableName);
rc = metadata_getattr(t_uri, "PublicType", PublicType);
if PublicType eq 'Library' then rc = metadata_getattr(t_uri, "ID", LibraryID);
else rc = metadata_getattr(t_uri, "ID", DatabaseSchemaID);
m=1;
mrc=1;
do while(mrc>0);
mrc = metadata_getnasn(uri,"Columns",m,c_uri);
rc = metadata_getattr(c_uri, "ID", ColumnID);
rc = metadata_getattr(c_uri, "Name", ColumnName);
rc = metadata_getattr(c_uri, "Desc", ColumnDesc);
rc = metadata_getattr(c_uri, "SASColumnLength", SASColumnLength);
rc = metadata_getattr(c_uri, "SASColumnType", SASColumnType);
rc = metadata_getattr(c_uri, "SASFormat", SASFormat);
rc = metadata_getattr(c_uri, "SASInformat", SASInformat);
m=m+1;
if mrc>0 then output;
end;
end;
end;
run;

data meta_info;
set meta_info;
columnname=upcase(columnname);
run;

proc sort data=meta_info;
	by ColumnName;
run;

*hämtar kolumndefinitionerna från look-up-tabell i datalagret;
data viewdef;
	set &dwlib..vw_viewlabels (keep=ColumnLabel columnname);
	columnname = upcase(columnname);
proc sort;
	by columnname;
run;

*mergar ihop båda dataseten på columnname, så att columnlabel läggs till på alla rader där columname finns i båda dataseten.
 ett Check-dataset skapas och dit sätts alla observationer som enligt viewdefinitions borde finnas i metadata, men som inte finns där;
data metainfo_new check;
	merge meta_info (in=a) viewdef (in=b);
	by columnname;
	if b and not a then output check;
	else output metainfo_new;
run;

*uppdaterar metadata med de kolumnetiketter (columnlabel) som hämtas från datalagret;
data _null_;
	set metainfo_new;
	if missing(columnlabel) then do;
	RC=METADATA_SETATTR("omsobj:Column?@Id='"||COLUMNID||"'","Desc",columndesc);
	end;
	else do;
	RC=METADATA_SETATTR("omsobj:Column?@Id='"||COLUMNID||"'","Desc",columnlabel);
	end;
run;


%end;
%let dsid = %sysfunc(close(&dsid));

%if "&VATABLE" ne "" and "&TABLEDESCRIPTION" ne "NULL" %then %do;
data _null_;
  set meta_info (obs=1);
  RC=METADATA_SETATTR("omsobj:PhysicalTable?@Name='&vatable'","Desc","&tabledescription");
run;
%end;

%put EXIT: set_labels;
%mend set_labels;

* Exempel på anrop.;
/*%set_labels(vatable=VARDDAG_TEST);*/

