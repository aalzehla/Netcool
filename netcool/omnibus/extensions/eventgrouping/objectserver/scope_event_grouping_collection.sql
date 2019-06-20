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
--	This SQL file adds the fields used by the related event grouping
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- CREATE NEW FIELDS IN COLLECTION OBJECTSERVER
------------------------------------------------------------------------------

ALTER TABLE alerts.status ADD COLUMN NormalisedAlarmName VARCHAR(255);
go

ALTER TABLE alerts.status ADD COLUMN NormalisedAlarmGroup VARCHAR(255);
go

ALTER TABLE alerts.status ADD COLUMN NormalisedAlarmCode INTEGER;
go

ALTER TABLE alerts.status ADD COLUMN ScopeID VARCHAR(255);
go

ALTER TABLE alerts.status ADD COLUMN SiteName VARCHAR(255);
go

ALTER TABLE alerts.status ADD COLUMN CauseWeight INTEGER;
go

ALTER TABLE alerts.status ADD COLUMN ImpactWeight INTEGER;
go

ALTER TABLE alerts.status ADD COLUMN ParentIdentifier VARCHAR(255);
go

ALTER TABLE alerts.status ADD COLUMN TTNumber VARCHAR(64);
go

ALTER TABLE alerts.status ADD COLUMN QuietPeriod INTEGER;
go


