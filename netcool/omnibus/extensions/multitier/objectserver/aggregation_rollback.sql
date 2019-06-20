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
-- SET THE BackupObjectServer PROPERTY TO FALSE
ALTER SYSTEM SET 'BackupObjectServer' = FALSE;
go

-- DISABLE THE FAILOVER TRIGGERS (DISABLED BY DEFAULT)
alter trigger backup_counterpart_down set enabled FALSE;
alter trigger backup_counterpart_up set enabled FALSE;
alter trigger backup_startup set enabled FALSE;
go

-- DISABLE THE primary_only TRIGGER GROUP VIA THE OUT-OF-THE-BOX
-- PROCEDURE
execute automation_enable;
go

------------------------------------------------------------------------------
-- REMOVE CONVERSION FOR 9999999

DELETE FROM alerts.conversions via 'TimeToDisplay9999999';
go

------------------------------------------------------------------------------
-- REMOVE FAILBACK TRIGGERS

DROP TRIGGER resync_complete;
go

DROP TRIGGER disconnect_all_clients;
go

DROP TRIGGER resync_old_events;
go

DROP TRIGGER detect_agg_gate_resync_complete;
go

DELETE FROM alerts.resync_complete;
go

DROP TABLE alerts.resync_complete;
go

DROP TRIGGER GROUP failback_triggers;
go

------------------------------------------------------------------------------
-- REMOVE PERFORMANCE STATISTICS TRIGGER

DROP TRIGGER timestamp_inserts;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW REINSERT TRIGGER

DROP TRIGGER agg_deduplication;
go

-- ENABLE THE DEFAULT REINSERT TRIGGER

ALTER TRIGGER deduplication SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW INSERT TRIGGER

DROP TRIGGER agg_new_row;
go

-- ENABLE THE DEFAULT INSERT TRIGGER

ALTER TRIGGER new_row SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE LOAD-BALANCING FOR THE DISPLAY OBJECTSERVERS
DELETE FROM master.servergroups;
go

------------------------------------------------------------------------------
-- REMOVE NEW FIELDS IN AGGREGATION OBJECTSERVER

ALTER TABLE alerts.status DROP COLUMN CollectionFirst;
go

ALTER TABLE alerts.status DROP COLUMN AggregationFirst;
go

ALTER TABLE alerts.status DROP COLUMN DisplayFirst;
go

------------------------------------------------------------------------------
-- REMOVE ACCELERATED INSERTS

DELETE FROM iduc_system.channel WHERE Name = 'accelerated_inserts';
go

DELETE FROM iduc_system.channel_interest WHERE ChannelID = 1;
go

DELETE FROM iduc_system.channel_summary WHERE ChannelID = 1;
go

DELETE FROM iduc_system.channel_summary_cols WHERE ChannelID = 1;
go

DROP TRIGGER accelerated_inserts;
go

