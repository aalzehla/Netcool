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
-- CREATE NEW FIELDS IN DISPLAY OBJECTSERVER

ALTER TABLE alerts.status
	ADD COLUMN CollectionFirst TIME
	ADD COLUMN AggregationFirst TIME
	ADD COLUMN DisplayFirst TIME
	-- TimeToDisplay STORES THE NUMBER OF SECONDS FOR THE EVENT
	-- TO GET TO THE DISPLAY LAYER AND IS SET IN timestamp_inserts
	ADD COLUMN TimeToDisplay INTEGER;
go

------------------------------------------------------------------------------
-- INITIALISE DISPLAY OBJECTSERVER TABLES

DELETE FROM master.national;
go

-- EDIT AGGREGATION OBJECTSERVER NAME IF NOT AGG_V

INSERT INTO master.national VALUES (0, 'AGG_V', 1);
go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT INSERT TRIGGER

ALTER TRIGGER new_row SET ENABLED FALSE;
go

-- CREATE THE NEW INSERT TRIGGER

CREATE OR REPLACE TRIGGER dsd_new_row
GROUP dsd_triggers
PRIORITY 2
COMMENT 'Replacement insert trigger (alerts.status) for multi-ObjectServer environments.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
declare

	now utc;
begin

	-- USE A TEMPORARY VARIABLE TO STORE THE CURRENT TIMESTAMP
	set now = getdate();

	-- CANCEL ALL INSERTS IF NOT EITHER COMING FROM THE DISPLAY GATEWAY OR IF
	-- NOT BEING INSERTED BY THE ROOT USER.  THIS ALLOWS INSERTS TO EXECUTE
	-- FOR DISPLAY LAYER PERFORMANCE TRIGGERS.
	if (%user.description <> 'display_gate' and %user.user_id <> 0) then

		cancel;
	end if;

	-- SET ServerName AND ServerSerial IF INSERT IS NOT COMING FROM A GATEWAY
        if (%user.description <> 'display_gate') then

		set new.ServerName = getservername();
		set new.ServerSerial = new.Serial;
        end if;

	-- UPDATE THE FOLLOWING WITH THE CURRENT TIMESTAMP
	set new.InternalLast = now;
	set new.StateChange = now;
end;
go

------------------------------------------------------------------------------
-- DISABLE THE DEFAULT REINSERT TRIGGER

ALTER TRIGGER deduplication SET ENABLED FALSE;
go

-- CREATE THE NEW REINSERT TRIGGER

CREATE OR REPLACE TRIGGER dsd_deduplication
GROUP dsd_triggers
PRIORITY 2
COMMENT 'Replacement reinsert trigger (alerts.status) for multi-ObjectServer environments.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
declare

	now utc;
	displayfirst utc;
	timetodisplay integer;
	serverserial integer;
	servername char(64);

begin

	-- USE A TEMPORARY VARIABLE TO STORE THE CURRENT TIMESTAMP
	set now = getdate();

	-- PRESERVE KEY FIELDS IN TEMP VARIABLES
	set displayfirst = old.DisplayFirst;
	set timetodisplay = old.TimeToDisplay;
	set serverserial = old.ServerSerial;
	set servername = old.ServerName;

	-- CANCEL ALL REINSERTS IF NOT EITHER COMING FROM THE DISPLAY GATEWAY OR IF
	-- NOT BEING INSERTED BY THE ROOT USER.  THIS ALLOWS REINSERTS TO EXECUTE
	-- FOR DISPLAY LAYER PERFORMANCE TRIGGERS.
	if (%user.description <> 'display_gate' and %user.user_id <> 0) then

		cancel;
	end if;

	-- REPLACE EXISTING ROW WITH INCOMING ROW
	set row old = new;

	-- RESTORE KEY FIELDS
	set old.DisplayFirst = displayfirst;
	set old.TimeToDisplay = timetodisplay;
	set old.ServerSerial = serverserial;
	set old.ServerName = servername;

	-- UPDATE THE FOLLOWING WITH THE CURRENT TIMESTAMP
	set old.InternalLast = now;
	set old.StateChange = now;
end;
go

------------------------------------------------------------------------------
-- CREATE PERFORMANCE STATISTICS TRIGGERS

CREATE OR REPLACE TRIGGER timestamp_inserts
GROUP dsd_triggers
PRIORITY 3
COMMENT 'Records timestamps for insertion into each tier (alerts.status) in multi-ObjectServer environments.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
begin

	-- SET TIMESTAMP DisplayFirst
	set new.DisplayFirst = getdate();

	-- CALCULATE TIME TAKEN TO DISPLAY
	-- CASE 1: EVENT WAS INSERTED AT THE COLLECTION LAYER
	if (new.CollectionFirst <> 0 and new.AggregationFirst <> 0 and new.DisplayFirst <> 0) then

		set new.TimeToDisplay = (to_int(new.DisplayFirst) - to_int(new.AggregationFirst)) +
			(to_int(new.AggregationFirst) - to_int(new.CollectionFirst));

	-- CASE 2: EVENT WAS INSERTED AT THE AGGREGATION LAYER
	elseif (new.CollectionFirst = 0 and new.AggregationFirst <> 0 and new.DisplayFirst <> 0) then

		set new.TimeToDisplay = (to_int(new.DisplayFirst) - to_int(new.AggregationFirst));

	-- CASE 3: EVENT WAS INSERTED AT THE DISPLAY LAYER
	else

		set new.TimeToDisplay = 0;

	end if;
