/****************************************************
* Macro: get_metaserverattr
*
* Skapar formaten METAPORT, METASERVER, METAUSER, METAPASS,
* som kan anv�ndas f�r att h�mta inloggningsuppg f�r metadataserver.
*****************************************************/

%macro get_metaserverattr();

* Format f�r att s�tta port och server till prod- eller testmilj�n. ;
proc format;
  value $metaport 
    bs = "8561"
    bst = "8561"
  ;
  value $metaserver 
    bs = "bs-ap-20.lul.se"
    bst = "bst-apx-20.lul.se"
  ;
  value $metauser 
    bs = "sasadm@saspw"
    bst = "sasadm@saspw"
  ;
  value $metapass 
    bs = "{SAS002}7D55EB1F27B29BC354FD035416238B741C2BF86732381F40"
    bst = "{SAS002}764CF83517DF837D08F526AE441395DB47C8ECE5"
  ;

run;

%mend;

/* Exempel p� anrop. */
%*get_metaserverattr;

