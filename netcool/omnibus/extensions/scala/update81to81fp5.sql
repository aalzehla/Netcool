-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2015. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- This file contains changes to the triggers contained in the 'scala_itnm_configuration.sql'
-- file that configure the integration with the IBM Operations Analytics - Log Analysis
-- product and Network Manager Insight Pack. 
--
-- You should apply this file if you have previously installed 'scala_itnm_configuration'
-- triggers, have upgraded the OMNIbusInsightPack to version 1.3.0.2 and are using the
-- xml1302.map file with the MessageBus Gateway version 7.

---------------------------------------------------------------
-- CREATE A POST-REINSERT TRIGGER TO FORWARD NEW INSERTS TO THE
-- MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE.
---------------------------------------------------------------
create or replace trigger scala_reinsert
group scala_triggers
enabled true
priority 20
comment 'Send an enriched event reinsert for alerts.status to message bus Gateway running in SCALA mode '
before reinsert on alerts.status
for each row
begin
	if( 	old.NmosObjInst <> 0 or
		old.FirstOccurrence <= (getdate() - 20) )
	then
		if (	old.SentToSCALA = 0	)
		then
			iduc evtft 'scala', insert, old;
			set old.SentToSCALA = 1;
		else
			iduc evtft 'scala', update, old;
		end if;
	end if;
end;
go
