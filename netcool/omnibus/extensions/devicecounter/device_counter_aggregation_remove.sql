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
-- DEVICE COUNTER COLLECTION REMOVAL
------------------------------------------------------------------------------

DROP TRIGGER device_counter_process_counter_events;
go

DROP TRIGGER device_counter_daily_log_count;
go

DROP PROCEDURE device_counter_log_nodes;
go

DROP TRIGGER device_counter_expire_nodes;
go

DROP TRIGGER device_counter_deduplication;
go

DROP TRIGGER device_counter_new_row;
go

DROP TRIGGER device_counter_recopy_classes_to_devices;
go

DROP PROCEDURE device_counter_copy_classes_to_devices;
go

DROP TRIGGER device_counter_table_deduplication;
go

DROP TRIGGER device_counter_types_table_deduplication;
go

DELETE FROM master.devices;
go

DROP TABLE master.devices;
go

DELETE FROM master.device_types;
go

DROP TABLE master.device_types;
go

DROP FILE device_counter_log;
go

DELETE FROM alerts.conversions where Value = 99990;
go

