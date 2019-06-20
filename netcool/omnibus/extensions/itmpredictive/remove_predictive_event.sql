-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2010. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Drop all the prediction event triggers
------------------------------------------------------------------------
drop trigger new_row_predictive;
go

drop trigger deduplicate_predictive;
go

------------------------------------------------------------------------
-- Drop the extra columns from alerts.status
------------------------------------------------------------------------
alter table alerts.status
                drop  PredictionTime
		-- If upgrading a 7.3.0 installation comment out above line
		-- and uncomment lines below:
		-- drop DaysToWarningThreshold
		-- drop DaysToCriticalThreshold
                drop TrendDirection;
go


