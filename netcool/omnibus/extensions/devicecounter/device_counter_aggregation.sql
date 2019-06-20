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
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- CREATE A CONVERSION FOR THE LICENSING EXEMPT EVENT CLASS
------------------------------------------------------------------------------

INSERT INTO alerts.conversions VALUES ('Class99990', 'Class', 99990, 'Licensing Exempt');
go

------------------------------------------------------------------------------
-- CREATE A LOG FILE FOR THE DEVICE COUNTS TO BE LOGGED
------------------------------------------------------------------------------

CREATE OR REPLACE FILE
	device_counter_log getenv('OMNIHOME') + '/log/' +
		getservername() + '_device_counter.log'
	maxfiles 2 maxsize 1mbytes;
go

------------------------------------------------------------------------------
-- CREATE THE master.device_types TABLE
------------------------------------------------------------------------------

CREATE TABLE master.device_types PERSISTENT
(
	Class			int primary key,
	Conversion		varchar(255),
	DeviceType		int
);
go

------------------------------------------------------------------------------
-- CREATE THE master.devices TABLE
------------------------------------------------------------------------------

CREATE TABLE master.devices PERSISTENT
(
	Node			varchar(64) primary key,
	Class			int,
	DeviceType		int,
	LastReceived		time
);
go

------------------------------------------------------------------------------
-- CREATE A DEDUPLICATION TRIGGER ON THE master.device_types TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_types_table_deduplication
GROUP default_triggers
PRIORITY 2
COMMENT 'Gracefully handles attempted deduplications into the master.device_types table.'
BEFORE REINSERT ON master.device_types
FOR EACH ROW
begin

	-- CANCEL ATTEMPTS TO REINSERT INTO THIS TABLE
	cancel;

end;
go

------------------------------------------------------------------------------
-- CREATE A DEDUPLICATION TRIGGER ON THE master.devices TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_table_deduplication
GROUP default_triggers
PRIORITY 2
COMMENT 'Update the last received timestamp on deduplication in the master.devices table.'
BEFORE REINSERT ON master.devices
FOR EACH ROW
begin

	-- UPDATE THE LastReceived TIMESTAMP ON DEDUPLICATION
	set old.LastReceived = new.LastReceived;

end;
go

------------------------------------------------------------------------------
-- CREATE PROCEDURE TO COPY CLASSES TO master.device_types TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE device_counter_copy_classes_to_devices ( )
begin

	-- THIS PROCEDURE WILL COPY ALL REGISTERED CLASSES TO THE
	-- master.device_types TABLE WITH A DEFAULT TYPE OF 0

	for each row ThisRow in alerts.conversions where
		ThisRow.Colname = 'Class'
	begin

		insert into master.device_types (
			Class,
			Conversion,
			DeviceType)
		values (
			ThisRow.Value,
			ThisRow.Conversion,
			0);
	end;
end;
go

------------------------------------------------------------------------------
-- EXECUTE THE PROCEDURE TO DO AN INITIAL COPY TO THE master.device_types TABLE
------------------------------------------------------------------------------

EXECUTE device_counter_copy_classes_to_devices;
go

------------------------------------------------------------------------------
-- UPDATE CERTAIN KEY CLASSES TO BE EXEMPT FROM LICENSING ACTIVITIES
--
--   3300 Simnet
--  10500 Impact self monitoring
--  99990 Licensing exempt events
--  99999 OMNIbus self monitoring
--
------------------------------------------------------------------------------

UPDATE master.device_types SET DeviceType = 9 where Class in (
	3300,
	10500,
	99990,
	99999);
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO PERIODICALLY COPY NEW CLASSES TO THE master.device_types TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_recopy_classes_to_devices 
GROUP default_triggers
PRIORITY 20
COMMENT 'Recopy classes to the device_types table after creation of a new class.'
AFTER INSERT ON alerts.conversions
FOR EACH ROW
begin

	-- RECOPY CLASSES TO master.device_types TABLE
	EXECUTE device_counter_copy_classes_to_devices;

end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO INSERT INTO master.devices ON INSERT INTO alerts.status
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_new_row
GROUP default_triggers
PRIORITY 20
COMMENT 'Inserts into master.devices on insert into alerts.status.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
declare

	device_type int;
begin

	-- INITIALISE VARIABLE
	set device_type = 0;

	-- SET EXEMPT CLASS FOR LOCALLY GENERATED EVENTS WHERE CLASS IS NOT SET
	if (new.Class = 0 and new.Node = get_prop_value('Hostname')) then

		set new.Class = 99990;
	end if;

	-- LOCATE DEVICE TYPE IN master.device_types TABLE
	for each row DeviceRow in master.device_types where
		DeviceRow.Class = new.Class
	begin

		-- SET device_type
		set device_type = DeviceRow.DeviceType;
	end;

	-- ONLY INSERT NON-EXEMPT TYPES
	if (device_type != 9) then

		-- INSERT INTO master.devices
		insert into master.devices (
			Node,
			Class,
			DeviceType,
			LastReceived)
		values (
			new.Node,
			new.Class,
			device_type,
			getdate());
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO INSERT INTO master.devices ON REINSERT INTO alerts.status
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_deduplication
GROUP default_triggers
PRIORITY 20
COMMENT 'Inserts into master.devices on reinsert into alerts.status.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
declare

	device_type int;
