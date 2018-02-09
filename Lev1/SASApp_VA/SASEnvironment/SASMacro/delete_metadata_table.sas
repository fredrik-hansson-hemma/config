

%*
Det h�r macrot tar emot namnet p� en tabell och raderar f�rsta b�sta tabell som hittas med det namnet

ToDo:
* Om macrot inte hittar n�gon tabell med det angivna namnet, ska en tydlig not skrivas ut i loggen.
* (Om m�jligt) Det ska g� att ange vilken katalog (eller libname) som tabellen finns lagrad i, i metadata. 
  Detta f�r att minska risken f�r ihopblandning med andra tabeller med samma namn.										;
%macro delete_metadata_table(	TableToDelete /* Tablename in metadata */ ,
								deleteAll=NO);
	data _null_;
		length uri $256 ;
		call missing(uri, nobj);

		* Get URI for table I want to delete	;
		search_string=cats("omsobj:DataTable?@Name='", "&TableToDelete", "'");
		nobj=metadata_getnobj(search_string,1,uri);

		if nobj GT 1 and "&deleteAll"="NO" then do;
			put "%STR(ER)ROR: Macrot delete_metadata_table hittade " nobj "tabeller med namnet &TableToDelete i metadata.";
			put "%STR(ER)ROR: Tabellnamnet m�ste vara unikt. Radera eventuella dubletter fr�n Management Console eller.";
			put "%STR(ER)ROR:" 'anropa macrot med %delete_metadata_table(' "&TableToDelete, deleteAll=YES);";
			put "%STR(ER)ROR: Programmet avbryts.";
			abort abend;
		end;
		else if nobj LT 1 then do;
			put "NOTE: Macrot delete_metadata_table hittade ingen tabell med namnet &TableToDelete i metadata. Inget kommer raderas.";
		end;

		do i=1 to nobj;
			* Delete table							;
			rc = METADATA_DELOBJ(uri);
		end;

		* Output for debug purposes				;
		put nobj= rc=;
	run;
%mend delete_metadata_table;


/****** Provk�rning
%delete_metadata_table(stg_DT_HJARTA, deleteAll=YES);
/***************************************/