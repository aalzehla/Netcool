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
-- This file contains changes to the triggers that configure the integration 
-- with the IBM Operations Analytics - Log Analysis product. The changes in this 
-- file are for use with the Network Manager Insight Pack. After you apply this
-- file, the triggers prevent events from being forwarded to IBM Operations 
-- Analytics - Log Analysis until the events are enriched by data from the 
-- Network Manager product. (To enrich events, Network Manager populates the 
-- NmosObjInst column of the ObjectServer alerts.status table during event 
-- processing; the Insight Pack requires that the NmosObjInst column be 
-- populated.) The publish trigger runs every 5 seconds. If the events are not enriched
-- 20 seconds after the trigger has run, the events are forwarded to IBM Operations 
-- Analytics - Log Analysis without NmosObjInst data.
-- 
-- This file must be applied to version 8.1 fixpack 2 and above of the ObjectServer
-- only. If you are upgrading from a 7.4 release ObjectServer you must run the
-- update74fp3to81.sql script before this file.

--
-- Review the content of this file before you apply it to the ObjectServer. 
--
-- If you apply this file, automations are replaced, which means that any customizations 
-- you made to the automations are lost.
-- 
-- Back up your ObjectServer instance before you apply this file. 
--
-- NOTE: The following triggers are enabled after running this file:
-- scala_insert, scala_reinsert and scala_publish
-- The scala_triggers group is also enabled.
--
----------------------------------------------------------------------

-------------------------------------------------------------------------------
-- The following configuration is for SCA-LA integration
-------------------------------------------------------------------------------
-- ADD AN INTEGER CONTROL COLUMN FOR THE SCA-LA PUBLICATION TRIGGERS. 
-- IT DETERMINES WHETHER AN INITIAL ITNM ENRICHED EVENT HAS BEEN PUBLISHED TO SCA-LA.
alter table alerts.status add column SentToSCALA int;
go

-- ADD HUMAN-READABLE CONVERSIONS FOR THE CONTROL COLUMN.
insert into alerts.conversions (KeyField, Colname, Value, Conversion) values('SentToSCALA0','SentToSCALA',0,'Not Sent');
insert into alerts.conversions (KeyField, Colname, Value, Conversion) values('SentToSCALA1','SentToSCALA',1,'Sent');
go

---------------------------------------------------------------
-- CREATE A POST-INSERT TRIGGER TO MARK NEW EVENTS AS NOT SENT.
---------------------------------------------------------------
create or replace trigger scala_insert
group scala_triggers
enabled true
priority 20
comment 'Flag an inserted event as not sent to SCA-LA'
after insert on alerts.status
for each row
begin
	set new.SentToSCALA = 0;
end;
go

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

--------------------------------------------------------------------------------
-- CREATE A TEMPORAL TRIGGER TO FORWARD AN NEWLY INSERTED EVENTS THAT HAVE
-- NOW BEEN ENRICHED BY THE ITNM GATEWAY TO THE MESSAGE BUS GATEWAY RUNNING IN 
-- SCA-LA MODE
--------------------------------------------------------------------------------
create or replace trigger scala_publish
group scala_triggers
enabled true
priority 20
comment 'Fast track enriched events to the message bus Gateway running in SCALA mode.'
every 5 seconds
declare
	expire_time	date;
begin
	-- We need to publish any event that is more than 20 seconds old and
	-- has not been enriched by ITNM.
	set expire_time = (getdate() - 20);

	-- Find any event that has not yet been published.
	for each row notsent in alerts.status where notsent.SentToSCALA = 0
	begin
		if( 	notsent.NmosObjInst <> 0 or
			notsent.FirstOccurrence <= expire_time )
		then
			iduc evtft 'scala', insert, notsent;
			set notsent.SentToSCALA = 1;
		end if;
	end;
end;
go

------------------------------------------------------------------------------- 
-- ACTIVATE THE GROUP CONTAINING THE SCALA TRIGGERS
-------------------------------------------------------------------------------
alter trigger group scala_triggers set enabled true;
go

-------------------------------------------------------------------------------
-- End of SCA-LA configuration
-------------------------------------------------------------------------------

-- End of file
