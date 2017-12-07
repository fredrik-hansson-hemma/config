  /* Stoppa LASR-servrar. */

  %macro stoppaLASR(port=port);

	proc printto print='/tmp/procoutputLASR.lst';

  proc lasr stop PORT=&port
    signer="https://bs-ap-20.lul.se:443/SASLASRAuthorization";
    performance host="bs-ap-20.lul.se";
  run;

	%mend;

  %stoppaLASR(port=10011); * LASR Analytic Server;
	%stoppaLASR(port=10031); * Public LASR;
	%stoppaLASR(port=10015); * EPJ;
	%stoppaLASR(port=10016); * LRC;
	%stoppaLASR(port=10017); * FTV;
  %stoppaLASR(port=10029); * Admin LASR;
