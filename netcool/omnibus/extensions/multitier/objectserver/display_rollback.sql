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
-- ENABLE THE TRIGGER GROUP primary_only

ALTER TRIGGER GROUP primary_only SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE PERFORMANCE STATISTICS TRIGGERS

DROP TRIGGER disable_average_calculation;
go

DROP TRIGGER enable_average_calculation;
go

DROP TRIGGER calculate_time_to_display;
go

DROP TRIGGER tag_old_events;
go

DROP TRIGGER timestamp_inserts;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW REINSERT TRIGGER

DROP TRIGGER dsd_deduplication;
go

-- ENABLE THE DEFAULT REINSERT TRIGGER

ALTER TRIGGER deduplication SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW INSERT TRIGGER

DROP TRIGGER dsd_new_row;
go

-- ENABLE THE DEFAULT INSERT TRIGGER

ALTER TRIGGER new_row SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- CLEAN master.national DISPLAY OBJECTSERVER TABLE

DELETE FROM master.national;
go

------------------------------------------------------------------------------
-- REMOVE NEW FIELDS IN DISPLAY OBJECTSERVER

ALTER TABLE alerts.status DROP COLUMN CollectionFirst;
go

ALTER TABLE alerts.status DROP COLUMN AggregationFirst;
go

ALTER TABLE alerts.status DROP COLUMN DisplayFirst;
go

ALTER TABLE alerts.status DROP COLUMN TimeToDisplay;
go

