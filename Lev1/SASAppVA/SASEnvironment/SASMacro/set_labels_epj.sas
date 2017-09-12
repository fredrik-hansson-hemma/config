/************************************
* Macro: SET_LABELS_EPJ
* 
* Läser kolumnbeskrivningar från tabell vw_ViewLabels.
* Uppdaterar rubriker för VA-tabellerna i EPJ LASR.
*
* VATABLE: Tabell som har laddats.
* ex på anrop: 
* %set_labels_EPJ(LIB=CI,VATABLE=EKONOMI) (sätter rubriker på tabell Ekonomi. Hämtar rubriker från CI.vw_ViewLabels)
* %set_labels_EPJ(LIB=CI,VATABLE=) (sätter rubriker på alla tabeller på LASR servern. Hämtar rubriker från CI.vw_ViewLabels)
* %set_labels_EPJ(LIB=CI,VATABLE=EKONOMI,TABLEDESCRIPTION=Ekonomin. Hämtar rubriker från CI.vw_ViewLabels.) 
* (sätter rubriker samt tabellbeskrivning på på tabell Ekonomi.) 
************************************/

%macro set_labels_epj(lib=, vatable=, tabledescription=NULL);

%put ENTER: set_labels_epj;
%if "VATABLE" = "" %then %do;
  %put Alla tabeller i LASR-minnet kommer att uppdatera kolumnrubriker.;
%end;
%if "VATABLE" ne "" %then %do;
  %put Tabell &vatable kommer att uppdatera kolumnrubriker.;
%end;

* VATABLE: Den tabell som ska uppdateras med nya kolumnbeskrivningar.;
%let vatable = %upcase(&vatable); 

LIBNAME EPJLA SASIOLA  TAG=epj  PORT=10015 SIGNER="https://rapport.lul.se:443/SASLASRAuthorization"  HOST="bs-ap-04.lul.se" ;
%if %sysfunc(upcase(&lib)) = CI %then %do;
LIBNAME CI SQLSVR  Datasrc=CI  SCHEMA=sas  USER=SASuser  PASSWORD="{SAS002}D5A637533C6B67F53704EDD41A1D2C5C301551034643E140331BDB6600E420812E813CF119A85CC3" ;
%end;
%if %sysfunc(upcase(&lib)) = CYTODOSP %then %do;
LIBNAME CYTODOSP SQLSVR  PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  READ_LOCK_TYPE=NOLOCK  Datasrc=CYTODOS_PROD  SCHEMA=Sas  USER=SASUSER_CYTO_PROD  PASSWORD="{SAS002}CB49D32854D83E3701B13A0F16512A602AA061DE1683A6313F77F6B0" ;
%end;
%if %sysfunc(upcase(&lib)) = ORBITA01 %then %do;
LIBNAME ORBITA01 SQLSVR  PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  READ_LOCK_TYPE=NOLOCK  Datasrc=ORBITA01  SCHEMA=LUL_VA  USER=TestLULVAuser  PASSWORD="{SAS002}9AFC164B19CD914F39D62074403465073C4F8FA1" ;
%end;
%if %sysfunc(upcase(&lib)) = ORBITAP %then %do;
LIBNAME ORBITAP SQLSVR  PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  READ_LOCK_TYPE=NOLOCK  Datasrc=ORBITAP  SCHEMA=LUL_VA  USER=ProdLULVAuser  PASSWORD="{SAS002}23AA9C284EE996642263D3111544288150129218" ;
%end;
%if %sysfunc(upcase(&lib)) = ORBITS %then %do;
LIBNAME ORBITS SQLSVR  PRESERVE_COL_NAMES=YES  PRESERVE_TAB_NAMES=YES  READ_LOCK_TYPE=NOLOCK  Datasrc=ORBITS  SCHEMA=sas  USER=SASUSER_ORBITSTATISTIK  PASSWORD="{SAS002}A8D5DB383F15EE011E0873BA50F37667" ;
%end;

* Hämtar alla tabeller som finns i LASR servern.;
proc sql noprint;
create table lasrtables as
select memname from dictionary.tables
where upcase(libname) = "EPJLA" 

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
	ColumnName $128
	ColumnDesc $128
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
data viewdef (rename=(column_label=columnlabel column_name=columnname));
	set &lib..vw_ViewLabels (keep=Column_Label column_name);
	column_name=upcase(column_name);
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

%put EXIT: set_labels_epj;
%mend set_labels_epj;

* Exempel på anrop.;
%*set_labels_epj(VATABLE=VBV_Brannskada,TABLEDESCRIPTION=Test);