begin

	-- INITIALISE VARIABLE
	set device_type = 0;

	-- LOCATE DEVICE TYPE IN master.device_types TABLE
	for each row DeviceRow in master.device_types where
		DeviceRow.Class = old.Class
	begin

		-- SET device_type
		set device_type = DeviceRow.DeviceType;
	end;

	-- ONLY INSERT NON-EXEMPT TYPES
	if (device_type != 9) then

		-- INSERT INTO master.devices
		insert into master.devices (
			Node,
			Class,
			DeviceType,
			LastReceived)
		values (
			new.Node,
			new.Class,
			device_type,
			getdate());
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO PERIODICALLY EXPIRE ROWS FROM THE master.devices TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_expire_nodes
GROUP default_triggers
PRIORITY 20
COMMENT 'Periodically expire device nodes from master.devices.'
EVERY 24 HOURS
begin

	-- DELETE EXPIRED NODES FROM master.devices
	-- NODES WILL BE DELETED IF NO EVENT HAS BEEN RECEIVED
	-- FOR OVER 1 YEAR

	delete from master.devices where
		LastReceived < (getdate() - 31536000);

end;
go

------------------------------------------------------------------------------
-- CREATE PROCEDURE TO LOG DEVICE COUNT INFORMATION
------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE device_counter_log_nodes ( )
declare

	num_network_devices int;
	num_server_devices int;
	num_client_devices int;

begin

	-- INITIALISE VARIABLES
	set num_network_devices = 0;
	set num_server_devices = 0;
	set num_client_devices = 0;

	-- COUNT UP DIFFERENT DEVICES TYPES
	for each row DeviceRow in master.devices
	begin

		if (DeviceRow.DeviceType = 0) then

			set num_network_devices = num_network_devices + 1;

		elseif (DeviceRow.DeviceType = 1) then

			set num_server_devices = num_server_devices + 1;

		elseif (DeviceRow.DeviceType = 2) then

			set num_client_devices = num_client_devices + 1;
		end if;
	end;

	write into device_counter_log values (
		to_char(getdate), ': ',
		'Network devices: ', to_char(num_network_devices), ', ',
		'Server devices: ', to_char(num_server_devices), ', ',
		'Client devices: ', to_char(num_client_devices));

end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO PERIODICALLY WRITE DEVICE COUNT INFORMATION TO LOG
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_daily_log_count
GROUP default_triggers
PRIORITY 20
COMMENT 'Daily write to log a summary of counts of device types.'
EVERY 24 HOURS
begin

	-- LOG DEVICE COUNTS TO FILE
	EXECUTE device_counter_log_nodes;

end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO PERIODICALLY PROCESS DEVICE COUNT EVENTS FROM COLLECTION
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER device_counter_process_counter_events
GROUP default_triggers
PRIORITY 20
COMMENT 'Periodically process the event counter events received from the Collection layer.'
EVERY 5 MINUTES
declare

	counter int;
	thisnode char(64);
	thisclass int;
	device_type int;

begin

	-- PROCESS ANY DEVICE COUNT EVENTS PRESENT
	for each row device_event in alerts.status where
		device_event.AlertGroup = 'Collection Device Counter'
	begin

		-- ITERATE OVER STORED DEVICE COUNTS
		for counter = 0 to device_event.Grade do
		begin

			-- ONLY PROCESS EVERY EVEN ENTRY
			if (mod(counter, 2) = 0) then

				-- SELECT NODE
				set thisnode = nvp_get(device_event.ExtendedAttr,
					to_char(counter));

				-- SELECT CLASS
				set thisclass = to_int(nvp_get(device_event.ExtendedAttr,
					to_char(counter + 1)));

				-- INITIALISE DEVICE TYPE
				set device_type = 0;

				-- LOCATE DEVICE TYPE IN master.device_types TABLE
				for each row DeviceRow in master.device_types where
					DeviceRow.Class = thisclass
				begin

					-- SET device_type
					set device_type = DeviceRow.DeviceType;
				end;

				-- ONLY INSERT NON-EXEMPT TYPES
				if (device_type != 9) then

					-- INSERT INTO master.devices
					insert into master.devices (
						Node,
						Class,
						DeviceType,
						LastReceived)
					values (
						thisnode,
						thisclass,
						device_type,
						getdate());
				end if;
			end if;
		end;
	end;

	-- DELETE PROCESSED DEVICE COUNT EVENTS
	delete from alerts.status where AlertGroup = 'Collection Device Counter';
end;
go



