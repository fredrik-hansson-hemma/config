/******************************************************************************************/
/* If the dataset is empty, then something went wrong with the extract.  Cancel execution */
/* with the SYSINFO macro variable set to 3.                                              */
/******************************************************************************************/

proc sql noprint;
   select count(*) into :ldapgrps_nobs from adExt.ldapgrps;
quit;

data _null_;
   if &ldapgrps_nobs eq 0 then do;
      put "ERROR: Group extraction failed. The dataset adExt.ldapgrps contains no observations.";
      put "ERROR: Cancelling execution of submitted statements.";
      put "ERROR: Verify these values are correct: ADServer, ADPort, ADGrpBaseDN, keyidvar, displayName";
      put "ERROR: Try re-run the code with this line commented";
      put "ERROR:     filter=""(&(cn=&GROUP_FILTER.)(objectCategory=group)(objectClass=group))"" ;; ";
      abort cancel 3;
   end;
run;

* Kontrollerar att fimObjects inneh�ller rader.;
proc sql noprint;
   select count(*) into :fimobjects_nobs from LULDW.fimobjects;
quit;

data _null_;
   if &fimobjects_nobs eq 0 then do;
      put "ERROR: The dataset LULDW.fimobjects contains no observations.";
      put "ERROR: Cancelling execution of submitted statements.";
      abort cancel 3;
   end;
run;
* Slut: Kontrollerar att fimObjects inneh�ller rader.;

/**********************************************************************/
/* Sort the list of groups extracted from Active Directory by the     */
/* distinguishedName attribute which represents the actual Group      */
/* name. This is necessary so the following  datastep can do BY       */
/* processing on the Group list in order to detect the next unique    */
/* Group name and output it to &idgrptbl.                             */
/**********************************************************************/

*proc sql;
*  drop index distinguishedName from adExt.ldapgrps;
*quit;

proc sort data=adExt.ldapgrps;
     by distinguishedName;
run;  
 
proc datasets library=adExt memtype=data nowarn nolist;    /* Create Index */
     modify ldapgrps;                         /* for speedy retrieval */
     index create distinguishedName;
run;                                                                                         
 
/******************************************************************************/
/* The following datastep creates the normalized tables for groups and group  */
/* membership from the adExt.ldapusers extracted above.             */
/******************************************************************************/

* Start: Anpassning LUL;
* Skapar format med alla superanv�ndare;
data superanv;
  set adext.ldapgrps (where=(upcase(name) = "LUL-SYSTEM-SAS-SUPERANV�NDARE"));
	start = member;
	end = member;
	label= "J";
	type = "C";
	fmtname="superanv";
run;

/*
proc sql;
 create table superanv_old as
 	select 
	memkeyid as start,
	memkeyid as end,
	"J" as label,
	"C" as type,
	"superanv" as fmtname
	from 
	metaext.idgrps as idgrps,
	metaext.grpmems as grpmems
	where idgrps.name = "Superanv�ndare"
	and idgrps.keyid = grpmems.grpkeyid
	and length(grpmems.memkeyid) in (6,8);
quit;
*/

proc format lib=work.formats cntlin= superanv;
run;


* Slut: Anpassning LUL;

