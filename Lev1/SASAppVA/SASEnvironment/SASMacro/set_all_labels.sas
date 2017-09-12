/************************************
* Program: SET_ALL_LABELS
* 
* Läser kolumnbeskrivningar från tabell ViewDefinitions
* i datalagret. Uppdaterar metadata om alla VA-tabeller i VALIBLA biblioteket.
*
* VATABLE: Tabell som har laddats.
* ex på anrop: 
* %set_labels(VATABLE=EKONOMI) (sätter rubriker på tabell Ekonomi.)
* %set_labels(VATABLE=) (sätter rubriker på alla tabeller på LASR servern.)  
************************************/


%set_labels(vatable=);

