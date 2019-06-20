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
-- CREATE NEW FIELDS IN AGGREGATION OBJECTSERVER

ALTER TABLE alerts.status
	ADD COLUMN CollectionFirst TIME
	ADD COLUMN AggregationFirst TIME
	ADD COLUMN DisplayFirst TIME;
go

------------------------------------------------------------------------------
-- INITIALISE LOAD-BALANCING FOR THE DISPLAY OBJECTSERVERS
-- NOT ENABLED BY DEFAULT
DELETE FROM master.servergroups;
go
-- INSERT INTO master.servergroups VALUES('DIS_1',1,1);
-- INSERT INTO master.servergroups VALUES('DIS_2',1,1);
-- go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT INSERT TRIGGER

ALTER TRIGGER new_row SET ENABLED FALSE;
go

-- CREATE THE NEW INSERT TRIGGER

CREATE OR REPLACE TRIGGER agg_new_row
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

	-- SET ServerName AND ServerSerial IF INSERT NOT COMING FROM AN OBJECTSERVER GATEWAY
	if (%user.description not in ('collection_gate', 'failover_gate') or
		new.ServerSerial = 0 or
		new.ServerName = '') then

                set new.ServerName = getservername();
                set new.ServerSerial = new.Serial;
        end if;

	-- SET FirstOccurrence IF NOT SET
	if (new.FirstOccurrence = 0) then

		set new.FirstOccurrence = now;
	end if;

	-- SET LastOccurrence IF NOT SET
	if (new.LastOccurrence = 0) then

		set new.LastOccurrence = now;
	end if;

	-- SET TALLY TO 1 IF SET TO 0.  THIS CAN HAPPEN WHEN
	-- A COLLECTION-TO-AGGREGATION RESYNC TAKES PLACE
	if (new.Tally = 0) then

		set new.Tally = 1;
	end if;
end;
go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT REINSERT TRIGGER

ALTER TRIGGER deduplication SET ENABLED FALSE;
go

-- CREATE THE NEW REINSERT TRIGGER

CREATE OR REPLACE TRIGGER agg_deduplication
GROUP default_triggers
PRIORITY 2
COMMENT 'Replacement reinsert trigger (alerts.status) for multi-ObjectServer environments.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
declare

	now utc;
begin

	-- USE A TEMPORARY VARIABLE TO STORE THE CURRENT TIMESTAMP
	set now = getdate();

	-- CANCEL ATTEMPTS BY PROBES TO REINSERT OLD EVENTS
	if (%user.app_name = 'PROBE') then

		if ((old.LastOccurrence > new.LastOccurrence) or
			((old.ProbeSubSecondId >= new.ProbeSubSecondId) and
			(old.LastOccurrence = new.LastOccurrence))) then

			cancel;
		end if;
	end if;

	-- IF REINSERT IS COMING FROM A FAILOVER GATEWAY
	if (%user.description = 'failover_gate') then

		set row old = new;

	-- ELSE REINSERT IS NOT COMING FROM A FAILOVER GATEWAY
	else

		-- IF REINSERT IS COMING FROM A COLLECTION GATEWAY
		if (%user.description = 'collection_gate') then

			-- ADD INCOMING TALLY TO CURRENT TOTAL
			set old.Tally = old.Tally + new.Tally;

		-- ELSE REINSERT IS NOT COMING FROM ANY GATEWAY
		else

			-- SIMPLY INCREMENT TALLY
			set old.Tally = old.Tally + 1;
		end if;

		-- SET LastOccurrence IF NOT SET
		if (new.LastOccurrence = 0) then

			set old.LastOccurrence = now;

		-- ELSE USE THE INCOMING VALUE
 		else 

			set old.LastOccurrence = new.LastOccurrence;
		end if;

		-- UPDATE THE FOLLOWING FIELDS ON DEDUPLICATION
		set old.Type = new.Type;
		set old.Summary = new.Summary;
		set old.AlertKey = new.AlertKey;
		set old.ProbeSubSecondId = new.ProbeSubSecondId;

		------------------------------------------
		-- HANDLE SEVERITY UPDATE ON DEDUPLICATION
		------------------------------------------
		-- DEFAULT - UPDATE ALWAYS

		set old.Severity = new.Severity;

		------------------------------------------
		-- REAWAKEN CLOSED ONLY - UPDATE ONLY IF CLEAR
		--
		-- if ((old.Severity = 0) and (new.Severity > 0)) then
		--
		--	set old.Severity = new.Severity;
		-- end if; 
		------------------------------------------
	end if;

	-- UPDATE THE FOLLOWING WITH THE CURRENT TIMESTAMP
	set old.StateChange = now;
	set old.InternalLast = now;
end;
go

------------------------------------------------------------------------------
-- CREATE PERFORMANCE STATISTICS TRIGGER

CREATE OR REPLACE TRIGGER timestamp_inserts
GROUP default_triggers
PRIORITY 3
COMMENT 'Records timestamps for insertion into each tier (alerts.status) in multi-ObjectServer environments.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
begin

	-- SET TIMESTAMP AggregationFirst IF NOT SET
	if (new.AggregationFirst = 0) then

		set new.AggregationFirst = getdate();
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE FAILBACK TRIGGERS

CREATE TRIGGER GROUP failback_triggers;
go

ALTER TRIGGER GROUP failback_triggers SET ENABLED TRUE;
go

-- CREATE A TRIGGER TO DISCONNECT ALL CLIENTS FROM THE BACKUP AFTER GATEWAY RESYNC

