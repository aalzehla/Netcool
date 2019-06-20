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
-- UNSET BackupObjectServer PROPERTY

ALTER SYSTEM SET 'BackupObjectServer' = FALSE;
go

------------------------------------------------------------------------------
-- REMOVE FAILOVER/FAILBACK TRIGGER

DROP TRIGGER resend_events_on_failover;
go

------------------------------------------------------------------------------
-- REMOVE PERFORMANCE STATISTICS TRIGGERS

DROP TRIGGER timestamp_inserts;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW EXPIRE TRIGGER

DROP TRIGGER col_expire;
go

-- ENABLE THE DEFAULT EXPIRE TRIGGER

ALTER TRIGGER expire SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW REINSERT TRIGGER

DROP TRIGGER col_deduplication;
go

-- ENABLE THE DEFAULT REINSERT TRIGGER

ALTER TRIGGER deduplication SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE THE NEW INSERT TRIGGER

DROP TRIGGER col_new_row;
go

-- ENABLE THE DEFAULT INSERT TRIGGER

ALTER TRIGGER new_row SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- REMOVE NEW FIELDS IN COLLECTION OBJECTSERVER

ALTER TABLE alerts.status DROP COLUMN SentToAgg;
go

ALTER TABLE alerts.status DROP COLUMN CollectionExpireTime;
go

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

