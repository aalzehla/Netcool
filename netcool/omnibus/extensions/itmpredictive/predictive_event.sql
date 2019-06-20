-------------------------------------------------------------------------
--
--	Licensed Materials - Property of IBM
--
--	5724O4800
--
--	(C) Copyright IBM Corp. 2009. All Rights Reserved
--
--	US Government Users Restricted Rights - Use, duplication
--	or disclosure restricted by GSA ADP Schedule Contract
--	with IBM Corp.
--
------------------------------------------------------------------------

-- This integration configures the ObjectServer to receive Predictive Events
-- from IBM Tivoli Performance Analyzer (part of IBM Tivoli Monitoring 6.2.2).

-- Three new columns are needed:
--  - TrendDirection: what direction the predicted trend is: 0=constant, 
--    1=rising, -1=falling.
--  - PredictionTime: Time when the warning or critical thresholds defined 
--    in ITPA is expected to be violated. 
--    The severity will indicate if it is a warning or critical threshold.
alter table alerts.status 
		add TrendDirection int
		add PredictionTime time
go

-- Ensure the extra columns for Predictive Events are set on deduplication
-- and reset ExpireTime so the event expires one day after the threshold 
-- violation is expected to occur.
create trigger deduplicate_predictive
group default_triggers
priority 10
comment 'Deduplicate Predictive Event Fields'
before reinsert on alerts.status
for each row
when
	new.Class = 83900
begin
	set old.TrendDirection = new.TrendDirection;
	set old.PredictionTime = new.PredictionTime;
	set old.ExpireTime = new.PredictionTime + (24 * 3600);
end;
go
-- Ensure the ExpireTime is set correctly for new Predictvee Events so 
-- the event expires one day after the threshold violation is expected to 
-- occur.
create trigger new_row_predictive
group default_triggers
priority 10
comment 'Set expiry on new Predictive Events'
before insert on alerts.status
for each row
when
	new.Class = 89300
begin
        set new.ExpireTime = new.PredictionTime + (24 * 3600);
end;
go
