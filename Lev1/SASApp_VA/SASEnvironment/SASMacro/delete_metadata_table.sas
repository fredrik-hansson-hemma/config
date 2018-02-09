

%*
Det här macrot tar emot namnet på en tabell och raderar första bästa tabell som hittas med det namnet

ToDo:
* Om macrot inte hittar någon tabell med det angivna namnet, ska en tydlig not skrivas ut i loggen.
* (Om möjligt) Det ska gå att ange vilken katalog (eller libname) som tabellen finns lagrad i, i metadata. 
  Detta för att minska risken för ihopblandning med andra tabeller med samma namn.										;
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
			put "%STR(ER)ROR: Tabellnamnet måste vara unikt. Radera eventuella dubletter från Management Console eller.";
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


/****** Provkörning
%delete_metadata_table(stg_DT_HJARTA, deleteAll=YES);
/***************************************/