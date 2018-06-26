/* 
 * autoexec_usermods.sas
 *
 *    This autoexec file extends autoexec.sas.  Place your site-specific include 
 *    statements in this file.  
 *
 *    Do NOT modify the autoexec.sas file.  
 *    
 */
LIBNAME LOG BASE "/SASWORK/LUL/LOG";
LIBNAME LULDWT SQLSVR  Datasrc=LULDW  SCHEMA=va  USER=sas  PASSWORD="{SAS002}AC7F81411895620249107D4E585F239033811450" ;
/* OBS! LULDW pekar också på DW-test! Egentligen borde LULDWT tas bort, men det verkar vara så mycket som bygger på det libnamet i testmiljön :-(       */
LIBNAME LULDW META library="LULDW" metaout=data;

LIBNAME MDS SQLSVR  PRESERVE_COL_NAMES=YES  READ_LOCK_TYPE=NOLOCK  Datasrc=MDS  SCHEMA=mdm  USER=SAS_Prod_fetch  PASSWORD="{SAS002}64F4120B242E176A4E2A18DC1D5B8C2D112C83403A86BC82185EA193" ;

LIBNAME CI SQLSVR  Datasrc=CI  SCHEMA=sas  USER=SASuser  PASSWORD="{SAS002}D5A637533C6B67F53704EDD41A1D2C5C301551034643E140331BDB6600E420812E813CF119A85CC3" ;

* Pekar på Visual Analytics Acceptans LASR ;
LIBNAME VALASR SASIOLA  TAG=HPS  PORT=10011 HOST="bst-apx-20.lul.se"  SIGNER="https://bst-apx-20.lul.se:8343/SASLASRAuthorization" ;
* Utveckling ;
LIBNAME VAUTVLA SASIOLA  TAG=hpsutv  PORT=10013 HOST="bst-apx-20.lul.se"  SIGNER="https://bst-apx-20.lul.se:8343/SASLASRAuthorization" ;

