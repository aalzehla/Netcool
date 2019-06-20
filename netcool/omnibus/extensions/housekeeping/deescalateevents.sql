
------------------------------------------------------------------------------
-- INSERT HOUSEKEEPING ExpireTime PROPERTY VALUES

-- LOWER CRITICAL EVENTS TO MAJOR AFTER 7 DAYS - DEFAULT
insert into master.properties (Name, IntValue) values ('HKDeescalateSev5', (60 * 60 * 24 * 7));
go

-- LOWER MAJOR EVENTS TO MINOR AFTER 8 DAYS - DEFAULT
insert into master.properties (Name, IntValue) values ('HKDeescalateSev4', (60 * 60 * 24 * 8));
go

-- LOWER MINOR EVENTS TO WARNING AFTER 9 DAYS - DEFAULT
insert into master.properties (Name, IntValue) values ('HKDeescalateSev3', (60 * 60 * 24 * 9));
go

-- LOWER WARNING EVENTS TO INDETERMINATE AFTER 10 DAYS - DEFAULT
insert into master.properties (Name, IntValue) values ('HKDeescalateSev2', (60 * 60 * 24 * 10));
go

-- LOWER INDETERMINATE EVENTS TO CLEAR AFTER 11 DAYS - DEFAULT
insert into master.properties (Name, IntValue) values ('HKDeescalateSev1', (60 * 60 * 24 * 11));
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER GROUP FOR THE HOUSEKEEPING TRIGGERS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER GROUP housekeeping_triggers;
go

ALTER TRIGGER GROUP housekeeping_triggers SET ENABLED FALSE;
go

-------------------------------------------------------------------
-- CREATE A DE-ESCALATION TRIGGER

CREATE OR REPLACE TRIGGER hk_de_escalate_events
GROUP housekeeping_triggers
ENABLED FALSE
PRIORITY 1
COMMENT 'TRIGGER hk_de_escalate_events
--
This trigger periodically checks the time since the last occurrence of events.
An event\'s severity is reduced by 1 each time it is de-escalated.
Events of these severities will gradually de-escalate over time until they are cleared.
Default event de-escalation thresholds:

	Severity 5 - threshold: HKDeescalateSev5 (master.properties)
	Severity 4 - threshold: HKDeescalateSev4 (master.properties)
	Severity 3 - threshold: HKDeescalateSev3 (master.properties)
	Severity 2 - threshold: HKDeescalateSev2 (master.properties)
	Severity 1 - threshold: HKDeescalateSev1 (master.properties)

IMPORTANT: a threshold of zero means the automation should do nothing with this event
'
EVERY 607 SECONDS
WHEN get_prop_value('ActingPrimary') %= 'TRUE'
declare

	deescalatesev5 integer;
	deescalatesev4 integer;
	deescalatesev3 integer;
	deescalatesev2 integer;
	deescalatesev1 integer;
	shortestdeescperiod integer;
	counter integer;
	now utc;

