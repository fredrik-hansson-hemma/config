/************************************
* Program: SET_ALL_LABELS
* 
* L�ser kolumnbeskrivningar fr�n tabell ViewDefinitions
* i datalagret. Uppdaterar metadata om alla VA-tabeller i VALIBLA biblioteket.
*
* VATABLE: Tabell som har laddats.
* ex p� anrop: 
* %set_labels(VATABLE=EKONOMI) (s�tter rubriker p� tabell Ekonomi.)
* %set_labels(VATABLE=) (s�tter rubriker p� alla tabeller p� LASR servern.)  
************************************/


%set_labels(vatable=);

