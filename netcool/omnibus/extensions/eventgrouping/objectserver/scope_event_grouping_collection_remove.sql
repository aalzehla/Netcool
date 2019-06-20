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
--	This SQL file removes the fields used by the related event grouping
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- DROP NEW FIELDS IN COLLECTION OBJECTSERVER
------------------------------------------------------------------------------

ALTER TABLE alerts.status DROP COLUMN NormalisedAlarmName;
go

ALTER TABLE alerts.status DROP COLUMN NormalisedAlarmGroup;
go

ALTER TABLE alerts.status DROP COLUMN NormalisedAlarmCode;
go

ALTER TABLE alerts.status DROP COLUMN ScopeID;
go

ALTER TABLE alerts.status DROP COLUMN CauseWeight;
go

ALTER TABLE alerts.status DROP COLUMN ImpactWeight;
go

ALTER TABLE alerts.status DROP COLUMN SiteName;
go

ALTER TABLE alerts.status DROP COLUMN ParentIdentifier;
go

ALTER TABLE alerts.status DROP COLUMN TTNumber;
go

ALTER TABLE alerts.status DROP COLUMN QuietPeriod;
go

