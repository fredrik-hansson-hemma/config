
* Hämtar ut värdet på en property som är lagrad i filen /opt/sas/RU_Utitlities/properties/server.properties	;
* Kända problem:
*    - Om en property finns specad två gånger i properties-filen kommer macrot returnera den första utan att varna användaren om att det finns fler förekomster.
*    - Det går inte att läsa property-värden som innehåller "="
*																																									;

%macro get_property(propertyfile=/opt/sas/RU_Utitlities/properties/server.properties /* Den här parametern bör aldrig behöva användas i anropet. Lägger till den ändå just in case...*/,
					property=);


	%put Macro get_property: Hämtar propertyn &property från filen &propertyfile och sparar i globala macrovariabel: %upcase(&property);
	options nonotes;
	filename properti "&propertyfile";

	data _null_;
		length property $32 value $31000;
		infile properti linesize=32000 dlm="=" missover encoding='utf-8' EOF=end_of_file;

		input property $ value $;

		* Om raden inte är tom och inte börjar med "#"	;
		* Läs allt före likamedtecknet. Matchar det propertyn vi söker?	;

		* Om vi hittar propertyn vi söker:									;
		if upcase(property)="%upcase(&property)" then do;
			* Lagra värdet i en global macrovariabel som heter som propertyn.	;
			call symputx("&property", value, 'G');
			* Bortkommenterad av säkerhetsskäl (ibland hämtas lösenord som inte ska skrivas till loggen)	;
			* put "Macro get_property: Hämtar värde från &propertyfile och sparar i globala macrovariabel: %upcase(&property)=" value;
			put ;
			* Avsluta därefter datasteget.										;
			stop;
		end;

		* Annars, fortsätt läsa nästa rad	;
		return;

		* Om filen tar slut utan att propertyn har hittats. Skriv ut ett felmeddelande	;
		end_of_file:
		put "%STR(ER)ROR: Kunde inte hitta propertien ""&property"" i &propertyfile";

	run;

	%* Återställer notes	;
	options notes;

%mend get_property;


/******* Tester ********

* Testar med en property som finns		;
%get_property(property=metaserver)

* Testar med en property som inte finns	;
%get_property(property=test)

/************************/