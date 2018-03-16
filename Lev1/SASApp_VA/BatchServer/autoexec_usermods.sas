/* 
 * autoexec_usermods.sas
 *
 *    This autoexec file extends autoexec.sas.  Place your site-specific include 
 *    statements in this file.  
 *
 *    Do NOT modify the autoexec.sas file.  
 *    
 */
LIBNAME LOG BASE "/saswork/LUL/LOG";
LIBNAME LULDW SQLSVR  READ_LOCK_TYPE=NOLOCK  Datasrc=LULDW  SCHEMA=va  USER=SAS_Prod_fetch  PASSWORD="{SAS002}64F4120B242E176A4E2A18DC1D5B8C2D112C83403A86BC82185EA193" ;
LIBNAME MDS SQLSVR  PRESERVE_COL_NAMES=YES  READ_LOCK_TYPE=NOLOCK  Datasrc=MDS  SCHEMA=mdm  USER=SAS_Prod_fetch  PASSWORD="{SAS002}64F4120B242E176A4E2A18DC1D5B8C2D112C83403A86BC82185EA193" ;
* LASR-server;
LIBNAME VALASR SASIOLA  TAG=HPS  PORT=10011 HOST="bs-ap-20.lul.se" SIGNER="https://bs-ap-20.lul.se:443/SASLASRAuthorization" ;

options validvarname=any validmemname=extend;