end;
go

CREATE OR REPLACE TRIGGER tag_old_events
GROUP dsd_triggers
PRIORITY 1
COMMENT 'This trigger detects the moment that the Aggregation-to-Display Gateway completes its resynchronisation step.
It then tags all events whose LastOccurrence was before this moment so that the old events do not get included
in the average time-to-display calculation.  Old events will incorrectly skew the average TimeToDisplay value upwards.' 
ON SIGNAL gw_resync_finish
begin

	update alerts.status set TimeToDisplay = 9999999 where LastOccurrence <= getdate();
end;
go

CREATE OR REPLACE TRIGGER calculate_time_to_display
GROUP dsd_triggers
PRIORITY 3
COMMENT
'Calculates the average time-to-display for all events and inserts a
synthetic event with the average time included in the Summary field.
Events that occurred before the Gateway start time are excluded since
these may incorrectly skew the average time-to-display upwards.'
EVERY 61 SECONDS
declare
	running_total integer;
	running_count integer;
	average_time integer;
	now utc;
begin

	-- INITIALISE VARIABLES
	set running_total  = 0;
	set running_count = 0;
	set average_time = 0;

	-- USE A TEMPORARY VARIABLE TO STORE THE CURRENT TIMESTAMP
	set now = getdate();

	-- TALLY UP THE TIME TAKEN EXCLUDING EVENTS THAT OCCURRED BEFORE
	-- THE GATEWAY CONNECT/FAILOVER/FAILBACK TIME
	for each row this_row in alerts.status where
		this_row.TimeToDisplay <> 9999999
	begin

		set running_total = running_total + this_row.TimeToDisplay;
		set running_count = running_count + 1;
	end;

	-- IF THERE ARE MORE THAN ZERO EVENTS
	if (running_count > 0) then

		-- CALCULATE OVERALL AVERAGE TIME TO DISPLAY
		set average_time = running_total / running_count;

		-- INSERT A STATISTIC EVENT SHOWING AVERAGE TIME TO DISPLAY
		insert into alerts.status (
			Identifier,
			Node,
			Summary,
			Type,
			Severity,
			FirstOccurrence,
			LastOccurrence,
			TimeToDisplay,
			Tally,
			AlertGroup,
			OwnerUID,
			Manager)
		values (
			'time_to_display',
			get_prop_value('Hostname'),
			'Average time to display events: ' + to_char(average_time) + ' seconds.',
			13,
			2,
			now,
			now,
			0,
			1,
			'nco_objserv',
			65534,
			'SystemWatch');
	end if;
end;
go

-- DISABLE AVERAGE TIME-TO-DISPLAY CALCULATION WHILE GATEWAY RESYNCHRONISES

CREATE OR REPLACE TRIGGER disable_average_calculation
GROUP dsd_triggers
PRIORITY 1
COMMENT 'This trigger disables the time-to-display calculation while the Gateway is resynchronising.'
ON SIGNAL gw_resync_start
begin

	alter trigger calculate_time_to_display set enabled FALSE;
end;
go

-- ENABLE AVERAGE TIME-TO-DISPLAY CALCULATION ONCE GATEWAY RESYNCHRONISATION COMPLETES

CREATE OR REPLACE TRIGGER enable_average_calculation
GROUP dsd_triggers
PRIORITY 1
COMMENT 'This trigger re-enables the time-to-display calculation once the Gateway has finished resynchronising.'
ON SIGNAL gw_resync_finish
begin

	alter trigger calculate_time_to_display set enabled TRUE;
end;
go

------------------------------------------------------------------------------
-- GRANT PERMISSIONS TO AutoAdmin GROUP FOR NEW TRIGGERS

GRANT ALTER ON TRIGGER dsd_new_row TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER dsd_deduplication TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER timestamp_inserts TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER tag_old_events TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER calculate_time_to_display TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER disable_average_calculation TO ROLE 'AutoAdmin';
GRANT ALTER ON TRIGGER enable_average_calculation TO ROLE 'AutoAdmin';
go

GRANT DROP ON TRIGGER dsd_new_row TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER dsd_deduplication TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER timestamp_inserts TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER tag_old_events TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER calculate_time_to_display TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER disable_average_calculation TO ROLE 'AutoAdmin';
GRANT DROP ON TRIGGER enable_average_calculation TO ROLE 'AutoAdmin';
go

------------------------------------------------------------------------------
-- DISABLE THE TRIGGER GROUP primary_only FOR DISPLAY OBJECTSERVERS

ALTER TRIGGER GROUP primary_only SET ENABLED FALSE;
go



