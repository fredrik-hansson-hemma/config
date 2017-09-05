%macro ldapextrgroups;
 
       shandle=0;
       num=0;

       attrs="name description groupType distinguishedName " ||
             "sAMAccountName member whenChanged whenCreated" ||
             "displayName";

      
       /*****************************************************************/
       /* Call the SAS interface to search the LDAP directory.  Upon    */
       /* successful return, the shandle variable will contain a search */
       /* handle that identifies the list of entries returned in the    */
       /* search.  The num variable will contain the total number of    */
       /* result entries found during the search.                       */
       /*****************************************************************/
       call ldaps_search(handle,shandle,filter, attrs, num, rc);
       if rc NE 0 and rc NE 1327233 then do; /* 1327233 is a return code when no results are found */
          msg = sysmsg();
          put msg;
          put filter=;
		  		put rc=;
       end;

       do eIndex = 1 to num;
 
          numAttrs=0;
          entryname='';

          call ldaps_entry(shandle, eIndex, entryname, numAttrs, rc);
          if rc NE 0 then do;
             msg = sysmsg();
             put msg;
          end;

          /* initialize the entry variables */
          name=""; 
          description=""; 
          groupType=""; 
          distinguishedName="";
          sAMAccountName=""; 
          member=""; /* DN of the group members */
          whenChanged=""; 
          whenCreated="";
          displayname="";
          
          
          /***********************************************************************/
          /* for each attribute, retrieve name and values                        */
          /* initialize the member attribute index to 0.  It will get set in the */
          /* loop below and then used to retrieve group members after the group  */
          /* attributes are set.                                                 */
          /***********************************************************************/
          memberindex = 0; 
          
          if (numAttrs > 0) then do aIndex = 1 to numAttrs;
             
             attrName='';
             numValues=0;
             
             call ldaps_attrName(shandle, eIndex, aIndex, attrName, numValues, rc);
             if rc NE 0 then do;
                put aIndex=;
                msg = sysmsg();
                put msg;
             end;

             /********************************************************************/
             /* if the attrName is member, then lets remember the aIndex so that */
             /* we can loop thru all the members after the group attributes are  */
             /* retrieved.                                                       */
             /********************************************************************/
             if (attrName = 'member') then do;
                memberindex = aIndex;
						 end;
		
             else do;  /* get the 1st value of the attribute. */
                call ldaps_attrValue(shandle, eIndex, aIndex, 1, value, rc);
                if rc NE 0 then do;
                   msg = sysmsg();
                   put msg;
                end;
             end;

             /* extract the description - Description */
             if (attrName = 'description')  then 
                description=value;
             /* extract the name - RDN  (relative distinguished name)  */
             if (attrName = 'name')  then 
                name=value;
             /* extract the groupType - Group-Type   */
             if (attrName = 'groupType')  then  
                groupType=value;
             /* extract the distinguishedName - Obj-Dist-Name */
             if (attrName = 'distinguishedName')  then 
                 distinguishedName=value;
             /* **extract the sAMAccountName - SAM-Account-Name */
			
             if (attrName = 'sAMAccountName')  then 
                sAMAccountName=value;
   
             /* extract the member - Member for Group */
             if (attrName = 'member')  then do;
                /* extract all the members of the group */
                member=value; /* DN of the group members */
             end;
   
             /* extract the whenChanged - When-Changed */
             if (attrName = 'whenChanged')  then 
                whenChanged=value;
             /* extract the whenCreated - When-Created */
             if (attrName = 'whenCreated')  then 
                whenCreated=value;

             /* extract the displayname - displayName */
             if (attrName = 'displayName')  then 
                displayname=value;
                
          end;  * end: do aIndex = 1 to numAttrs;   
   
          /* ... Group defined with no members */
          if memberindex = 0 then do;			 	
             member="";
             output work.ldapgrps;  /* Write out Group Name Entry */
          end;

          /* ... when Group has members then retrieve each one */
          else do;
           
 /***************** START ********************/