data &idgrptbla &idgrpmemstbla;
     %defineidgrpcols;       
     %defineidgrpmemscols; 

     set adExt.ldapgrps;
     by distinguishedName;     

		 * Start: Anpassning LUL.;
     * Gruppnamnen i AD slutar p� -SAS, vi tar bort -SAS ur namnet innan vi laddar till metadata.; 
		 	if upcase(substr(compress(reverse(name)), 1, 4)) = 'SAS-' then do;
					org_group = 1; * flagga f�r att gruppen �r en organisationsgrupp;
				  tmp_name = substr(compress(reverse(name)), 5);
					name = compress(reverse(tmp_name));
					drop tmp_name;
			end;
		
			* Slut: Anpassning LUL.;

     
     if first.distinguishedName then do;
        keyid = distinguishedName;
     
       
        grptype="" ;
        output &idgrptbl;
		

     end;

    

     grpkeyid=distinguishedName;
     memkeyid=member;	
     
     * memkeyid=saMAccountName;

     output &idgrpmemstbl;

		 * Start: Anpassning LUL;
		 * Om det �r en organisationsgrupp skapas det en admingrupp f�r den. Admingruppen har prefix -W (Write). Medlemmar �r superanv�ndare;

		 if org_group = 1 and first.distinguishedName then do;
		 	  name = compress(name !!"-W");
				distinguishedName = name;
        keyid = name;
     
       
        grptype="" ;
        output &idgrptbl;
		
     end;
		
		 * Om medlemmen �r en grupp eller en superanv�ndare ska den med i admingruppen;
		 if org_group = 1 and (index(member, "-SAS") or put(member, $superanv.) = "J") then do;
		 	 
    		  
	
		 	if put(member, $superanv.) = "J" then do; 
				name=tranwrd(name, '-W', '');
				grpkeyid=compress(name !!"-W"); 
				memkeyid=member;
			end;
    	 * om medlemmen �r en grupp, tar bort '-SAS' fr�n namnet g�r sedan om den till en admingrupp genom att s�tta suffixet "-W";
      if index(member, "-SAS") then do;
			   tmp_member = substr(compress(reverse(member)), 5);
				 member = compress(reverse(tmp_member));
				 drop tmp_member;
         memkeyid=compress(member !!"-W");
		 		 name=tranwrd(name, '-W', '');
				 grpkeyid=compress(name !!"-W"); 
       end; 

     output &idgrpmemstbl;	
		 end;

		drop org_group;
		 * Slut: Anpassning LUL;
run;

/* Start: Anpassning LUL. Beh�righetsstrukturen v�nds. */
/* AD-har en uppifr�n-och-ner struktur. Alla tillh�r LUL-gruppen, grupper i LUL
har h�gre beh�righet. SAS har nerifr�n-och-upp struktur, dvs. LUL-gruppen �r h�gsta beh�righeten. I f�ljande steg
v�nds beh�righetsstrukturen f�r SAS-grupper i AD. Member-of blir member och member blir member-of.
*/


proc sql;
  create table grpmems as
  select grpmems.grpkeyid, grpmems.memkeyid,  idgrps.keyid as memkeyid_ou
  from adext.grpmems as grpmems left join adext.idgrps as idgrps
  on compress(tranwrd(grpmems.memkeyid,'-SAS','')) = idgrps.name
  ;
quit;

data adext.grpmems (keep=grpkeyid memkeyid);
	set grpmems;
  
	* Str�nghantering. Halva1: framf�r kommatecken;
  halva1 = scan(grpkeyid, 1, ',');
	halva2 = tranwrd(grpkeyid, left(halva1), '');
	*if index(memkeyid, '-PV-') then pvgrupp=1;
	*if pvgrupp then do;
	    * Om det �r en SAS-grupp eller en -W grupp;
			if index(memkeyid_ou, "-SAS") or (substr(left(reverse(memkeyid)),1,2)= "W-") then do;
			   * Tar bort 'CN=' d�r det finns;
				 if index(halva1,'CN=') then tmp_grpkeyid = substr(halva1, 4);
				 else if not index(halva1,'CN=') then tmp_grpkeyid = halva1;
				 /*
				 if index(tmp_grpkeyid, "-SAS") then do;
			     tmp_member = substr(compress(reverse(tmp_grpkeyid)), 5);
				   tmp_grpkeyid = compress(reverse(tmp_member));
		     end; */

	       grpkeyid = memkeyid_ou;
				 memkeyid = tmp_grpkeyid;
			   
				 if index(tmp_grpkeyid, "-SAS") then do;
			     tmp_member = substr(left(reverse(tmp_grpkeyid)), 5);
				   tmp_grpkeyid = left(reverse(tmp_member));
		     end; 
			end;
	* end; * end: if pvgrupp;
 
run;

/* Slut: Anpassning LUL. Beh�righetsstrukturen v�nds. */


