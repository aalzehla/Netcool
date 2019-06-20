------------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2015. All Rights Reserved
--
--      US Government Users Restricted Right - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- DEVICE COUNTER
--
-- This utility simplifies the tracking of counting the number of managed devices
-- by counting unique nodes from which it receives events.  For licensing purposes,
-- monitored end points fall into one of three different types:
--
--   Network device (type 0)
--   Server device (type 1)
--   Client device (type 2)
--
--   A licensing exempt type has been created also:
--
--   Exempt devices (type 9)
--
-- The category of device will be automatically deduced based on its class.
-- A table called master.device_type is created and maintains a mapping
-- between classes and device types.  It is important to ensure that the
-- mapping is correct in this table to ensure that the monitored end-points
-- are correct in terms of device type.  Any custom classes that are added will
-- automatically be added to the master.device_type table too.  The default
-- device type assignment will be 0 - network device.  This can be updated
-- in the master.device_type table if this categorisation is not correct.
--
-- NOTE: EXEMPT CLASSES SHOULD BE SET IN master.device_types
--
-- Thereafter, events received from any nodes will cause entries to be created
-- in the table master.devices table - one row for every unique node.
-- Then, periodically, the contents of this file will be logged to file so that
-- current size of the managed environment can be determined.
--
-- This SQL file is designed to work on a Collection layer ObjectServer.  It
-- stores the Node names and Classes from Nodes it has received events from.
-- It then sends this information once every 5 minutes up to the Aggregation
-- layer embedded within a synthetic event - via NVP functions.  The
-- Aggregation layer then receives and processes these events: first: adding
-- the information to its own cache of device count information, and, second:
-- deleting the synthetic events once they have been processed.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- CREATE A CONVERSION FOR THE LICENSING EXEMPT EVENT CLASS
------------------------------------------------------------------------------

INSERT INTO alerts.conversions VALUES ('Class99990', 'Class', 99990, 'Licensing Exempt');
go

------------------------------------------------------------------------------
-- CREATE A LOG FILE FOR DEVICE COUNTS TO BE LOGGED
------------------------------------------------------------------------------

CREATE OR REPLACE FILE
	device_counter_log getenv('OMNIHOME') + '/log/' +
		getservername() + '_device_counter.log'
	maxfiles 2 maxsize 1mbytes;
go

------------------------------------------------------------------------------
-- CREATE THE master.devices TABLE
------------------------------------------------------------------------------

CREATE TABLE master.devices PERSISTENT
(
	Node			varchar(64) primary key,
	Class			int
);
go

------------------------------------------------------------------------------
-- CREATE A DEDUPLICATION TRIGGER ON THE master.devices TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_table_deduplication
GROUP default_triggers
PRIORITY 2
COMMENT 'Gracefully handles attempted deduplications into the master.devices table.'
BEFORE REINSERT ON master.devices
FOR EACH ROW
begin

	-- CANCEL ATTEMPTS TO REINSERT INTO THIS TABLE
	cancel;

end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO INSERT INTO master.devices ON INSERT INTO alerts.status
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_new_row
GROUP default_triggers
PRIORITY 2
COMMENT 'Inserts into master.devices on insert into alerts.status.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
begin

	-- SET EXEMPT CLASS FOR LOCALLY GENERATED EVENTS WHERE CLASS IS NOT SET
	if (new.Class = 0 and new.Node = get_prop_value('Hostname')) then

		set new.Class = 99990;
	end if;

	-- INSERT INTO master.devices
	insert into master.devices (
		Node,
		Class)
	values (
		new.Node,
		new.Class);
end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO INSERT INTO master.devices ON REINSERT INTO alerts.status
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_deduplication
GROUP default_triggers
PRIORITY 2
COMMENT 'Inserts into master.devices on reinsert into alerts.status.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
begin

	-- INSERT INTO master.devices
	insert into master.devices (
		Node,
		Class)
	values (
		old.Node,
		old.Class);
end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO PERIODICALLY PROCESS THE CONTENTS OF THE master.devices TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_process_table
GROUP default_triggers
PRIORITY 20
COMMENT 'Periodically process contents of master.devices table.'
EVERY 1 MINUTES
declare

	name_value_pairs char(4096);
	counter int;

begin

	-- INITIALISE VARIABLE
	set name_value_pairs = '';
	set counter = 0;

	-- PARSE OVER master.devices TABLE AND CONSTRUCT SYNTHETIC
	-- EVENT TO PASS UP TO AGGREGATION LAYER
	for each row device in master.devices
	begin

		-- STORE THE NODE
		set name_value_pairs = nvp_set(
			name_value_pairs,
			to_char(counter),
			device.Node);

		set counter = counter + 1;

		-- STORE THE CLASS OF THE NODE
		set name_value_pairs = nvp_set(
			name_value_pairs,
			to_char(counter),
			device.Class);

		set counter = counter + 1;
	end;

	-- INSERT A SYNTHETIC EVENT IF THERE ARE EVENTS RECEIVED
	if (counter != 0) then

		-- INSERT A SYNTHETIC EVENT TO HOLD THE DEVICE COUNT DETAILS
		insert into alerts.status (
			Identifier,
			Node,
			Summary,
			Class,
			Type,
			Severity,
			FirstOccurrence,
			LastOccurrence,
			Grade,
			ExpireTime,
			AlertGroup,
			OwnerUID,
			Manager,
			Agent,
			ServerName,
			ExtendedAttr)
		values (
			'device_counter_event_' + to_char(getdate()),
			getservername(),
			'Collection device counter event from ' + getservername(),
			99990,
			13,
			2,
			getdate(),
			getdate(),
			(counter - 1),
			86400,
			'Collection Device Counter',
			65534,
			'OMNIbus Collection Device Counter @' + getservername(),
			'OMNIbus Collection Device Counter',
			getservername(),
			name_value_pairs);

		-- WRITE SUMMARY TO LOG
		write into device_counter_log values (
			to_char(getdate), ': ',
			'Sent ', to_char(counter/2),
			' Nodes to the Aggregation layer for device count processing.');
	end if;

	-- CLEAN OUT THE master.devices TABLE
	delete from master.devices;
end;
go