CREATE OR REPLACE TRIGGER disconnect_all_clients
GROUP failback_triggers
PRIORITY 2
COMMENT 'Once bidirectional Gateway resynchronisation has completed, disconnect all clients
except for the bidirectional Gateway, Administrator and Web GUI clients.
This will cause all connected clients to fail back to the primary ObjectServer AGG_P.
This trigger should only be enabled on the backup ObjectServer AGG_B.'
ON SIGNAL gw_resync_finish
begin

	-- CHECK IF gw_resync_finish IS FROM failover_gate
	if (%user.description = 'failover_gate') then

		ALTER SYSTEM SET 'ActingPrimary' = FALSE;

		-- DISCONNECT ALL CLIENTS EXCEPT FOR THE FAILOVER
		-- GATEWAY OR ADMINISTRATOR SESSIONS
		for each row this_connection in catalog.connections where
			this_connection.AppName <> 'Administrator' and
			this_connection.AppName <> 'WEBTOP' and
			this_connection.AppDescription <> 'failover_gate'
		begin

			alter system drop connection this_connection.ConnectionID;
		end;
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE RESYNC COMPLETE TRIGGER

CREATE OR REPLACE TRIGGER resync_complete
GROUP primary_only
PRIORITY 1
COMMENT 'Creates synthetic events to indicate when Gateways have completed resynchronisation.'
ON SIGNAL gw_resync_finish
declare

	now utc;
	summary_string char(512);
begin

	-- INITIALISE VARIABLE
	set now = getdate();
	set summary_string = '';

	-- CONSTRUCT SUMMARY STRING
	if (%user.description = 'collection_gate') then

		set summary_string = 'Collection ';

	elseif (%user.description = 'failover_gate') then

		set summary_string = 'Failover ';

	elseif (%user.description = 'display_gate') then

		set summary_string = 'Display ';

	end if;

	set summary_string = summary_string +
		'Gateway resynchronisation complete on ' +
		%user.host_name +
		'.'; 

	-- INSERT A SYNTHETIC EVENT TO INDICATE GATEWAY RESYNCHRONISATION COMPLETION
	insert into alerts.status (
		Identifier,
		Node,
		Summary,
		Type,
		Severity,
		FirstOccurrence,
		LastOccurrence,
		Tally,
		ExpireTime,
		AlertGroup,
		OwnerUID,
		Manager)
	values (
		'gateway_resync_' + to_char(now) + '_' + %user.description + '_' + to_char(%user.connection_id),
		get_prop_value('Hostname'),
		summary_string,
		13,
		2,
		now,
		now,
		1,
		86400,
		'nco_objserv',
		65534,
		'SystemWatch');

end;
go

------------------------------------------------------------------------------
-- GRANT PERMISSIONS TO AutoAdmin GROUP FOR NEW TRIGGERS

GRANT ALTER ON TRIGGER agg_new_row TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER agg_deduplication TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER timestamp_inserts TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER disconnect_all_clients TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER resync_complete TO ROLE 'AutoAdmin';
go

GRANT DROP ON TRIGGER agg_new_row TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER agg_deduplication TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER timestamp_inserts TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER disconnect_all_clients TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER resync_complete TO ROLE 'AutoAdmin';
go

------------------------------------------------------------------------------
-- CREATE A CONVERSION FOR 9999999

INSERT INTO alerts.conversions (
	KeyField,
	Colname,
	Value,
	Conversion)
values (
	'TimeToDisplay9999999',
	'TimeToDisplay',
	9999999,
	'N/A');
go

------------------------------------------------------------------------------
-- CREATE A PROCEDURE TO CONFIGURE THE BACKUP OBJECTSERVER

CREATE OR REPLACE PROCEDURE set_up_objectservers ( )
begin

	-- IF THIS OBJECTSERVER IS A BACKUP OBJECTSERVER AND FOLLOWS
	-- THE STANDARD NAMING CONVENTION, IT WILL HAVE _B IN ITS NAME
	if (getservername() like '_B') then

		-- IF IT DOES, SET THE BackupObjectServer PROPERTY TO TRUE
		ALTER SYSTEM SET 'BackupObjectServer' = TRUE;
		ALTER SYSTEM SET 'ActingPrimary' = FALSE;

		-- ENABLE THE FAILOVER TRIGGERS (DISABLED BY DEFAULT)
		ALTER TRIGGER backup_counterpart_down SET ENABLED TRUE;
		ALTER TRIGGER backup_counterpart_up SET ENABLED TRUE;
		ALTER TRIGGER backup_startup SET ENABLED TRUE;

		-- DISABLE THE primary_only TRIGGER GROUP VIA THE OUT-OF-THE-BOX
		-- PROCEDURE
		EXECUTE automation_disable;

	-- ELSE IT IS A PRIMARY OBJECTSERVER IN WHICH CASE DISABLE THE TRIGGER
	-- disconnect_all_clients AS THIS SHOULD ONLY BE ENABLED ON THE BACKUP
	else

		ALTER TRIGGER disconnect_all_clients SET ENABLED FALSE;
	end if;
end;
go

-- EXECUTE THE PROCEDURE TO SET UP THE OBJECTSERVERS
EXECUTE set_up_objectservers;
go

-- AFTER INITIAL SETUP, THIS PROCEDURE IS NO LONGER REQUIRED SO DROP IT
DROP PROCEDURE set_up_objectservers;
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
