  /* Starta LASR-servrar. */

  %macro startaLASR(port=port);

	  proc printto print='/tmp/procoutputLASR.lst';

    proc lasr create PORT=&port
      path="/saswork/signaturefiles"
      signer="https://rapport.lul.se:443/SASLASRAuthorization"
      tablemem=80
      ;
      performance host="rapport.lul.se"
      install="/opt/TKGrid"
      nodes=ALL
      ;
    run;

	%mend;

  %startaLASR(port=10010); * LASR Analytic Server;
	%startaLASR(port=10031); * Public LASR;
	%startaLASR(port=10015); * EPJ;
	%startaLASR(port=10016); * LRC;
	%startaLASR(port=10017); * FTV;
  %startaLASR(port=10029); * Admin LASR;
