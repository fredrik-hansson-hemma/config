/* 
 * autoexec_usermods.sas
 *
 *    This autoexec file extends autoexec.sas.  Place your site-specific include 
 *    statements in this file.  
 *
 *    Do NOT modify the autoexec.sas file.  
 *    
 */
LIBNAME EPJDATA META library="SASAppVA - EPJDATA" metaout=data;
LIBNAME LULDW META library="LULDW" metaout=data;
options validvarname=any validmemname=extend;