begin
	-- INITIALISE VARIABLES TO DEFAULTS
	set deescalatesev5 = 60 * 60 * 24 * 7; -- 7 DAYS
	set deescalatesev4 = 60 * 60 * 24 * 8; -- 8 DAYS
	set deescalatesev3 = 60 * 60 * 24 * 9; -- 9 DAYS
	set deescalatesev2 = 60 * 60 * 24 * 10; -- 10 DAYS
	set deescalatesev1 = 60 * 60 * 24 * 11; -- 11 DAYS
	set shortestdeescperiod = 0;
	set counter = 0;
	set now = getdate();

	-- LOAD DEESCALATE PROPERTIES FROM master.properties
	for each row deescalateprop in master.properties where
		deescalateprop.Name like ('HKDeescalateSev')
	begin
		if (deescalateprop.Name = 'HKDeescalateSev5') then
			set deescalatesev5 = deescalateprop.IntValue;
		elseif (deescalateprop.Name = 'HKDeescalateSev4') then
			set deescalatesev4 = deescalateprop.IntValue;
		elseif (deescalateprop.Name = 'HKDeescalateSev3') then
			set deescalatesev3 = deescalateprop.IntValue;
		elseif (deescalateprop.Name = 'HKDeescalateSev2') then
			set deescalatesev2 = deescalateprop.IntValue;
		elseif (deescalateprop.Name = 'HKDeescalateSev1') then
			set deescalatesev1 = deescalateprop.IntValue;
		end if;

		-- STORE SHORTEST DEESCALATION PERIOD
		if (shortestdeescperiod = 0 or shortestdeescperiod > deescalateprop.IntValue) then

			set shortestdeescperiod = deescalateprop.IntValue;
		end if;
	end;

	-- ONLY PROCESS EVENTS OLDER THAN THE SHORTEST DEESCALATION PERIOD
	-- EXCLUDE Type 2 RESOLUTION EVENTS
	-- EXCLUDE Parent EVENTS
	for each row thisrow in alerts.status where
		thisrow.Type != 2 and
		thisrow.LastOccurrence < (now - shortestdeescperiod) and
		thisrow.AlertGroup  not in ('SiteNameParent', 'ScopeIDParent', 'Synthetic Event - Parent')
	begin

		-- CHECK SEVERITY 5 EVENTS OLDER THAN HKDeescalateSev5 THRESHOLD
		if (thisrow.Severity = 5 and deescalatesev5 != 0 and
			thisrow.LastOccurrence < (now - deescalatesev5)) then

			-- DE-ESCALATE EVENT SEVERITY BY 1
			set thisrow.Severity = 4;

			-- ADD A JOURNAL ENTRY TO INDICATE THE EVENT WAS
			-- DE-ESCALATED BY THIS TRIGGER
			EXECUTE jinsert(thisrow.Serial, 0, getdate(),
				'Event de-escalated from 5 to 4 by trigger: hk_de_escalate_events');

			-- INCREMENT COUNTER
			set counter = counter + 1;

		-- CHECK SEVERITY 4 EVENTS OLDER THAN HKDeescalateSev4 THRESHOLD
		elseif (thisrow.Severity = 4 and deescalatesev4 != 0 and
			thisrow.LastOccurrence < (now - deescalatesev4)) then

			-- DE-ESCALATE EVENT SEVERITY BY 1
			set thisrow.Severity = 3;

			-- ADD A JOURNAL ENTRY TO INDICATE THE EVENT WAS
			-- DE-ESCALATED BY THIS TRIGGER
			EXECUTE jinsert(thisrow.Serial, 0, getdate(),
				'Event de-escalated from 4 to 3 by trigger: hk_de_escalate_events');

			-- INCREMENT COUNTER
			set counter = counter + 1;

		-- CHECK SEVERITY 3 EVENTS OLDER THAN HKDeescalateSev3 THRESHOLD
		elseif (thisrow.Severity = 3 and deescalatesev3 != 0 and
			thisrow.LastOccurrence < (now - deescalatesev3)) then

			-- DE-ESCALATE EVENT SEVERITY BY 1
			set thisrow.Severity = 2;

			-- ADD A JOURNAL ENTRY TO INDICATE THE EVENT WAS
			-- DE-ESCALATED BY THIS TRIGGER
			EXECUTE jinsert(thisrow.Serial, 0, getdate(),
				'Event de-escalated from 3 to 2 by trigger: hk_de_escalate_events');

			-- INCREMENT COUNTER
			set counter = counter + 1;

		-- CHECK SEVERITY 2 EVENTS OLDER THAN HKDeescalateSev2 THRESHOLD
		elseif (thisrow.Severity = 2 and deescalatesev2 != 0 and
			thisrow.LastOccurrence < (now - deescalatesev2)) then

			-- DE-ESCALATE EVENT SEVERITY BY 1
			set thisrow.Severity = 1;

			-- ADD A JOURNAL ENTRY TO INDICATE THE EVENT WAS
			-- DE-ESCALATED BY THIS TRIGGER
			EXECUTE jinsert(thisrow.Serial, 0, getdate(),
				'Event de-escalated from 2 to 1 by trigger: hk_de_escalate_events');

			-- INCREMENT COUNTER
			set counter = counter + 1;

		-- CHECK SEVERITY 1 EVENTS OLDER THAN HKDeescalateSev1 THRESHOLD
		elseif (thisrow.Severity = 1 and deescalatesev1 != 0 and
			thisrow.LastOccurrence < (now - deescalatesev1)) then

			-- DE-ESCALATE EVENT SEVERITY BY 1
			set thisrow.Severity = 0;

			-- ADD A JOURNAL ENTRY TO INDICATE THE EVENT WAS
			-- DE-ESCALATED BY THIS TRIGGER
			EXECUTE jinsert(thisrow.Serial, 0, getdate(),
				'Event de-escalated from 1 to 0 by trigger: hk_de_escalate_events');

			-- INCREMENT COUNTER
			set counter = counter + 1;
		end if;
	end;

	-- ADD LOGGING INFORMATION AND SYNTHETIC EVENT
	if (counter != 0) then

		-- ADD A LOG ENTRY TO SELF-MONITORING
		EXECUTE sm_log('Housekeeping: reducing Severity of ' +
			to_char(counter) + ' old events');

		-- CREATE A SYNTHETIC ALERT TO SHOW PURGE INITIATED
		EXECUTE sm_insert(
			'OMNIbus ObjectServer : reducing Severity for old events for ' +
			getservername(), get_prop_value('Hostname'), 'DBStatus', 2,
			'Housekeeping: reducing Severity of ' + to_char(counter) + ' old events',
			counter, 600, 1);
	end if;
end;
go

