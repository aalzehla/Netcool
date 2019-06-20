------------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2009. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- CREATE NEW FIELDS IN COLLECTION OBJECTSERVER

ALTER TABLE alerts.status
	ADD COLUMN SentToAgg INTEGER
	ADD COLUMN CollectionExpireTime INTEGER
	ADD COLUMN CollectionFirst TIME
	ADD COLUMN AggregationFirst TIME
	ADD COLUMN DisplayFirst TIME;
go

------------------------------------------------------------------------------
-- DISABLE THE generic_clear TRIGGER AT COLLECTION

ALTER TRIGGER generic_clear SET ENABLED FALSE;
go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT INSERT TRIGGER

ALTER TRIGGER new_row SET ENABLED FALSE;
go

-- CREATE THE NEW INSERT TRIGGER

CREATE OR REPLACE TRIGGER col_new_row
GROUP default_triggers
PRIORITY 2
COMMENT 'Replacement insert trigger (alerts.status) for multi-ObjectServer environments.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
declare

	now utc;
begin

	-- USE A TEMPORARY VARIABLE TO STORE THE CURRENT TIMESTAMP
	set now = getdate();

	-- SET InternalLast AND StateChange
	set new.InternalLast = now;
	set new.StateChange = now;
	
	-- SET FirstOccurrence IF NOT SET
	if (new.FirstOccurrence = 0) then

		set new.FirstOccurrence = now;
	end if;

	-- SET LastOccurrence IF NOT SET
	if (new.LastOccurrence = 0) then

		set new.LastOccurrence = now;
	end if;

	set new.ServerName = getservername();
	set new.ServerSerial = new.Serial;

	set new.Tally = 1;

	-- IF CollectionExpireTime IS NOT SET, SET TO DEFAULT OF 30 SECONDS
	-- THIS FIELD SPECIFIES THE AMOUNT OF TIME (IN SECONDS) THAT AN
	-- EVENT SHOULD REMAIN AT THE COLLECTION LAYER AFTER THE FirstOccurrence
	if (new.CollectionExpireTime = 0) then

		set new.CollectionExpireTime = 30;
	end if;
end;
go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT REINSERT TRIGGER

ALTER TRIGGER deduplication SET ENABLED FALSE;
go

-- CREATE THE NEW REINSERT TRIGGER

CREATE OR REPLACE TRIGGER col_deduplication
GROUP default_triggers
PRIORITY 2
COMMENT 'Replacement reinsert trigger (alerts.status) for multi-ObjectServer environments.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
declare

	now utc;
begin
	-- CANCEL ATTEMPTS BY PROBES TO REINSERT OLD EVENTS
	if (%user.app_name = 'PROBE') then

		if ((old.LastOccurrence > new.LastOccurrence) or
			((old.ProbeSubSecondId >= new.ProbeSubSecondId) and
			(old.LastOccurrence = new.LastOccurrence)))
		then

			cancel;
		end if;
	end if;

	-- USE A TEMPORARY VARIABLE TO STORE THE CURRENT TIMESTAMP
	set now = getdate();

	-- SET LastOccurrence IF NOT SET
	if (new.LastOccurrence = 0) then

		set old.LastOccurrence = now;

	-- ELSE USE THE INCOMING VALUE
	else

		set old.LastOccurrence = new.LastOccurrence;
	end if;

	-- INCREMENT THE TALLY ON DEDUPLICATION
	set old.Tally = old.Tally + 1;

	-- UPDATE THE FOLLOWING FIELDS ON DEDUPLICATION
	set old.SentToAgg = 0;
	set old.Severity = new.Severity;
	set old.Type = new.Type;
	set old.Summary = new.Summary;
	set old.AlertKey = new.AlertKey;
	set old.ProbeSubSecondId = new.ProbeSubSecondId;

	-- UPDATE THE FOLLOWING WITH THE CURRENT TIMESTAMP
	set old.StateChange = now;
	set old.InternalLast = now;
	set old.CollectionFirst = now;
end;
go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT EXPIRE TRIGGER

ALTER TRIGGER expire SET ENABLED FALSE;
go

-- CREATE THE NEW EXPIRE TRIGGER

CREATE OR REPLACE TRIGGER col_expire
GROUP default_triggers
PRIORITY 2
COMMENT 'Replacement expire trigger (alerts.status) for multi-ObjectServer environments.'
EVERY 31 SECONDS
begin

	-- DELETE EVENTS THAT HAVE BEEN SENT TO AGGREGATION
	-- AND THAT HAVE EXCEEDED THEIR CollectionExpireTime.
	delete from alerts.status where
		SentToAgg = 1 and
		StateChange < (getdate() - CollectionExpireTime);
end;
go

------------------------------------------------------------------------------
-- CREATE PERFORMANCE STATISTICS TRIGGERS

CREATE OR REPLACE TRIGGER timestamp_inserts
GROUP default_triggers
PRIORITY 3
COMMENT 'Records timestamps for insertion into each tier (alerts.status) in multi-ObjectServer environments.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
begin

	-- SET TIMESTAMP CollectionFirst
	set new.CollectionFirst = getdate();
end;
go

------------------------------------------------------------------------------
-- RESEND ALL EVENTS AFTER A FAILOVER/FAILBACK

