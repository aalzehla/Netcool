
------------------------------------------------------------------------------
-- INSERT HOUSEKEEPING ExpireTime PROPERTY VALUES

-- CRITICAL EVENTS EXPIRE AFTER 7 DAYS BY DEFAULT
insert into master.properties (Name, IntValue) values ('HKExpireTimeSev5', (60 * 60 * 24 * 7));
go

-- MAJOR EVENTS EXPIRE AFTER 5 DAYS BY DEFAULT
insert into master.properties (Name, IntValue) values ('HKExpireTimeSev4', (60 * 60 * 24 * 5));
go

-- MINOR EVENTS EXPIRE AFTER 3 DAYS BY DEFAULT
insert into master.properties (Name, IntValue) values ('HKExpireTimeSev3', (60 * 60 * 24 * 3));
go

-- WARNING EVENTS EXPIRE AFTER 1 DAY BY DEFAULT
insert into master.properties (Name, IntValue) values ('HKExpireTimeSev2', (60 * 60 * 24 * 1));
go

-- INDETERMINITE EVENTS EXPIRE AFTER 4 HOURS BY DEFAULT
insert into master.properties (Name, IntValue) values ('HKExpireTimeSev1', (60 * 60 * 4));
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER GROUP FOR THE HOUSEKEEPING TRIGGERS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER GROUP housekeeping_triggers;
go

ALTER TRIGGER GROUP housekeeping_triggers SET ENABLED FALSE;
go

-------------------------------------------------------------------
-- CREATE A DEFAULT EXPIRATION TRIGGER

CREATE OR REPLACE TRIGGER hk_set_expiretime
GROUP housekeeping_triggers
ENABLED FALSE
PRIORITY 1
COMMENT 'TRIGGER hk_set_expiretime
--
This trigger sets the ExpireTime field for all events where it is
not yet set.  It works in conjunction with the default expire
trigger to provide an automated event expiry mechanism.
Default expiry thresholds:

Critical events - threshold: HKExpireTimeSev5 (master.properties)
Major events - threshold: HKExpireTimeSev4 (master.properties)
Minor events - threshold: HKExpireTimeSev3 (master.properties)
Warning events - threshold: HKExpireTimeSev2 (master.properties)
Indeterminate events - threshold: HKExpireTimeSev1 (master.properties)

Clear events are to be ignored by this trigger.
'
EVERY 599 SECONDS
WHEN get_prop_value('ActingPrimary') %= 'TRUE'
declare

	expiretimesev5 integer;
	expiretimesev4 integer;
	expiretimesev3 integer;
	expiretimesev2 integer;
	expiretimesev1 integer;
	counter integer;

begin

	-- INITIALISE VARIABLES TO DEFAULTS
	set expiretimesev5 = 60 * 60 * 24 * 7; -- 7 DAYS
	set expiretimesev4 = 60 * 60 * 24 * 5; -- 5 DAYS
	set expiretimesev3 = 60 * 60 * 24 * 3; -- 3 DAYS
	set expiretimesev2 = 60 * 60 * 24 * 1; -- 1 DAY
	set expiretimesev1 = 60 * 60 * 4; -- 4 HOURS
	set counter = 0;

	-- LOAD ExpireTime PROPERTIES FROM master.properties
	for each row expiretimeprop in master.properties where
		expiretimeprop.Name in (
			'HKExpireTimeSev5', 'HKExpireTimeSev4', 'HKExpireTimeSev3',
			'HKExpireTimeSev2', 'HKExpireTimeSev1')
	begin
		if (expiretimeprop.Name = 'HKExpireTimeSev5') then
			set expiretimesev5 = expiretimeprop.IntValue;
		elseif (expiretimeprop.Name = 'HKExpireTimeSev4') then
			set expiretimesev4 = expiretimeprop.IntValue;
		elseif (expiretimeprop.Name = 'HKExpireTimeSev3') then
			set expiretimesev3 = expiretimeprop.IntValue;
		elseif (expiretimeprop.Name = 'HKExpireTimeSev2') then
			set expiretimesev2 = expiretimeprop.IntValue;
		elseif (expiretimeprop.Name = 'HKExpireTimeSev1') then
			set expiretimesev1 = expiretimeprop.IntValue;
		end if;
	end;

	-- FIND ROWS WHERE ExpireTime IS NOT YET SET AND SET ExpireTime
	-- BASED ON EVENT SEVERITY - IGNORE CLEARED EVENTS - IGNORE SYNTHETIC PARENT EVENTS
	for each row unexpired in alerts.status where
		unexpired.ExpireTime = 0 and
		unexpired.Severity != 0 and
		unexpired.AlertGroup not in ('SiteNameParent', 'ScopeIDParent', 'Synthetic Event - Parent')
	begin
		-- CRITICAL EVENTS:
		if (unexpired.Severity = 5) then
			set unexpired.ExpireTime = expiretimesev5;
		-- MAJOR EVENTS:
		elseif (unexpired.Severity = 4) then
			set unexpired.ExpireTime = expiretimesev4;
		-- MINOR EVENTS:
		elseif (unexpired.Severity = 3) then
			set unexpired.ExpireTime = expiretimesev3;
		-- WARNING EVENTS:
		elseif (unexpired.Severity = 2) then
			set unexpired.ExpireTime = expiretimesev2;
		-- INDETERMINATE EVENTS:
		elseif (unexpired.Severity = 1) then
			set unexpired.ExpireTime = expiretimesev1;
		end if;

		-- INCREMENT COUNTER
		set counter = counter + 1;
	end;

	-- ADD LOGGING INFORMATION AND SYNTHETIC EVENT
	if (counter != 0) then

		-- ADD A LOG ENTRY TO SELF-MONITORING
		call procedure sm_log('Housekeeping: setting ExpireTime for ' +
			to_char(counter) + ' unset events');

		-- CREATE A SYNTHETIC ALERT TO SHOW PURGE INITIATED
		call procedure sm_insert(
			'OMNIbus ObjectServer : set ExpireTime for unset events for ' +
			getservername(), get_prop_value('Hostname'), 'DBStatus', 2,
			'Housekeeping: setting ExpireTime for ' + to_char(counter) + ' unset events',
			counter, 600, 1);
	end if;
end;
go