/* retrieve entry indexed by integer entryIndex */
						groupfilter="(&(objectClass=*)(memberof="||trim(distinguishedname)||"))";
						put groupfilter=;
						grouphandle=0;
      			groupnum=0;

       			groupattrs="sAMAccountName";
			 
    				call ldaps_search(handle,grouphandle,groupfilter, groupattrs, groupnum, rc);
       			if rc NE 0 and rc NE 1327233 then do; /* 1327233 is a return code when no results are found */
          		msg = sysmsg();
          		put msg;
          		put groupfilter=;
		  				put rc=;
       			end;

       			do groupEntryIndex = 1 to groupnum;
 							* put groupEntryIndex=;
          		numAttrs=0;
          		entryname='';

          		call ldaps_entry(grouphandle, groupEntryIndex, entryname, numAttrs, rc);
          		if rc NE 0 then do;
             		msg = sysmsg();
             		put msg;
          		end;

          		/* initialize the entry variables */
          		member="";
          
          /***********************************************************************/
          /* for each attribute, retrieve name and values                        */
          /* initialize the member attribute index to 0.  It will get set in the */
          /* loop below and then used to retrieve group members after the group  */
          /* attributes are set.                                                 */
          /***********************************************************************/
          
          	if (numAttrs > 0) then do groupAttrIndex = 1 to numAttrs;
             
             attrName='';
             numValues=0;
             
             call ldaps_attrName(grouphandle, groupEntryIndex, groupAttrIndex, attrName, numValues, rc);
             if rc NE 0 then do;
                put groupAttrIndex=;
                msg = sysmsg();
                put msg;
             end;
 
             /* get the 1st value of the attribute. */
             call ldaps_attrValue(grouphandle, groupEntryIndex, groupAttrIndex, 1, value, rc);
             if rc NE 0 then do;
               msg = sysmsg();
               put msg;
             end;
           
             if (attrName = 'sAMAccountName')  then 
                member=value;
        
          	end;  /* end: do groupAttrIndex = 1 to numAttrs */    
  
/***************** SLUT **********************/
 	
            output work.ldapgrps;  /* Write out Group Member Entry */
  
       		end;  /* end: do groupEntryIndex = 1 to groupnum */

					/* free search resources */
       		if grouphandle NE 0 then do;
          call ldaps_free(grouphandle,rc);
          if rc NE 0 then do;
             msg = sysmsg();
             put msg;
          end; 
       end;
			
			 end; * end: when Group has members then retrieve each one.;	

		 end; * end: do eIndex = 1 to num;

     * Free search resources.;
     if shandle NE 0 then do;
     	 call ldaps_free(shandle,rc);
       if rc NE 0 then do;
         msg = sysmsg();
         put msg;
       end; 
     end;
%mend;  

%macro transmemkeyid;
    proc sql;
         update &idgrpmemstbl
            set memkeyid = 
                case when (select unique distinguishedName from adExt.ldapgrps
                     	where memkeyid = name) is missing then memkeyid
                     else (select unique distinguishedName from adExt.ldapgrps
                     	where memkeyid = name)
                end;           
     quit; 
     data &idgrpmemstbl;
		 	set &idgrpmemstbl (where=(not missing(memkeyid))) ;
		 run;
%mend;

/* Extract the groups from Active Directory */
%macro ADGroupFilter(filter=*);
data work.ldapgrps (keep=name description groupType distinguishedName 
				          sAMAccountName member whenChanged whenCreated
				          displayname);
               
	length entryname $200 attrName $100 value $600 filter $200 
	groupfilter $200 name $60 description $200 groupType $20
	distinguishedName $200 sAMAccountName $50 member $50 
	whenChanged $30 whenCreated $30 displayname $256;     

	handle = 0;
	rc     = 0;
	option = "OPT_REFERRALS_ON";

	/* open connection to LDAP server */     
	call ldaps_open( handle, &ADServer, &ADPort, &ADGrpBaseDN, &ADBindUser, &ADBindPW, rc, option );     
	if rc NE 0 then do;
		msg = sysmsg();
		put msg;
	end;

	timeLimit=0;
	sizeLimit=0;
	base='';  /* use default set at _open time */
	referral = "OPT_REFERRALS_ON";
	restart = ""; /* use default set at _open time */

	call ldaps_setOptions(handle, timeLimit, sizeLimit, base, referral, restart, rc);

	filter="(&(CN=&filter.)(objectCategory=Group)(objectClass=group))";
	* TEST;
	*filter="(&(CN=LUL-FTV-Users)(objectCategory=Group)(objectClass=group))";
	* SLUT: TEST;
	%ldapextrgroups  
	;

	/* close connection to LDAP server */
	call ldaps_close(handle,rc);
	if rc NE 0 then do;
		msg = sysmsg();
		put msg;
	end;
run;

/* append the result */
* proc append base=adExt.ldapgrps data=work.ldapgrps;
* run;

%mend;
