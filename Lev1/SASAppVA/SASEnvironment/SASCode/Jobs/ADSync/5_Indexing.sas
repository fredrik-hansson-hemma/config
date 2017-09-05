/************************************************************************/
/* The idgrps and grpmems (i.e. group definitions and group membership) */
/* Tables are already in sorted order.  Create Indexes for them.        */
/************************************************************************/

/* Create Index on idgrps dataset for speedy retrieval */ 
proc datasets library=adExt memtype=data nolist;   
	modify idgrps;
	index create keyid;
quit;  

/* Create Index on grpmems dataset for speedy retrieval */ 
proc datasets library=adExt memtype=data nolist;   
	modify grpmems;
	index create grpkeyid;
quit;                                                                                         

/************************************************************************/
/* Each person entry in &persontbl must be unique according to the      */
/* rules for Metadata Authorization Identities.  By enforcing this      */
/* uniqueness here, we help ensure that the Metadata XML will load      */
/* correctly when the %mduimpl macro is invoked with submit=1 below.    */
/************************************************************************/ 

proc sort data=&persontbl force nodupkey;
     by keyid;
run;

proc datasets library=adExt memtype=data nolist;   /* Create Index for */
     modify person;                                /* speedy retrieval */
     index create keyid;
quit;

/************************************************************************/
/* The location dataset should have an entry for each location that     */
/* a person will have.  So, if there are 3 people and one of them       */
/* has 2 locations, then there should be 4 records in &locationtbl.     */
/* Sort &locationtbl by the location keyid.                             */
/************************************************************************/

proc sort data=&locationtbl nodupkey;
     by keyid;
run;

proc datasets library=adExt memtype=data nolist;   /* Create Index for */
     modify location;                              /* speedy retrieval */
     index create keyid;
quit;            
                              
/************************************************************************/
/* Each person can have one or more entries in &phonetbl.  Each         */
/* entry will be a unique combination of keyid and phone number.        */
/************************************************************************/                                                                           
proc sort data=&phonetbl nodupkey;
     by keyid phonenumber;
run;                                                                                             

proc datasets library=adExt memtype=data nolist;   /* Create Index for */
     modify phone;                                 /* speedy retrieval */
     index create keyid;
quit;

/************************************************************************/
/* Each person can have one or more entries in &emailtbl. Because       */
/* more than one person can share an EMAIL address, the entries         */
/* are not required to be unique.                                       */
/************************************************************************/
proc sort data=&emailtbl;
     by keyid;
run;  
 
/* Create Index on email dataset for speedy retrieval */
proc datasets library=adExt memtype=data nolist;  
     modify email;                                  
     index create keyid;
quit;

/************************************************************************/
/* Because each person can have multiple logins, the entries by         */
/* keyid are not required to be unique.  However, the UserID            */
/* attribute by relation to AuthenticationDomain must be unique for     */
/* each login owned by a person, *and* a login can only be related      */
/* to one person.  These constraints are enforced during processing     */
/* in the %mduimpl macro, which is invoked below.                       */
/************************************************************************/
proc sort data=&logintbl;
     by keyid;
run;  
 
/* Create Index on logins dataset for speedy retrieval */
proc datasets library=adExt memtype=data nolist;   
     modify logins;                                
     index create keyid;
quit;  

/************************************************************************/
/* We've imported group membership without knowing if the members were  */
/* actually imported as people or groups.  If they weren't then we'll   */
/* get messages during the load about unknown group members.  To avoid  */
/* those messages, let's go ahead and eliminate those "unknown members. */
/************************************************************************/

proc sql;
     create table &idgrpmemstbl._del as 
       select * from &idgrpmemstbl
        where memkeyid not in (select unique keyid from &persontbl)
                 and grpkeyid not in (select unique keyid from &idgrptbl);

     delete from &idgrpmemstbl
        where memkeyid not in (select unique keyid from &persontbl)
                 and grpkeyid not in (select unique keyid from &idgrptbl);
quit;
/*
proc sql;
     create table &idgrpmemstbl._del as 
       select * from &idgrpmemstbl
        where memkeyid not in (select unique keyid from &persontbl)
                 and memkeyid not in (select unique keyid from &idgrptbl);

     delete from &idgrpmemstbl
        where memkeyid not in (select unique keyid from &persontbl)
                 and memkeyid not in (select unique keyid from &idgrptbl);
quit;
*/


%put &idgrpmemstbl;
%put &persontbl;
%put &idgrptbl;
