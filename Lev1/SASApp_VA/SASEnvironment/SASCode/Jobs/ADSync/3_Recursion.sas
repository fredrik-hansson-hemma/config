/* 
 * recursively get the group information 
 * The used dataset is being used to store what's already checked to keep from infinite loop
 * 
 */
%macro Recursion(firsttime=0, used=work.used);
	%if &firsttime eq 1 %then %do;
		/* prepare for the recursive call */
		proc sql noprint;
			create table &used. (name char(200));
		quit;

		proc datasets lib=adExt nolist;
			delete ldapgrps;
		run;
		quit;
		%let name1      = &GROUP_FILTER.;
		%let name_len = 1;
		%if %symexist(GROUP_FILTER2) %then %do;
			%let name2      = &GROUP_FILTER2.;
			%let name_len = 2;
			%if %symexist(GROUP_FILTER3) %then %do;
				%let name3      = &GROUP_FILTER3.;
				%let name_len = 3;
				%if %symexist(GROUP_FILTER4) %then %do;
					%let name4      = &GROUP_FILTER4.;
					%let name_len = 4;
					%if %symexist(GROUP_FILTER5) %then %do;
						%let name5      = &GROUP_FILTER5.;
						%let name_len = 5;
					%end;
				%end;
			%end;
		%end;
	%end;
	%else %do;
		/* store the name into macro variables */
		data _null_;
			set adExt.ldapgrps end=last;
			name = scan(scan(member, 1, ","), 2, "=");
			call symput("name" || trim(left(_n_)), trim(left(name)));
			if last then call symput("name_len", trim(left(_n_)));
		run;
	%end;
	%let rerun = 0;

	%put Inaktiverar loggning 
	filename slask dummy;
	proc printto log=slask;
	run;

	%do i=1 %to &name_len;
		/* test whether this is already done */
		proc sql noprint;
		   select count(*) into :done from &used. where name="&&name&i";
		quit;

		%if &done=0 %then %do;
			%let rerun = 1;
			%let n     = %bquote(&&name&i);  /* escape if names contain quotes */
			proc sql noprint;
				insert into &used. values("&n");
			quit;
			%put Checking membership for &n ;
			%ADGroupFilter(filter=&n);
			/* append the result */
			proc append base=adExt.ldapgrps data=work.ldapgrps;
			run;

		%end;
	%end;

	proc printto;
	run;

	%if &rerun eq 1 %then %do;
		%Recursion;
	%end;
%mend;

/* Macro: VanligaADGrupper
* Anpassning LUL. Macrot plockar ut alla personer ur vanliga AD-grupper så som 
* Users och Users-FIM och lägger personerna i SAS-grupper.
* Ex. Om gruppen LUL-FTV-Users-FIM är kopplad till LUL-FTV-SAS, ska alla personer
* i LUL-FTV-Users-FIM läggas som medlemmar till LUL-FTV-SAS.
* LUL-FTV-Users-FIM gruppen ska inte läsas in i SAS metadata. 
*/ 

