/* Specify target metadata server connection details */
* Lösenordet för sasadm@saspw är satt i programmet 0_passwords.sas	;

* Hämtar namnet på metadataservern från properties-filen (eftersom det beror på vilken maskin vi kör på)	;
%get_property(property=metaserver)
options
	metaserver="&metaserver"
	metaport=8561
	metaprotocol='bridge'
	metauser='sasadm@saspw'
	metapass=&metapass
	metarepository='Foundation'
	metaconnect='NONE'
	;


/* Allocation of FimObjects; */
%let dwlib = luldw; 

/*Specify the directory for the extracted AD data (master tables).  */
libname adExt "&ADSyncStaging/ADExtract";

/* Specify the directory for the extracted metadata (target tables).*/
libname metaExt "&ADSyncStaging/MetaExtract";

/* Specify the directory for the comparison output (change tables).*/
libname metaUpd "&ADSyncStaging/MetaUpdate";

/* Active directory server and port */
%*let ADServer="LUL-DC-06.LUL-NET.AD.LUL.SE";
%let ADServer="LUL-NET.AD.LUL.SE";

%let ADPort=389;

/* Path where in Active Directory to start searching (applies to group and users) */
*%let ADGrpBaseDN = "OU=Groups,OU=InfoMate,OU=Sodertalje,OU=SE,DC=global,DC=scd,DC=scania,DC=com"; 
*%let ADGrpBaseDN = "OU=LUL,DC=lul-net,DC=ad,DC=lul,DC=se"; 
%let ADGrpBaseDN ="OU=LUL,DC=lul-net,DC=ad,DC=lul,DC=se";

/* Define group filters
 * - work with '*', eg, "SAS*"
 * - support up to 5 filters, eg, GROUP_FILTER=, GROUP_FILTER2=, ..., GROUP_FILTER5=, etc */

%let GROUP_FILTER=*SAS;
%let GROUP_FILTER2=LUL-SYSTEM-SAS-*;

/* Användarnamn och lösenord för att ansluta till Active Directory server och extrahera information är satta i programmet 0_passwords.sas */


/****************************************************************************/
/* Set the name of the windows domain that should be prepended with a '\'   */
/* to each login created by this extraction.                                */
/****************************************************************************/
%let WindowsDomain=LUL-NET;

/****************************************************************************/
/* Define the tag that will be included in the Context attribute of         */
/* ExternalIdentity objects associated with the information loaded by this  */
/* application.  This tag will make it easier to determine where information*/
/* originated from when synchronization tools become available.             */
/* Note, the value of this macro should not be quoted.                      */
/****************************************************************************/
%let ADExtIDTag = AD;

/****************************************************************************/
/* Choose the value that will be used as the keyid for Person information.  */
/* Choices are the DistinguishedName of the User entry or the employeeid.   */
/* For groups, the DistinguishedName will be used.                          */
/*                                                                          */
/* %let keyidvar=employeeID;                                                */
/* %let keyidvar=distinguishedName;                                         */
/* %let keyidvar=saMAccountName;                                         */
/****************************************************************************/
%let keyidvar=saMAccountName;

/****************************************************************************/
/* Set the name of the AuthenticationDomain in the metadata to which logins */
/* created by the process should be associated.  Note, this name is not     */
/* required to be the same name as the windows domain. Logins from multiple */
/* windows domains can participate in the same metadata AuthenticationDomain*/
/* if the windows domains trust each other.                                 */
/****************************************************************************/
%let MetadataAuthDomain=DefaultAuth;
/*** Report ***/
%LET TODAY=%SYSFUNC(PUTN(%SYSFUNC(TODAY()), date9.));
filename report "&ADSyncStaging./Logs/report_&TODAY..txt";