CREATE OR REPLACE TRIGGER resend_events_on_failover
GROUP default_triggers
PRIORITY 1
COMMENT 'This trigger resends all events in the Collection ObjectServer to the Aggregation layer in the event of a failover or a failback to ensure events are not lost in the event of a sudden outage.  SentToAgg is reset to 0 to allow the Gateway to resend all events.  CollectionFirst is reset for all events so that any events that haven\'t yet been reaped at the Collection layer but don\'t exist at the Aggregation layer anymore will receive an updated CollectionFirst time at the Aggregation layer.  This prevents the TimeToDisplay field being incorrectly skewed upwards due to a historic CollectionFirst value.  Any events that still exist at the Aggregation layer will correctly ignore this attempted update to the CollectionFirst field.'
ON SIGNAL gw_resync_start
begin

	-- RESET SentToAgg TO RESEND ALL EVENTS CURRENTLY IN COLLECTION
	-- RESET CollectionFirst SO THAT HISTORIC EVENTS NO LONGER AT
	-- AGGREGATION GET UPDATED CollectionFirst TIMESTAMPS
	update alerts.status set
		SentToAgg = 0,
		CollectionFirst = getdate();
end;
go

------------------------------------------------------------------------------
-- GRANT PERMISSIONS TO AutoAdmin GROUP FOR NEW TRIGGERS

GRANT ALTER ON TRIGGER col_new_row TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER col_deduplication TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER col_expire TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER timestamp_inserts TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER resend_events_on_failover TO ROLE 'AutoAdmin';
go

GRANT DROP ON TRIGGER col_new_row TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER col_deduplication TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER col_expire TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER timestamp_inserts TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER resend_events_on_failover TO ROLE 'AutoAdmin';
go

------------------------------------------------------------------------------
-- SET BackupObjectServer PROPERTY ON THE BACKUP OBJECTSERVER

CREATE OR REPLACE PROCEDURE configure_backup_objectserver ( )
begin

	if (getservername() like '_B') then

		ALTER SYSTEM SET 'BackupObjectServer' = TRUE;
	end if;
end;
go

-- EXECUTE THE PROCEDURE
EXECUTE configure_backup_objectserver;
go

-- AFTER INITIAL SETUP, THIS PROCEDURE IS NO LONGER REQUIRED
DROP PROCEDURE configure_backup_objectserver;
go

------------------------------------------------------------------------------
-- FAST-TRACKING NEW EVENTS THROUGH ALL OBJECTSERVER TIERS

-- CREATE A NEW CHANNEL FOR THE PROPAGATION OF EVENTS THROUGH A TIERED ENVIRONMENT
INSERT INTO iduc_system.channel (
	Name,
	ChannelID,
        Description)
VALUES (
	'accelerated_inserts',
	1,
	'This channel is part of the standard multitier architecture configuration and exists to enable inserts to propagate faster through a tiered architecture.');
go

-- CREATE A CHANNEL INTEREST FOR COLLECTION TO AGGREGATION GATEWAYS
INSERT INTO iduc_system.channel_interest (
	InterestID,
	ElementName,
	IsGroup,
	Hostname,
	AppName,
	AppDescription,
	ChannelID)
VALUES (
	1,
	'',
	0,
	'',
	'',
	'collection_gate',
	1);
go

-- CREATE A CHANNEL INTEREST FOR AGGREGATION TO DISPLAY GATEWAYS
INSERT INTO iduc_system.channel_interest (
	InterestID,
	ElementName,
	IsGroup,
	Hostname,
	AppName,
	AppDescription,
	ChannelID)
VALUES (
	2,
	'',
	0,
	'',
	'',
	'display_gate',
	1);
go

-- CREATE A CHANNEL INTEREST FOR THE FAILOVER AGGREGATION GATEWAY
INSERT INTO iduc_system.channel_interest (
	InterestID,
	ElementName,
	IsGroup,
	Hostname,
	AppName,
	AppDescription,
	ChannelID)
VALUES (
	3,
	'',
	0,
	'',
	'',
	'failover_gate',
	1);
go

-- CREATE A CHANNEL SUMMARY ENTRY FOR THE ACCELERATED INSERTS CHANNEL
INSERT INTO iduc_system.channel_summary (
	DatabaseName,
	TableName,
	ChannelID,
	SummaryID)
VALUES (
	'alerts',
	'status',
	1,
	1);
go

-- DEFINE THE FIELDS TO BE FORWARDED OVER THE ACCELERATED INSERTS CHANNEL
INSERT INTO iduc_system.channel_summary_cols (
	ColumnName, 
	SummaryID, 
	Position,
	ChannelID)
VALUES (
	'Serial',
	1,
	0,
	1);
go

-- CREATE A POST-INSERT TRIGGER TO FORWARD NEW INSERTS TO THE NEXT TIER
CREATE TRIGGER accelerated_inserts
GROUP default_triggers
PRIORITY 1
COMMENT 'Fast track inserts from alerts.status to higher tiers in a tiered environment'
AFTER INSERT ON alerts.status
FOR EACH ROW
BEGIN
	-- FAST TRACK ALL INSERTS TO THE NEXT TIER
	IDUC EVTFT 'accelerated_inserts', insert, new;
END;
go