%macro vanligaADGrupper();
 		
  proc datasets lib=work nolist;
		delete temp_ldapgrps nytrad2 anvand nytrad;
	quit;

	data medlemsgrupper;
		set adExt.ldapgrps;

		/* Hämta alla medlemmar som är grupper. Om medlemsnamn innehåller siffror är det antagligen ett användarID */
  	/* och sållas därför bort. */
		if length(member) in (6,8) and (
			index(member,'1') or index(member,'2') or index(member,'3') or index(member,'4') or index(member,'5') or
			index(member,'6') or index(member,'7') or index(member,'8') or index(member,'9') or index(member,'0')
			) then delete;
		if missing(member) then delete; 
	run;

  /* Filterar bort de medlemmar som finns i ldaggrps som huvudgrupper. */
  proc sql noprint;
    create table nyagrupper as
		select medlemsgrupper.*
		from medlemsgrupper as medlemsgrupper
		where medlemsgrupper.member not in (select name from adext.ldapgrps);
	quit;

 

	%let ny_id = %sysfunc(open(nyagrupper));
	  
	/* Läs in varje ny grupp från AD. */
	%do %while (%sysfunc(fetch(&ny_id)) = 0);
	  * Sparar undan namn på huvudgruppen;
		%let x_name = %sysfunc(getvarc(&ny_id, %sysfunc(varnum(&ny_id, NAME)))); 
	  %let x_grouptype = %sysfunc(getvarc(&ny_id, %sysfunc(varnum(&ny_id, GROUPTYPE)))); 
		%let x_description = %sysfunc(getvarc(&ny_id, %sysfunc(varnum(&ny_id, DESCRIPTION)))); 
		%let x_samaccountname = %sysfunc(getvarc(&ny_id, %sysfunc(varnum(&ny_id, SAMACCOUNTNAME)))); 
		%let x_distinguishedname = %sysfunc(getvarc(&ny_id, %sysfunc(varnum(&ny_id, DISTINGUISHEDNAME)))); 
		%let member = %sysfunc(getvarc(&ny_id, %sysfunc(varnum(&ny_id, MEMBER)))); 

		* Hämtar member från AD.;
    %ADGroupFilter(filter=&member); 

		data pers grps;
		set ldapgrps;
		if missing(member) then delete;
		* Om member är en person ska de flyttas till huvudgruppen;
		if length(member) in (6,8) and (
		index(member,'1') or index(member,'2') or index(member,'3') or index(member,'4') or index(member,'5') or
		index(member,'6') or index(member,'7') or index(member,'8') or index(member,'9') or index(member,'0')
		) then do;
			name = "&x_name";
			grouptype = "&x_grouptype";
			description = "&x_description";
			samaccountname = "&x_samaccountname";
			distinguishedname = "&x_distinguishedname";
			output pers;
		end;
		else output grps;
		run;
	
		/* Lägg in personer i Adext.ldapgrps. */
		proc append base=temp_ldapgrps data=pers force;
		run;
		
		/* Finns gruppen redan inläst från AD ska den inte hämtas in igen. */		
		data anvand (keep=member);
			set grps;
		run;	

		data nytrad (keep=member);
			set grps;
		run;

    proc datasets lib=work nolist;
		  delete nytrad2;
	  quit;
		
		%let nytrad_id = %sysfunc(open(NYTRAD));
		%let antal = %sysfunc(attrn(&nytrad_id, NOBS)); 
		/* Loopen ska avslutas om det inte finns mer medlemsgrupper att hämta in. */ 
		%if &antal le 0 %then %let igen = 0;
		%if &antal > 0 %then %let igen = 1;
		%let nytrad_id = %sysfunc(close(&nytrad_id));
		

    * Om der finns grupper i grupper; 
  	%do %while (&igen = 1);
     	%if %sysfunc(exist(NYTRAD2)) %then %do;
			  data nytrad; set nytrad2; run;
		  %end; * if sysfunc(exist(NYTRAD2));
		%let index = 0; * Index: används för att räkna antal loopar;
  		%let nytrad_id = %sysfunc(open(NYTRAD));
	    
			* loop through nytrad;
			%do %while (%sysfunc(fetch(&nytrad_id)) = 0);
			%let index = %eval(&index + 1);
			%let member = %sysfunc(getvarc(&nytrad_id, %sysfunc(varnum(&nytrad_id, MEMBER)))); 

	
			* Hämtar member från AD.;
    	%ADGroupFilter(filter=&member); 

			data pers grps;
			set ldapgrps;
			if missing(member) then delete;
			* Om member är en person ska de flyttas till huvudgruppen;
			if length(member) in (6,8) and (
			index(member,'1') or index(member,'2') or index(member,'3') or index(member,'4') or index(member,'5') or
			index(member,'6') or index(member,'7') or index(member,'8') or index(member,'9') or index(member,'0')
			) then do;
				name = "&x_name";
				grouptype = "&x_grouptype";
				description = "&x_description";
				samaccountname = "&x_samaccountname";
				distinguishedname = "&x_distinguishedname";
				output pers;
			end;
			else do;
				output grps;
			end;
			run;
	
			/* Lägg in personer i Adext.ldapgrps. */
			proc append base=temp_ldapgrps data=pers force;
			run;
		
			/* Finns gruppen redan inläst från AD ska den inte hämtas in igen. */		
			proc sql noprint;
		 	delete from grps
			where member in (select member from anvand);
    	quit;			

			proc append base=anvand data=grps (keep=member);
			run;

			* Om första loopen;
			%if &index = 1 %then %do;
				data nytrad2;
					set grps;
				run;
			%end; /* end: if index = 1 */
			%else %do;
			proc append base=nytrad2 data=grps force;
			run;
			%end; /* end: else do */
			%end; /* end: do while (sysfunc(fetch(NYTRAD)) = 0); */ 
			%let nytrad_id = %sysfunc(close(&nytrad_id));
	  	
			%let nytrad2_id = %sysfunc(open(NYTRAD2));
			%let antal = %sysfunc(attrn(&nytrad2_id, NOBS)); 
			/* Loopen ska avslutas om det inte finns mer medlemsgrupper att hämta in. */ 
			%if &antal le 0 %then %let igen = 0;
			%if &antal > 0 %then %let igen = 1;
			%let nytrad2_id = %sysfunc(close(&nytrad2_id));
		
		%end; /* end: do until igen = 1 */

	%end; /* end: do while fetch(NYAGRUPPER) */
	%let ny_id = %sysfunc(close(&ny_id));
  
  proc sort data=temp_ldapgrps out=ldapgrps dupout=duppiduppi nodupkey;
		by name distinguishedname grouptype member;
	run;

	proc append base=adext.ldapgrps data=ldapgrps;
	run;

%mend vanligaADGrupper;

%Recursion(firsttime=1);

/* Start: Anpassning LUL. */
/* I AD:s SAS-grupper kan IT-samordnare lägga in vanliga AD-grupper (typ -Users -Users-FIM). */
/* För varje AD-grupp som inte har ändelsen -SAS görs ny sökning mot AD för att hämta upp medlemmar. */

%vanligaADGrupper;

/* Slut: Anpassning LUL. */
