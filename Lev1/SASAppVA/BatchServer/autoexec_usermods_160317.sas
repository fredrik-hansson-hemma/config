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
LIBNAME LULDW SQLSVR  Datasrc=LULDW  SCHEMA=va  USER=sasVA  PASSWORD="{SAS002}6DC8FE512E0DA8B60937A18B0A83601F416F94B329D1D979384EC89E5268A2B3";
* LASR-server;
LIBNAME VALASR SASIOLA  TAG=HPS  PORT=10010 HOST="bs-ap-04.lul.se" SIGNER="http://bs-ap-04.lul.se:7980/SASLASRAuthorization" ;
