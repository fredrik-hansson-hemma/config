/************************************
* Program: UPDATE_AUDIT_VISUALANALYTICS_FULL_LOAD
* 
* Lägger på organisationstillhörighet från fimObjects.
* Programmet anropas från Autoload.sas för EVDMLA.
*
************************************/

* VA användningsdata;
libname app "/opt/sas/config/Lev1/AppData/SASVisualAnalytics/VisualAnalyticsAdministrator/AutoLoad/EVDMLA/";
* Datalagret;
LIBNAME LULDW SQLSVR  READ_LOCK_TYPE=NOLOCK  Datasrc=LULDW  SCHEMA=va  USER=SAS_Prod_fetch  PASSWORD="{SAS002}64F4120B242E176A4E2A18DC1D5B8C2D112C83403A86BC82185EA193" ;

* Hämtar organisation från fimObjects per användarID.;
* Skapar datumflaggor utifrån timestamp_dttm.;

proc sql noprint;

create table Audit_VisualAnalytics as
select 
	audit.action_success_flg,
	audit.action_type,
	audit.audit_id,
	audit.audit_info,
	audit.executor_nm,
	audit.newclient_id,
	audit.newelapsed_time,
	audit.newemail_recipients,
	audit.newemail_sender,
	audit.newexport_object,
	audit.newexport_output,
	audit.newexport_rows,
	audit.newlasr_server_name,
	audit.newlocation,
	audit.newreport_elements,
	audit.newserver_app,
	audit.newtable_name,
	audit.object_type,
	audit.oldlocation,
	audit.timestamp_dttm,
	audit.userid,
	scan(fim.fullpath,2, '\') as org2,
	case when scan(fim.fullpath,2, '\') in ('UAS','PV') then scan(fim.fullpath, 3, '\')
		else '' end as org3,
	case when intck("MONTH", datepart(timestamp_dttm), (today()-1)) lt 3 then 1
		else 0 end as last3mon,
  case when intck("DAY", datepart(timestamp_dttm), (today()-1)) lt 7 then 1
		else 0 end as last1week,
  case when intck("DAY", datepart(timestamp_dttm), (today()-1)) lt 1 then 1
		else 0 end as last1day

from app.AUDIT_VISUALANALYTICS as audit LEFT JOIN LULDW.fimObjects as fim
on audit.userid = fim.UserName
;

quit;

proc copy in=work out=app memtype=data;
select audit_visualanalytics;
run;


