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
    bs = "bs-ap-02.lul.se"
    bst = "bst-apx-02.lul.se"
  ;
  value $metauser 
    bs = "sasadm@saspw"
    bst = "sasadm@saspw"
  ;
  value $metapass 
    bs = "{SAS002}3625302A57941B764B291B5F2AB04D0C100A61DE"
    bst = "{SAS002}478B5D39102209EB3F606100017A7AAE"
  ;

run;

%mend;

/* Exempel p� anrop. */
%*get_metaserverattr;

