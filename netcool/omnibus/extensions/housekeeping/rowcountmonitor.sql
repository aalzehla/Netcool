
------------------------------------------------------------------------------
-- INSERT HOUSEKEEPING THRESHOLD PURGE PROPERTY VALUES

-- DEFAULT THRESHOLD FOR THE alerts.status TABLE IS 100,000
insert into master.properties (Name, IntValue) values ('HKThresholdStatus', 100000);
go

-- DEFAULT THRESHOLD FOR THE alerts.journal TABLE IS 150,000
insert into master.properties (Name, IntValue) values ('HKThresholdJournal', 150000);
go

-- DEFAULT THRESHOLD FOR THE alerts.details TABLE IS 150,000
insert into master.properties (Name, IntValue) values ('HKThresholdDetails', 150000);
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER GROUP FOR THE HOUSEKEEPING TRIGGERS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER GROUP housekeeping_triggers;
go

ALTER TRIGGER GROUP housekeeping_triggers SET ENABLED FALSE;
go

-------------------------------------------------------------------
-- CREATE THE DEFAULT EVENT THRESHOLD PURGE TRIGGER

CREATE OR REPLACE TRIGGER hk_row_counter
GROUP housekeeping_triggers
ENABLED FALSE
PRIORITY 1
COMMENT 'TRIGGER hk_purge_exceeded_events
--
This trigger periodically checks the size of four key tables and
deletes data from those tables should it detect that a row threshold
has been breached.  Detection and deletion rules are on a per-table basis.
Default table thresholds:

	alerts.status - threshold: HKThresholdStatus (master.properties)
	alerts.journal - threshold: HKThresholdJournal (master.properties)
	alerts.details - threshold: HKThresholdDetails (master.properties)
'
EVERY 601 SECONDS
WHEN get_prop_value('ActingPrimary') %= 'TRUE'
declare

	statusthreshold integer;
	journalthreshold integer;
	detailsthreshold integer;
	counter integer;
	now utc;

begin

	-- INITIALISE VARIABLES
	set statusthreshold = 100000;
	set journalthreshold = 150000;
	set detailsthreshold = 150000;
	set counter = 0;
	set now = getdate();

	-- LOAD THRESHOLD PROPERTIES FROM master.properties
	for each row thresholdprop in master.properties where
		thresholdprop.Name in ('HKThresholdStatus', 'HKThresholdJournal', 'HKThresholdDetails')
	begin
		if (thresholdprop.Name = 'HKThresholdStatus') then
			set statusthreshold = thresholdprop.IntValue;
		elseif (thresholdprop.Name = 'HKThresholdJournal') then
			set journalthreshold = thresholdprop.IntValue;
		elseif (thresholdprop.Name = 'HKThresholdDetails') then
			set detailsthreshold = thresholdprop.IntValue;
		end if;
	end;

	------------------------------------------
	-- PROCESS alerts.status TABLE
	------------------------------------------

	-- COUNT NUMBER OF alerts.status EVENTS
	for each row thisrow in alerts.status
	begin

		-- INCREMENT COUNTER
		set counter = counter + 1;
	end;

	-- CARRY OUT PURGE ON alerts.status IF THRESHOLD BREACHED
	if (counter > statusthreshold) then

		------------------------------------------
		-- alerts.status REMEDIAL ACTION GOES HERE
		------------------------------------------
		-- DEFAULT:
		-- GRADUALLY LOWER SEVERITY OF EVENTS LESS THAN 5
		-- WHICH WILL EVENTUALLY RESULT IN DELETION
		-- - EXCLUDE Type 2 RESOLUTION EVENTS
		-- - EXCLUDE SELF-MONITORING EVENTS
		-- - EXCLUDE SYNTHETIC PARENT EVENTS

		-- THE BELOW SQL IS PROVIDED AS AN EXAMPLE - USE WITH CARE!

