
* H�mtar ut v�rdet p� en property som �r lagrad i filen /opt/sas/RU_Utitlities/properties/server.properties	;
* K�nda problem:
*    - Om en property finns specad tv� g�nger i properties-filen kommer macrot returnera den f�rsta utan att varna anv�ndaren om att det finns fler f�rekomster.
*    - Det g�r inte att l�sa property-v�rden som inneh�ller "="
*																																									;

%macro get_property(propertyfile=/opt/sas/RU_Utitlities/properties/server.properties /* Den h�r parametern b�r aldrig beh�va anv�ndas i anropet. L�gger till den �nd� just in case...*/,
					property=);

	filename properti "&propertyfile";

	data _null_;
		length property $32 value $31000;
		infile properti linesize=32000 dlm="=" missover encoding='utf-8' EOF=end_of_file;

		input property $ value $;

		* Om raden inte �r tom och inte b�rjar med "#"	;
		* L�s allt f�re likamedtecknet. Matchar det propertyn vi s�ker?	;

		* Om vi hittar propertyn vi s�ker:									;
		if upcase(property)="%upcase(&property)" then do;
			* Lagra v�rdet i en global macrovariabel som heter som propertyn.	;
			call symputx("&property", value, 'G');
			put "NOTE: S�tter f�ljande globala macrovariabel: %upcase(&property)=" value;
			put ;
			* Avsluta d�refter datasteget.										;
			stop;
		end;

		* Annars, forts�tt l�sa n�sta rad	;
		return;

		* Om filen tar slut utan att propertyn har hittats. Skriv ut ett felmeddelande	;
		end_of_file:
		put "%STR(ER)ROR: Kunde inte hitta propertien ""&property"" i &propertyfile";

	run;

%mend get_property;


/******* Tester ********

* Testar med en property som finns		;
%get_property(property=metaserver)

* Testar med en property som inte finns	;
%get_property(property=test)

/************************/