

%*
Det h�r macrot tar emot namnet p� en tabell och raderar f�rsta b�sta tabell som hittas med det namnet

ToDo:
* Om det hittas flera tabeller med samma namn ska macrot generera ett felmeddelande och avbryta utan att radera n�got.
* Om macrot inte hittar n�gon tabell med det angivna namnet, ska en tydlig not skrivas ut i loggen.
* (Om m�jligt) Det ska g� att ange vilken katalog (eller libname) som tabellen finns lagrad i, i metadata. 
  Detta f�r att minska risken f�r ihopblandning med andra tabeller med samma namn.										;
%macro delete_metadata_table(TableToDelete /* Tablename in metadata */ );
	data _null_;
		length uri $256 ;
		call missing(uri, nobj);

		* Get URI for table I want to delete	;
		search_string=cats("omsobj:DataTable?@Name='", "&TableToDelete", "'");
		nobj=metadata_getnobj(search_string,1,uri);

		* Delete table							;
		rc = METADATA_DELOBJ(uri);

		* Output for debug purposes				;
		put nobj= rc=;
	run;
%mend delete_metadata_table;