--		-- ITERATE OVER ALL TARGET EVENTS
--		for each row thisrow in alerts.status where
--			thisrow.Type != 2 and
--			thisrow.Class != 99999 and
--			thisrow.Severity in (1, 2, 3, 4) and
--			thisrow.AlertGroup  not in (
--				'SiteNameParent',
--				'ScopeIDParent',
--				'Synthetic Event - Parent')
--		begin
--
--			-- ADD A JOURNAL ENTRY TO INDICATE THE EVENT WAS
--			-- DE-ESCALATED BY THIS TRIGGER
--			EXECUTE jinsert(thisrow.Serial, 0, getdate(),
--				'Event de-escalated from ' + to_char(thisrow.Severity) +
--				' to ' + to_char(thisrow.Severity - 1) +
--				' by trigger: housekeeping_row_counter');
--
--			-- LOWER THE SEVERITY BY ONE
--			set thisrow.Severity = thisrow.Severity - 1;
--
--		end;

		------------------------------------------

		-- CREATE A SYNTHETIC ALERT TO SHOW PURGE INITIATED
		EXECUTE sm_insert(
			'OMNIbus ObjectServer : alerts.status database purge for ' +
			getservername(), get_prop_value('Hostname'), 'DBStatus', 5,
			'ALERT: alerts.status table threshold (' + to_char(statusthreshold) +
			') breached - count is: ' + to_char(counter) + ' - purge initiated',
			counter, 86400, 1);
	end if;

	------------------------------------------
	-- PROCESS alerts.journal TABLE
	------------------------------------------

	-- REINITIALISE VARIABLES
	set counter = 0;

	-- COUNT NUMBER OF alerts.journal ROWS
	for each row thisrow in alerts.journal
	begin

		-- INCREMENT COUNTER
		set counter = counter + 1;
	end;

	-- CARRY OUT PURGE ON alerts.journal IF THRESHOLD BREACHED
	if (counter > journalthreshold) then

		------------------------------------------
		-- alerts.details REMEDIAL ACTION GOES HERE
		------------------------------------------
		-- DEFAULT:
		-- DELETE JOURNALS OLDER THAN 5 DAYS (432000 SECONDS)

		-- THE BELOW SQL IS PROVIDED AS AN EXAMPLE - USE WITH CARE!

--		delete from alerts.journal where Serial in (
--			select Serial from alerts.status where Severity < 5);

		------------------------------------------

		-- CREATE A SYNTHETIC ALERT TO SHOW PURGE INITIATED
		EXECUTE sm_insert(
			'OMNIbus ObjectServer : alerts.journal database purge for ' +
			getservername(), get_prop_value('Hostname'), 'DBStatus', 5,
			'ALERT: alerts.journal table threshold (' + to_char(journalthreshold) +
			') breached - count is: ' + to_char(counter) + ' - purge initiated',
			counter, 86400, 1);
	end if;

	------------------------------------------
	-- PROCESS alerts.details TABLE
	------------------------------------------

	-- REINITIALISE VARIABLES
	set counter = 0;

	-- COUNT NUMBER OF alerts.details ROWS
	for each row thisrow in alerts.details
	begin

		-- INCREMENT COUNTER
		set counter = counter + 1;
	end;

	-- CARRY OUT PURGE ON alerts.details IF THRESHOLD BREACHED
	if (counter > detailsthreshold) then

		------------------------------------------
		-- alerts.details REMEDIAL ACTION GOES HERE
		------------------------------------------
		-- DEFAULT:
		-- DELETE ALL DETAILS FOR EVENTS LESS THAN CRITICAL IN SEVERITY

		-- THE BELOW SQL IS PROVIDED AS AN EXAMPLE - USE WITH CARE!

--		delete from alerts.details where Identifier in (
--			select Identifier from alerts.status where Severity < 5);

		------------------------------------------

		-- CREATE A SYNTHETIC ALERT TO SHOW PURGE INITIATED
		EXECUTE sm_insert(
			'OMNIbus ObjectServer : alerts.details database purge for ' +
			getservername(), get_prop_value('Hostname'), 'DBStatus', 5,
			'ALERT: alerts.details table threshold (' + to_char(detailsthreshold) +
			') breached - count is: ' + to_char(counter) + ' - purge initiated',
			counter, 86400, 1);
	end if;
end;
go

