/**********************************************************************************/
/*                                                                                */
/* Copyright (c) 2011, SAS Institute Inc., Cary, NC, USA, All Rights Reserved     */
/*                                                                                */
/**********************************************************************************/

%macro apm_request_term();

/*
 *  End the ARM execution for userid.
 */


%ARMSTOP(maconly=yes);
%ARMEND(maconly=yes);


%mend;

%apm_request_term;