/* Get user details using the members extracted above */
data adExt.ldapusers                                                               
     (keep= displayName streetAddress cn company mail employeeID facsimileTelephoneNumber 
            distinguishedName l mobile otherTelephone physicalDeliveryOfficeName postalCode name 
            sAMAccountName st telephoneNumber co title whenChanged whenCreated);

	length entryname $200 attrName $100 value $600 filter $200
	    displayName $256 streetAddress $100 cn $40 company $50 mail $80 
	    employeeID $30 facsimileTelephoneNumber $50 distinguishedName $200
	    l $50 mobile $50 otherTelephone $50 physicalDeliveryOfficeName $50
	    postalCode $20 name $60 sAMAccountName $20 st $20 telephoneNumber $50
	    co $50 /*title $50*/ whenChanged $30 whenCreated $30;

	set LULDW.fimobjects (where=(username not is missing)keep= firstname middlename lastname title fullpath email username enddate);
	if middlename ne "" then DisplayName= trim(FirstName)||' '||trim(MiddleName)||' '||trim(LastName);
	else if middlename eq "" then DisplayName= trim(FirstName)||' '||trim(LastName);
  * Ta bara med de med g�llande anst�llning;
	* date = datepart(enddate);
	* L�gger till en dag p� enddate f�r att �verbrygga ev glapp mellan anst�llningsperioder i AD.;
	* if (date = .) or (date+1 ge today()); 
	sAMAccountName = UserName;
	mail=email;
	name =UserName;
	company=fullpath;
 	employeeID=UserName;
run;

/******************************************************************************************/
/* If the dataset is empty, then something went wrong with the extract.  Cancel execution */
/* with the SYSINFO macro variable set to 2.                                              */
/******************************************************************************************/
proc sql noprint;
   select count(*) into :ldapusers_nobs from adExt.ldapusers;
quit;
   
data _null_;
   if &ldapusers_nobs eq 0 then do;
      put "ERROR: User extraction failed.  The dataset adExt.ldapusers contains no observations.";
      put "ERROR: Cancelling execution of submitted statements.";
      abort cancel 2;
   end;
run;

/**********************************************************************************/
/* If we were using the anything other than the DN as the keyid for persons, then */
/* we need to re-code the person group memberkeys from DN to the proper keyid     */
/* so that they match.                                                            */
/**********************************************************************************/
%transmemkeyid;

/******************************************************************************************/
/* The following datastep creates the normalized tables for person, location,             */
/* phone, email, and login from the adExt.ldapusers extracted above.            */
/******************************************************************************************/


data &persontbla                      /* Macros to define Normalized Tables from %mduimpc */
     &locationtbla
     &phonetbla
     &emailtbla
     &logintbla 
      ;
     %definepersoncols;        /* Macros to define Normalized Table Columns from %mduimpc */
     %definelocationcols;
     %definephonecols;
     %defineemailcols;
     %definelogincols; 

     set adExt.ldapusers;
                                            
     keyid = &keyidvar;
  
     description=company;  
     output &persontbl;
                             
     if mail NE "" then do;
        emailAddr = mail;
        emailType = "Office";
        output &emailtbl;
     end; 
                     
     if UserName NE "" then do; 
      
        /* setup login values */ 
        /* we need to prefix the login user id with the domain id */
       
        if "&WindowsDomain" = "" then
           userid = UserName ;
        else
           userid = "&WindowsDomain\" || UserName ;  
      
        password ="";
        authdomkeyid = 'domkey' || compress(upcase("&MetadataAuthDomain"));

        output &logintbl;
     end;                                                                                        
run;                                                          


/************************************************************************/
/* The following datastep creates the normalized table for the          */ 
/* AuthenticationDomain specified in the &MetadataAuthDomain near the   */
/* beginning of this SAS code.  This value is also used to create the   */
/* foreign key variable "authdomkeyid" for the logins table in the next */ 
/* datastep, forming the relation between the authdomtbl and logintbl.  */
/************************************************************************/

data &authdomtbl;
     %defineauthdomcols;  /* Macros to define Table authdomain from %mduimpc */
     authDomName="&MetadataAuthDomain";
     keyid='domkey' || compress(upcase("&MetadataAuthDomain"));
	 output;
	 authDomName="web";
     keyid='domkeyWEB';
		 output;
run;
 

                                                     
