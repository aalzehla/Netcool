------------------------------------------------------------------------------
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
--	RELATED EVENT GROUPING
--
--	This SQL file removes the fields and triggers used by the related event grouping
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- DROP TRIGGERS
------------------------------------------------------------------------------

DROP TRIGGER correlation_process_existing_parents;
go

DROP TRIGGER correlation_delete_row;
go

DROP TRIGGER correlation_update;
go

DROP TRIGGER correlation_new_row;
go

DROP TRIGGER GROUP correlation_triggers;
go

------------------------------------------------------------------------------
-- DROP INDEXES ON PARENT TABLES
------------------------------------------------------------------------------

DROP INDEX SiteNameIdentifierIdx;
go

DROP INDEX ScopeIDIdentifierIdx;
go

------------------------------------------------------------------------------
-- DROP TABLE TO STORE ScopeAlias MEMBERS
------------------------------------------------------------------------------

DELETE FROM master.correlation_scopealias_members;
go

DROP TABLE master.correlation_scopealias_members;
go

------------------------------------------------------------------------------
-- DROP TABLE TO STORE ScopeAlias ENTRIES
------------------------------------------------------------------------------

DELETE FROM master.correlation_scopealias;
go

DROP TABLE master.correlation_scopealias;
go

------------------------------------------------------------------------------
-- DROP TABLE TO STORE ScopeIDs
------------------------------------------------------------------------------

DELETE FROM master.correlation_scopeid;
go

DROP TABLE master.correlation_scopeid;
go

------------------------------------------------------------------------------
-- DROP TABLE TO STORE SiteNames
------------------------------------------------------------------------------

DELETE FROM master.correlation_sitename;
go

DROP TABLE master.correlation_sitename;
go

------------------------------------------------------------------------------
-- DELETE Properties
------------------------------------------------------------------------------

DELETE FROM master.properties where Name in ('QuietPeriod', 'PropagateTTNumber', 'PropagateAcknowledged');
go

------------------------------------------------------------------------------
-- DROP INDEXES ON alerts.status TABLE
------------------------------------------------------------------------------

DROP INDEX ParentIdentifierIdx;
go

DROP INDEX ScopeIDIdx;
go

DROP INDEX SiteNameIdx;
go

------------------------------------------------------------------------------
-- DROP NEW FIELDS IN AGGREGATION OBJECTSERVER
------------------------------------------------------------------------------

ALTER TABLE alerts.status DROP COLUMN NormalisedAlarmName;
go

ALTER TABLE alerts.status DROP COLUMN NormalisedAlarmGroup;
go

ALTER TABLE alerts.status DROP COLUMN NormalisedAlarmCode;
go

ALTER TABLE alerts.status DROP COLUMN ScopeID;
go

ALTER TABLE alerts.status DROP COLUMN SiteName;
go

ALTER TABLE alerts.status DROP COLUMN CauseWeight;
go

ALTER TABLE alerts.status DROP COLUMN ImpactWeight;
go

ALTER TABLE alerts.status DROP COLUMN ParentIdentifier;
go

ALTER TABLE alerts.status DROP COLUMN TTNumber;
go

ALTER TABLE alerts.status DROP COLUMN QuietPeriod;
go

