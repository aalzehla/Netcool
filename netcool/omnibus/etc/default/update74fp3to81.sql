-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2014. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SQL file contains schema, data and automation changes to be applied
-- to a 7.4.0 ObjectServer instance to bring it up to v8.0
--
--  The contents of this file should be reviewed prior to adding it to
--  the ObjectServer.
--  Applying this file may cause automations to be replaced, meaning
--  any customization of the automations will be lost
--
--  Prior to applying this file, it is advisable to backup your
--  ObjectServer instance
--
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Registry database: Remove virtual probe registry.
----------------------------------------------------------------------
drop trigger registry_new_probe;
go

drop trigger registry_reinsert_probe;
go

drop trigger registry_probe_disconnect;
go

drop trigger registry_cleanup_probes;
go

delete from registry.probes;
go

drop table registry.probes;
go

----------------------------------------------------------------------
-- Registry database: Create persistent probe registry.
----------------------------------------------------------------------
create table registry.probes persistent
(
	-- Columns populated by probe
        Name            varchar(128) primary key,  -- Size of catalog.connection.AppDescription
	Hostname	varchar(64) primary key,   -- Size of alerts.status.Node

	HTTP_port       int,                       -- The ports that can be used to communicate
	HTTPS_port      int,                       -- with the probe.

	PID		int,                       -- Process ID
	Status		int,                       -- 0=dead, 1=running
	StartTime	time,                      -- Time probe started running.

	RulesChecksum	char(40),                  -- Rules File aggregate checksum
	ProbeType       varchar(128),
	ApiVersion	varchar(20),               -- Probe API product version
	ApiReleaseID	varchar(20),               -- Probe API release ID

	-- Columns populated by ObjectServer Triggers
	ConnectionID	int,                       -- ObjectServer connection ID, 0 =  not connected
	LastUpdate	time                       -- time of most recent update
);
go

----------------------------------------------------------------------
-- Registry database: trigger updates.
----------------------------------------------------------------------

create or replace trigger registry_new_probe
group registry_triggers
enabled true
priority 10
comment 'Set defaults for new entry in REGISTRY.PROBES'
before insert on registry.probes
for each row
begin
if (%user.app_name = 'PROBE') or (%user.app_name = 'PROXY') then
	set new.ConnectionID = %user.connection_id;
end if;
if (%user.app_name != 'GATEWAY') then
	set new.LastUpdate = getdate;
end if;
end;
go

create or replace trigger registry_probe_disconnect
group registry_triggers
enabled true
priority 10
comment 'Reset ConnectionID in probe registry when probe or proxy server disconnects.'
on signal disconnect
begin
	if (%signal.process = 'PROBE') then
		update registry.probes set ConnectionID = 0, LastUpdate = getdate
			where ConnectionID = %signal.connectionid;
	-- proxy server shuffles probe connections dynamically.
	-- Unsafe to reset probes that have not stopped.
	elseif (%signal.process = 'PROXY') then
		update registry.probes set ConnectionID = 0, LastUpdate = getdate
			where ConnectionID = %signal.connectionid
			 and  Status = 0;
	end if;
end;
go

create or replace trigger registry_reinsert_probe
group registry_triggers
enabled true 
priority 10
comment 'Treat inserts to existing PROBE.REGISTRY entry as though they were updates. Time stamp the record to keep track of the last time this entry was updated. Only probes directly connected, or connected via a proxy server, as well as gateways are allowed to re-insert into the table. Other applications must use UPDATE to modify the probe registry.'
before reinsert on registry.probes
for each row
begin
	if (%user.app_name = 'PROBE') or
	   (%user.app_name = 'PROXY') then
		set row old = new; 
		set old.ConnectionID = %user.connection_id;
		set old.LastUpdate = getdate;
	elseif (%user.app_name = 'GATEWAY') and
	       (new.LastUpdate > old.LastUpdate) then
		-- Only update the registry if the reinsert is more recent
		set row old = new;
	else
		cancel;
	end if;
end;
go

create or replace trigger registry_update_probe
group registry_triggers
enabled true 
priority 10
comment 'Set the LastUpdate column for updates coming from all clients except gateways. Only permit updates from gateways if the LastUpdate time is more recent than the existing entry'
before update on registry.probes
for each row
begin
	if (%user.app_name != 'GATEWAY') then
		set new.LastUpdate = getdate();
	elseif (new.LastUpdate < old.LastUpdate) then
		cancel;
	end if;
end;
go

----------------------------------------------------------------------
-- Registry database: security updates.
------------------------------------------------------------------------
grant insert on table registry.probes to role 'RegisterProbe';
grant update on table registry.probes to role 'RegisterProbe';
grant select on table registry.probes to role 'RegistryReader';
grant insert on table registry.probes to role 'RegistryAdmin';
grant update on table registry.probes to role 'RegistryAdmin';
grant select on table registry.probes to role 'RegistryAdmin';
grant delete on table registry.probes to role 'RegistryAdmin';
grant alter on table registry.probes to role 'DatabaseAdmin';
grant drop on table registry.probes to role 'DatabaseAdmin';
grant create index on table registry.probes to role 'DatabaseAdmin';
grant drop index on table registry.probes to role 'DatabaseAdmin';
grant role 'RegistryAdmin' to group 'Gateway';
go

----------------------------------------------------------------------
-- New and updated Conversions
----------------------------------------------------------------------
INSERT INTO alerts.conversions VALUES ( 'Class99999', 'Class', 99999, 'SelfMonitoring');
INSERT INTO alerts.conversions VALUES ( 'NmosManagedStatus4','NmosManagedStatus',4,'Undiscovered interface' );
go

----------------------------------------------------------------------
-- New KPI for updates to alerts.status rows
----------------------------------------------------------------------
-- Add StatusUpdates column to master.stats table

ALTER TABLE master.stats ADD COLUMN StatusUpdates int; 
go

-- Add StatusUpdates column to master.activity_stats table

ALTER TABLE master.activity_stats ADD COLUMN StatusUpdates int; 
go

-- New triggers which utilise/store the new data

--
-- Database trigger to count status table updates
--
create or replace trigger status_updates
group stats_triggers
priority 20
comment 'Counts status table updates'
after update on alerts.status
for each row
begin
	update master.activity_stats via 'alerts' set StatusUpdates = StatusUpdates + 1;
end;
go

--
-- Signal trigger that handles the raising of the
-- statistics reset signal
--
create or replace trigger stats_reset
group stats_triggers
priority 1
comment 'Reset the statistics data'
on signal stats_reset
begin
	delete from master.stats;
	delete from master.activity_stats;
	insert into master.activity_stats values( 'alerts', 0, 0, 0, 0, 0 );
end;
go

--
-- Trigger to create statistics
--
create or replace trigger statistics_gather
group stats_triggers
priority 20
comment 'Create some v3.x ObjectServer statistics'
every 300 seconds
declare	clients		int;
	realtimes	int;
	probes		int;
	gateways	int;
	monitors	int;
	proxys		int;
	ecount		int;
	jcount		int;
	dcount		int;
	sinserts	int;
	sninserts	int;
	sdedups		int;
	jinserts	int;
	dinserts	int;
	supdates	int;
begin
	-- Initialise counters
	set clients = 0;
	set realtimes = 0;
	set probes = 0;
	set gateways = 0;
	set monitors = 0;
	set proxys = 0;
	set ecount = 0;
	set jcount = 0;
	set dcount = 0;

	-- Get number of clients
	for each row srow in catalog.connections
	begin
		set clients = clients + 1;
	end;

	-- Get number of realtime clients
	for each row srow in catalog.connections where srow.IsRealTime = true
	begin
		set realtimes = realtimes + 1;
	end;

	-- Get number of probes
	for each row srow in catalog.connections where srow.AppName = 'PROBE'
	begin
		set probes = probes + 1;
	end;

	-- Get number of Gateways
	for each row srow in catalog.connections where srow.AppName = 'GATEWAY'
	begin
		set gateways = gateways + 1;
	end;

	-- Get number of monitors
	for each row srow in catalog.connections where srow.AppName = 'MONITOR'
	begin
		set monitors = monitors + 1;
	end;

	-- Get number of proxies
	for each row srow in catalog.connections where srow.AppName = 'PROXY'
	begin
		set proxys = proxys + 1;
	end;

	-- Get number of rows in alerts.status
	for each row srow in alerts.status
	begin
		set ecount = ecount + 1;
	end;

	-- Get number of rows in alerts.journal
	for each row srow in alerts.journal
	begin
		set jcount = jcount + 1;
	end;

	-- Get number of rows in alerts.details
	for each row srow in alerts.details
	begin
		set dcount = dcount + 1;
	end;

	-- Get status/journal/details table activity statistics.
	for each row srow in master.activity_stats where srow.DatabaseName = 'alerts'
	begin
		set sinserts = srow.StatusNewInserts + srow.StatusDedups;
		set sninserts = srow.StatusNewInserts;
		set sdedups = srow.StatusDedups;
		set jinserts = srow.JournalInserts;
		set dinserts = srow.DetailsInserts;
		set supdates = srow.StatusUpdates;
	end;

	-- Insert a stats row
	insert into master.stats values( getdate(), clients, realtimes, probes, gateways, monitors, proxys, ecount, jcount, dcount, sinserts, sninserts, sdedups, jinserts, dinserts, supdates );
end;
go

----------------------------------------------------------------------
-- OMNIbus Self Monitoring
----------------------------------------------------------------------
------------------------------------------------------------------------------
-- ENABLE THE stats_triggers GROUP AS IT IS REQUIRED FOR SELF MONITORING FUNCTIONALITY
------------------------------------------------------------------------------
ALTER TRIGGER GROUP stats_triggers SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- Delete statistic that are over 120 days old
------------------------------------------------------------------------------
create or replace trigger delete_stats
group stats_triggers
priority 20
comment 'keep up to 120 days of records in the master.stats table'
every 24 hours
declare
days_data int;
begin
        -- Keep 120 days of data
	-- Modify this to reduce / increase the number
	set days_data = 86400*120;
	delete from master.stats where StatTime < (getdate - days_data);
end;
go


------------------------------------------------------------------------------
-- CREATE A FILE FOR SELF MONITORING METRICS TO BE LOGGED TO
------------------------------------------------------------------------------
CREATE OR REPLACE FILE
	self_monitoring getenv('OMNIHOME') + '/log/' + getservername() + '_selfmonitoring.log'
	maxfiles 2 maxsize 1mbytes;

------------------------------------------------------------------------------
-- CREATE A TRIGGER GROUP FOR THE SELF MONITORING EVENT CLASS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER GROUP self_monitoring_group;
go

ALTER TRIGGER GROUP self_monitoring_group SET ENABLED TRUE;
go

------------------------------------------------------------------------------
-- CREATE A HOLDING TABLE FOR THE LAST STATS REPORT TIMESTAMPS
------------------------------------------------------------------------------
CREATE TABLE master.sm_activity PERSISTENT
(
	ReportTrigger		char(255) primary key,
	ProbeStatsLastSeqNos	int,
	MasterStatsLast		time
);
go

INSERT INTO master.sm_activity VALUES ('sm_db_stats', 1, 0);
go

INSERT INTO master.sm_activity VALUES ('sm_dbops_stats', 1, 0);
go


INSERT INTO master.sm_activity VALUES ('sm_connections', 1, 0);
go

------------------------------------------------------------------------------
-- CREATE A TABLE FOR THE SYNTHETIC EVENT SEVERITY THRESHOLDS
------------------------------------------------------------------------------
CREATE TABLE master.sm_thresholds PERSISTENT
(
        ThresholdName           char(64) primary key,
	DisplayName		char(64),
	Sev1			int,
	Sev2			int,
	Sev3			int,
	Sev4			int,
	Sev5			int,
	EnableInfo		int,
	DeduplicateInfo		int
);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_memstore

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_memstore', 'SM Memstore', 0, 0, 75, 85, 95, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_triggers

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_triggers_individual', 'SM Triggers Individual', 0, 0, 20, 25, 30, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_triggers_total', 'SM Triggers Total', 0, 0, 50, 70, 90, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_triggers_reporting_period', 'SM Triggers Reporting Period', 0, 0, 61, 70, 90, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_client_time

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_client_time_individual', 'SM Client Time Individual', 0, 0, 30, 40, 50, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_client_time_total', 'SM Client Time Total', 0, 0, 40, 60, 90, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_connections

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_connections', 'SM Connections', 0, 0, 50, 30, 10, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_db_stats

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_db_stats_event_count', 'SM DB Stats Event Count', 0, 0, 80000, 90000, 100000, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_db_stats_journal_count', 'SM DB Stats Journal Count', 0, 0, 20000, 35000, 50000, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_db_stats_details_count', 'SM DB Stats Details Count', 0, 0, 3000, 10000, 20000, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_dbops_stats

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_dbops_stats_status_inserts', 'SM DB Ops Stats Status Inserts', 0, 0, 10000, 0, 0, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_dbops_stats_journal_inserts', 'SM DB Ops Stats Journal Inserts', 0, 0, 10000, 0, 0, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_dbops_stats_details_inserts', 'SM DB Ops Stats Details Inserts', 0, 0, 10000, 0, 0, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_top_nodes

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_top_nodes', 'SM Top Nodes', 0, 0, 100, 200, 500, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_top_probes

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_top_probes', 'SM Top Probes', 0, 0, 600, 800, 1000, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_top_classes

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_top_classes', 'SM Top Classes', 0, 0, 600, 800, 1000, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_time_to_display

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_time_to_display', 'SM Time to Display', 0, 0, 60, 120, 180, 1, 1);
go

------------------------------------------------------------------------------
-- PROCEDURE: sm_insert
-- This generic procedure is called by triggers for the insertion of self-
-- monitoring events.
--
-- Usage:
--  call procedure sm_insert(Identifier, AlertGroup, Severity, 'This is self Monitoring event');
--
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sm_insert
(
  in identifier char(255),
  in node char(64),
  in alertgroup char(255),
  in severity int,
  in summary_string char(255),
  in event_metric int,
  in expiretime int,
  in event_type int)
begin

	-- INSERT A SYNTHETIC EVENT for Self Monitoring
	insert into alerts.status (
		Identifier, Node, Summary, Class, Type, Severity, FirstOccurrence, LastOccurrence,
		Tally, ExpireTime, AlertGroup, OwnerUID, Manager, Agent, ServerName, Grade) 
        values (
		identifier, node, summary_string, 99999, event_type, severity, getdate(), getdate(),
		1, expiretime + 30, alertgroup, 65534, 'OMNIbus Self Monitoring @' + getservername(),
		'OMNIbus SelfMonitoring', getservername(), event_metric) updating (Severity); 
end;
go

------------------------------------------------------------------------------
-- PROCEDURE: sm_log
-- This generic procedure is called by triggers for the logging of self-
-- monitoring data.
--
-- Usage:
--  call procedure sm_log( message );
--
------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sm_log
(
  in summary_string char(255)
)
begin

    -- WRITE A RECORD TO THE LOG FILE
    write into self_monitoring values (to_char(getdate), ': ', summary_string);

end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO LOG ALERT INSERTS TO THE SELF MONITORING LOG
-----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_log_alert_inserts
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Writes log messages to the self monitoring log file for ALERTS.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
WHEN new.Class = 99999 and new.Summary like 'ALERT'
begin


	-- WRITE A LOG MESSAGE
	call procedure sm_log(new.AlertGroup + ': ' + new.Summary);
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO LOG ALERT REINSERTS TO THE SELF MONITORING LOG
-----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_log_alert_reinserts
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Writes log messages to the self monitoring log file for ALERTS.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
WHEN new.Class = 99999 and new.Summary like 'ALERT'
begin


	-- WRITE A LOG MESSAGE
	call procedure sm_log(new.AlertGroup + ': ' + new.Summary);
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO UPDATE GRADE FIELD ON DEDUPLICATION OF SYNTHETIC EVENTS
-----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_deduplication_grade
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Updates Grade, ExpireTime and Acknowledged fields on deduplication
of self-monitoring events.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
WHEN old.Class = 99999
begin

	-- UPDATE Grade FIELD ON DEDUPLICATION OF SELF MONITORING EVENTS
	set old.Grade = new.Grade;
	
	-- UPDATE ExpireTime FIELD ON DEDUPLICATION OF SELF MONITORING EVENTS
	set old.ExpireTime = new.ExpireTime;

	-- UNACKNOWLEDGE EVENT IF IT IS ACKNOWLEDGED
	set old.Acknowledged = 0;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO CREATE A JOURNAL ENTRY IF ALERT EVENT CHANGES SEVERITY
-----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_create_journal_on_severity_change
GROUP self_monitoring_group
PRIORITY 1
COMMENT 'Inserts a journal for ALERT events if the Severity is updated.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
WHEN old.Class = 99999 and old.Type = 1 and (old.Severity != new.Severity)
declare
	old_conversion char(255);
	new_conversion char(255);
	journal_string char(255);
begin

	-- SET OLD SEVERITY TEXT
	if (old.Severity = 5) then
		set old_conversion = 'Critical';
	elseif (old.Severity = 4) then
		set old_conversion = 'Major';
	elseif (old.Severity = 3) then
		set old_conversion = 'Minor';
	elseif (old.Severity = 2) then
		set old_conversion = 'Warning';
	elseif (old.Severity = 1) then
		set old_conversion = 'Indeterminate';
	elseif (old.Severity = 0) then
		set old_conversion = 'Clear';
	end if;

	-- SET NEW SEVERITY TEXT
	if (new.Severity = 5) then
		set new_conversion = 'Critical';
	elseif (new.Severity = 4) then
		set new_conversion = 'Major';
	elseif (new.Severity = 3) then
		set new_conversion = 'Minor';
	elseif (new.Severity = 2) then
		set new_conversion = 'Warning';
	elseif (new.Severity = 1) then
		set new_conversion = 'Indeterminate';
	elseif (new.Severity = 0) then
		set new_conversion = 'Clear';
	end if;

	-- START BUILDING JOURNAL STRING
	set journal_string = 'Severity has been ';

	-- CHECK IF SEVERITY IS GOING UP OR DOWN
	if (old.Severity < new.Severity) then

		set journal_string = journal_string + 'upgraded ';

	else
		set journal_string = journal_string + 'downgraded ';
	end if;

	-- COMPLETE JOURNAL STRING
	set journal_string =  journal_string + 'from ' + old_conversion +
		' (' + to_char(old.Severity) + ') to ' + new_conversion +
		' (' + to_char(new.Severity) + ').  The metric was: ' + to_char(old.Grade) +
		' and is now: ' + to_char(new.Grade) + '.';

	-- INSERT JOURNAL
	call procedure jinsert(
		old.Serial,
		%user.user_id,
		getdate(),
		journal_string);
	
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO GENERATE SYNTHETIC EVENTS FOR MEMSTORE STATS
-----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_memstore 
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Creates synthetic events for memstore stats.'
ON signal profiler_report
declare
	percentage real;
	summary_string char(255);
	identifierappendix char(255);
	sev int;
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;
begin

	-- INITIALISE VARIABLES
	set percentage = 0;
	set summary_string = '';
	set identifierappendix = '';
	set sev = 0;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_memstore'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- CHECK THE MEMSTORE SIZE AND SET THE SEVERITY OF THE
	-- SYNTHETIC EVENT ACCORDINGLY
	for each row row_mem in catalog.memstores where
		row_mem.StoreName = 'table_store'
	begin
		set percentage = (row_mem.UsedBytes * 100 / row_mem.SoftLimit);
		set summary_string = 'table_store soft limit: used ' +
			to_char(to_int(row_mem.UsedBytes/1048576)) +
			' MB of capacity ' +
			to_char(to_int(row_mem.SoftLimit/1048576)) + ' MB (' +
			to_char(to_int(ceil(percentage))) + '% used)';

		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfo = 1) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : Memstore Status for ' +
				getservername() + identifierappendix,
				get_prop_value('Hostname'), 'MemstoreStatus', 2,
				summary_string, to_int(ceil(percentage)), 60, 13);
		end if;

		-- CHECK IF MEMSTORE THRESHOLD HAS BEEN BREACHED
		if (percentage >= sev3 and percentage < sev4) then
			set sev = 3;
			set summary_string = 'ALERT: ' + summary_string;
		elseif (percentage >= sev4 and percentage < sev5) then
			set sev = 4;
			set summary_string = 'ALERT: ' + summary_string;
		elseif (percentage >= sev5) then
			set sev = 5;
			set summary_string = 'ALERT: extend soft limit: ' + summary_string;
		end if;

		-- IF THRESHOLD HAS BEEN BREACHED
		if (sev != 0) then

			-- INSERT A SYNTHETIC ALERT
			call procedure sm_insert('ALERT: OMNIbus ObjectServer : Memstore Status for ' +
				getservername(), get_prop_value('Hostname'),
				'MemstoreStatus', sev, summary_string,
				to_int(ceil(percentage)), 86400, 1);
		end if;
	 end;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO GENERATE SYNTHETIC EVENTS FOR TRIGGER STATS
-----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_triggers
GROUP self_monitoring_group 
PRIORITY 10
COMMENT 'Creates synthetic events for Objectserver Trigger stats.'
ON signal profiler_report
declare
	total_time real;
	identifierappendix char(255);
	sev int;
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;

begin
	set total_time = 0;
	set identifierappendix = '';
	set sev = 0;

	-- GET TRIGGER TIME THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_triggers_individual'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
	end;

	-- FOR EACH ENABLED TRIGGER GROUP
	for each row trigger_group in catalog.trigger_groups where trigger_group.IsEnabled = true
	begin

		-- CHECK THE TRIGGER TIMES FOR EACH ACTIVE TRIGGER IN THAT GROUP
		for each row trig in catalog.trigger_stats
			where trig.TriggerName in (
				select TriggerName from catalog.triggers where
					IsEnabled = true and
					GroupName = trigger_group.GroupName)
		begin

			-- ADD CURRENT TRIGGER TIME TO THE RUNNING TOTAL
			set total_time = total_time + trig.PeriodTime;

			-- GENERATE SYNTHETIC EVENTS FOR INDIVIDUAL TRIGGERS OVER THRESHOLD
 			if (trig.PeriodTime >= sev3) then

				-- SET SEVERITY OF SYNTHETIC EVENTS
				if (trig.PeriodTime >= sev3 and trig.PeriodTime < sev4) then
					set sev = 3;
				elseif (trig.PeriodTime >= sev4 and trig.PeriodTime < sev5) then
					set sev = 4;
				elseif (trig.PeriodTime >= sev5) then
					set sev = 5;
				end if;

				-- INSERT A SYNTHETIC EVENT FOR THIS TRIGGER
				call procedure sm_insert(
					'OMNIbus ObjectServer : Trigger Status for ' +
					getservername() + ':' + trig.TriggerName,
					get_prop_value('Hostname'), 'TriggerStatus',
					sev, 'ALERT: ' + trig.TriggerName +
					': trigger time is high: ' +
					substr(to_char(trig.PeriodTime), 1, 5) +
					' seconds', to_int(ceil(trig.PeriodTime)),
					86400, 1);
			end if;
		end;
	end;

	-- GET TOTAL TRIGGER TIME THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_triggers_total'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- INSERT A SYNTHETIC EVENT IF ENABLED FOR INFO EVENTS
	if (enableinfo = 1) then

		-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW TOTAL TRIGGER TIME
		call procedure sm_insert(
			'OMNIbus ObjectServer: Trigger Status for ' +
			getservername() + ': ' + identifierappendix,
			get_prop_value('Hostname'), 'TriggerStatus', 2,
			'Time for all triggers in profiling period (' +
			substr(to_char(%signal.report_period), 1, 5) + 's): ' +
			substr(to_char(total_time), 1, 5) + ' seconds',
			to_int(ceil(total_time)), 60, 13);
	end if;

	-- RESET sev
	set sev = 0;

	-- CHECK IF TOTAL TRIGGER TIME THRESHOLD HAS BEEN BREACHED
	if (total_time >= sev3 and total_time < sev4) then
		set sev = 3;
	elseif (total_time >= sev4 and total_time < sev5) then 
		set sev = 4;
	elseif (total_time >= sev5) then 
		set sev = 5;
	end if;
	
	-- INSERT A SYNTHETIC ALERT TO SHOW TOTAL TRIGGER TIME THRESHOLD BREACH
	if (sev != 0) then

		call procedure sm_insert(
			'OMNIbus ObjectServer: Trigger Status for ' +
			getservername(), get_prop_value('Hostname'),
			'TriggerStatus', sev,
			'ALERT: Time for all triggers in profiling period is high: ' +
			substr(to_char(total_time), 1, 5) + ' seconds',
			to_int(ceil(total_time)), 86400, 1);
	end if;

	-- GET REPORTING PERIOD THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_triggers_reporting_period'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
	end;

	-- RESET sev
	set sev = 0;

	-- CHECK IF REPORTING PERIOD THRESHOLD HAS BEEN BREACHED
	if (%signal.report_period >= sev3 and %signal.report_period < sev4) then
		set sev = 3;
	elseif (%signal.report_period >= sev4 and %signal.report_period < sev5) then
		set sev = 4;
	elseif (%signal.report_period >= sev5) then
		set sev = 5;
	end if;

	-- INSERT A SYNTHETIC ALERT TO SHOW REPORTING PERIOD THRESHOLD BREACH
	if (sev != 0) then

		-- INSERT A SYNTHETIC EVENT
		call procedure sm_insert(
			'OMNIbus ObjectServer : Profiler Report Status for '
			+ getservername(), get_prop_value('Hostname'),
			'TriggerStatus', sev,
			'ALERT: ObjectServer profiling period high: ' +
			substr(to_char(%signal.report_period), 1, 5) + ' seconds',
			to_int(ceil(%signal.report_period)), 86400, 1);
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO GENERATE SYNTHETIC EVENTS FOR CLIENTS SQL TIME STATS 
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_client_time
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Creates synthetic events for ObjectServer time spent executing client SQL'
ON signal profiler_report
declare
	total_time real;
	identifierappendix char(255);
	summary_string char(255);
	app_description char(128);
	sev int;
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;
begin

	-- INITIALISE VARIABLES
	set total_time = 0;
	set summary_string = '';
	set app_description = '';
	set identifierappendix = '';
	set sev = 0;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_client_time_individual'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
	end;

	-- ITERATE OVER EACH CONNECTED CLIENT THAT HAS SUBMITTED REQUESTS
	for each row profile in catalog.profiles where profile.NumSubmits > 0
	begin

		-- RESET sev
		set sev = 0;

		-- CHECK IF CONNECTED CLIENT TIME THRESHOLD HAS BEEN BREACHED
		if (profile.PeriodSQLTime >= sev3 and profile.PeriodSQLTime < sev4) then
			set sev = 3;
		elseif (profile.PeriodSQLTime >= sev4 and profile.PeriodSQLTime < sev5) then
			set sev = 4;
		elseif ( profile.PeriodSQLTime >= sev5) then
			set sev = 5;
		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW CONNECTED CLIENT TIME THRESHOLD BREACH
		if (sev != 0) then

			-- FIND THE AppDescription FOR THE CONNECTION
			for each row this_connection in catalog.connections where
				this_connection.ConnectionID = profile.ConnectionID
			begin

				set app_description = this_connection.AppDescription;
			end;

			if (app_description = '') then

				-- SET THE SUMMARY FIELD WITHOUT AN APP DESCRIPTION
				set summary_string = 'ALERT: ' + profile.AppName +
					' on ' + profile.HostName + ' (ConnID: ' +
					to_char(profile.ConnectionID) + ') used: ' +
					substr(to_char(profile.PeriodSQLTime), 1, 5) +
					' seconds';

			elseif (app_description like '^e@') then

				-- SET THE SUMMARY FIELD WITH A NATIVE EVENT LIST ENTRY
				set summary_string = 'ALERT: Native Event List on ' +
					profile.HostName + ' (ConnID: ' +
					to_char(profile.ConnectionID) + ') used: ' +
					substr(to_char(profile.PeriodSQLTime), 1, 5) +
					' seconds';
			else

				-- SET THE SUMMARY FIELD WITH A GENERIC APP DESCRIPTION
				set summary_string = 'ALERT: ' + profile.AppName + ': ' +
					app_description + ' on ' + profile.HostName +
					' (ConnID: ' + to_char(profile.ConnectionID) +
					') used: ' + substr(to_char(profile.PeriodSQLTime), 1, 5) +
					' seconds';
			end if;

			-- INSERT A SYNTHETIC EVENT
			call procedure sm_insert(
				'OMNIbus ObjectServer : PeriodSQLtime for ' +
				profile.AppName + ':uid=' + to_char(profile.UID) +
				':' + getservername() + ':' + app_description +
				':' + to_char(profile.ConnectionID),
				get_prop_value('Hostname'), 'ClientStatus', sev,
				summary_string, to_int(ceil(profile.PeriodSQLTime)),
				86400, 1);
		end if;

		set total_time = total_time + profile.PeriodSQLTime;
	end;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_client_time_total'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- INSERT A SYNTHETIC EVENT IF ENABLED FOR INFO EVENTS
	if (enableinfo = 1) then

		-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW TOTAL CLIENT TIME
		call procedure sm_insert(
			'OMNIbus ObjectServer : Total SQL time for all clients ' +
			getservername() + ': ' + identifierappendix,
			get_prop_value('Hostname'), 'ClientStatus', 2,
			'Time for all clients in granularity period (' +
			get_prop_value('Granularity') + 's): ' +
			substr(to_char(total_time), 1, 5) + ' seconds',
			to_int(ceil(total_time)), 60, 13);
	end if;

	-- RESET sev
	set sev = 0;

	-- CHECK IF TOTAL CLIENT TIME THRESHOLD HAS BEEN BREACHED
	if (total_time >= sev3 and total_time < sev4) then
		set sev = 3;
	elseif (total_time >= sev4 and total_time < sev5) then
		set sev = 4;
	elseif (total_time >= sev5) then
		set sev = 5;
	end if;

	-- INSERT A SYNTHETIC ALERT TO SHOW TOTAL CLIENT TIME THRESHOLD BREACH
	if (sev != 0) then

		call procedure sm_insert(
			'OMNIbus ObjectServer : Total SQL time for all clients ' +
			getservername(), get_prop_value('Hostname'),
			'ClientStatus', sev,
			'ALERT: Total time for all clients is high: ' +
			substr(to_char(total_time), 1, 5),
			to_int(ceil(total_time)), 86400, 1);
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO GENERATE SYNTHETIC EVENTS FOR OBJECTSERVER CONNECTION STATS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_connections
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Creates synthetic events for ObjectServer client connections stats.'
EVERY 60 SECONDS
declare
	lastreport int;
	max_connections int;
	avl_connections int;
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;
	summary_string  char(255);
	identifierappendix char(255);
	sev int;
begin

	-- INITIALISE VARIABLES
	set lastreport = 0;
	set sev = 0;
	set max_connections = to_int(get_prop_value('Connections'));
	set avl_connections = max_connections;
	set summary_string = '';
	set identifierappendix = '';

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_connections'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- FIND THE LAST TIME THIS TRIGGER RAN
	for each row this_row in master.sm_activity where
		this_row.ReportTrigger='sm_connections'
	begin
		set lastreport = this_row.MasterStatsLast;
	end;

	-- IF THIS IS THE FIRST TIME THIS TRIGGER HAS RUN, LASTREPORT WILL BE ZERO
	-- SKIP THIS ITERATION OF THE TRIGGER AND STORE THE CURRENT STATS FOR THE NEXT
	-- ITERATION
	if (lastreport = 0) then

		-- ITERATE OVER master.stats TO FIND THE MOST RECENT STATS REPORT
		for each row this_row in master.stats
		begin

			-- STORE THE HIGHEST VALUE
			if (this_row.StatTime > lastreport) then

				set lastreport = this_row.StatTime;
			end if;
		end;

		-- STORE THE HIGHEST VALUE FOR THE NEXT RUN OF THIS TRIGGER
		update master.sm_activity set MasterStatsLast = lastreport where
			ReportTrigger='sm_connections';

		-- TERMINATE HERE
		cancel;
	end if;

	-- RETRIEVE THE LATEST REPORT, IF IT EXISTS, AND UPDATE SYNTHETIC EVENT
	for each row this_row in master.stats where this_row.StatTime > lastreport
	begin

		-- CALCULATE THE NUMBER OF FREE CONNECTIONS
		set avl_connections = max_connections - this_row.NumClients;

		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfo = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW THE NUMBER OF
			-- AVAILABLE CONNECTIONS
			call procedure sm_insert(
				'OMNIbus ObjectServer : Connections available for ' +
				getservername() + ':' + identifierappendix,
				get_prop_value('Hostname'), 'ConnectionStatus', 2,
				'Used ' + to_char(this_row.NumClients) + ' of ' +
				to_char(max_connections) +
				' connections. Available connections: ' +
				to_char(avl_connections), avl_connections, 300, 13);
		end if;

		-- RESET sev
		set sev = 0;

		-- CHECK IF EVENT COUNT THRESHOLD HAS BEEN BREACHED
		if (avl_connections <= sev3 and avl_connections > sev4) then
			set sev = 3;
		elseif (avl_connections <= sev4 and avl_connections > sev5) then
			set sev = 4;
		elseif (avl_connections <= sev5) then
			set sev = 5;
		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW EVENT COUNT THRESHOLD BREACH
		if (sev != 0) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : Connections available for ' +
				getservername() + ':ALERT',
				get_prop_value('Hostname'), 'ConnectionStatus', sev,
				'ALERT: number of available connections is low: ' +
				to_char(avl_connections), avl_connections, 86400, 1);
		end if;

		update master.sm_activity set MasterStatsLast = this_row.StatTime where
			ReportTrigger = 'sm_connections';

		break;
	end;

	-- INSERT SYNTHETIC EVENTS FOR CONNECTIONS IF ENABLED
	if (enableinfo = 1) then

		-- RECREATE CONNECTION SYNTHETIC EVENTS BASED ON CURRENT CONNECTIONS
		for each row client in catalog.connections where
			client.AppName in ('PROBE', 'GATEWAY')
		begin

			-- SET Summary FOR SYNTHETIC EVENT
			set summary_string = client.AppName + ': ' +
				client.AppDescription + ' connected from host ' +
				client.HostName + ' (ID: ' +
				to_char(client.ConnectionID) + ').';

			call procedure sm_insert(
				'probe_gateway_connection_event:' + getservername() +
				':' + client.HostName + ':' +
				to_char(client.ConnectionID) + ':' + client.AppName +
				':' + client.AppDescription + ':' + identifierappendix,
				get_prop_value('Hostname'), 'ConnectionStatus', 2,
				summary_string, client.ConnectionID, 60, 13);
		end;
	end if;

	-- SET FOR EXPIRY ANY ConnectionWatch EVENTS THAT HAVE NOT YET EXPIRED
	update alerts.status set ExpireTime = 86400 where
		ExpireTime = 0 and
		Manager = 'ConnectionWatch';
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO GENERATE SYNTHETIC EVENTS FOR OBJECTSERVER DATABASE STATS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_db_stats
GROUP self_monitoring_group
PRIORITY 11
COMMENT 'Creates synthetic events for ObjectServer DB stats.'
EVERY 60 SECONDS
declare
	lastreport int;
	sev int;
	sev3events int;
	sev4events int;
	sev5events int;
	enableinfoevents int;
	deduplicateinfoevents int;
	identifierappendixevents char(255);
	sev3journals int;
	sev4journals int;
	sev5journals int;
	enableinfojournals int;
	deduplicateinfojournals int;
	identifierappendixjournals char(255);
	sev3details int;
	sev4details int;
	sev5details int;
	enableinfodetails int;
	deduplicateinfodetails int;
	identifierappendixdetails char(255);
begin

	-- INITIALISE VARIABLES
	set lastreport = 0;
	set sev = 0;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds FOR EVENT COUNTS
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_db_stats_event_count'
	begin

		set sev3events = thresholds.Sev3;
		set sev4events = thresholds.Sev4;
		set sev5events = thresholds.Sev5;
		set enableinfoevents = thresholds.EnableInfo;
		set deduplicateinfoevents = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfoevents = 0) then

		set identifierappendixevents = to_char(getdate());
	end if;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds FOR JOURNAL COUNTS
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_db_stats_journal_count'
	begin

		set sev3journals = thresholds.Sev3;
		set sev4journals = thresholds.Sev4;
		set sev5journals = thresholds.Sev5;
		set enableinfojournals = thresholds.EnableInfo;
		set deduplicateinfojournals = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfojournals = 0) then

		set identifierappendixjournals = to_char(getdate());
	end if;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds FOR DETAILS COUNTS
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_db_stats_details_count'
	begin

		set sev3details = thresholds.Sev3;
		set sev4details = thresholds.Sev4;
		set sev5details = thresholds.Sev5;
		set enableinfodetails = thresholds.EnableInfo;
		set deduplicateinfodetails = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfodetails = 0) then

		set identifierappendixdetails = to_char(getdate());
	end if;

	-- FIND THE LAST TIME THIS TRIGGER RAN
	for each row this_row in master.sm_activity where
		this_row.ReportTrigger='sm_db_stats'
	begin

		-- RETRIEVE AND STORE THE TIMESTAMP OF THE LAST STATS REPORT PROCESSED
		set lastreport = this_row.MasterStatsLast;
	end;

	-- IF THIS IS THE FIRST TIME THIS TRIGGER HAS RUN, LASTREPORT WILL BE ZERO
	-- SKIP THIS ITERATION OF THE TRIGGER AND STORE THE CURRENT STATS FOR THE NEXT
	-- ITERATION
	if (lastreport = 0) then

		-- ITERATE OVER master.stats TO FIND THE MOST RECENT STATS REPORT
		for each row this_row in master.stats
		begin

			-- STORE THE HIGHEST VALUE
			if (this_row.StatTime > lastreport) then

				set lastreport = this_row.StatTime;
			end if;
		end;

		-- STORE THE HIGHEST VALUE FOR THE NEXT RUN OF THIS TRIGGER
		update master.sm_activity set MasterStatsLast = lastreport where
			ReportTrigger='sm_db_stats';
		
		-- TERMINATE HERE SINCE WE DON'T HAVE ANY PREVIOUS TIMESTAMP
		cancel;
	end if;

	-- RETRIEVE THE LATEST REPORT, IF IT EXISTS, AND INSERT SYNTHETIC EVENTS
	for each row this_row in master.stats where
		this_row.StatTime > lastreport
	begin

		-- FIRST REPORT ON EVENTS IN alerts.status
		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfoevents = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW EVENT COUNT
			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.status Database Stats for ' +
				getservername() + ':' + identifierappendixevents,
				get_prop_value('Hostname'), 'DBStatus', 2,
				'Event count (alerts.status): ' + to_char(this_row.EventCount),
				this_row.EventCount, 300, 13);

		end if;

		-- RESET sev
		set sev = 0;

		-- CHECK IF EVENT COUNT THRESHOLD HAS BEEN BREACHED
		if (this_row.EventCount >= sev3events and this_row.EventCount < sev4events) then
			set sev = 3;
		elseif (this_row.EventCount >= sev4events and this_row.EventCount < sev5events) then
			set sev = 4;
		elseif (this_row.EventCount >= sev5events) then
			set sev = 5;
		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW EVENT COUNT THRESHOLD BREACH
		if (sev != 0) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.status Database Stats for ' +
				getservername(),
				get_prop_value('Hostname'), 'DBStatus', sev,
				'ALERT: event count (alerts.status) is high: ' +
				to_char(this_row.EventCount), this_row.EventCount,
				86400, 1);
		end if;

		-- SECOND REPORT ON JOURNALS IN alerts.journal
		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfojournals = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW JOURNAL COUNT
			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.journal Database Stats for ' +
				getservername() + ':' + identifierappendixjournals,
				get_prop_value('Hostname'), 'DBStatus', 2,
				'Journal count (alerts.journal): ' + to_char(this_row.JournalCount),
				this_row.JournalCount, 300, 13);

		end if;

		-- RESET sev
		set sev = 0;

		-- CHECK IF JOURNAL COUNT THRESHOLD HAS BEEN BREACHED
		if (this_row.JournalCount >= sev3journals and this_row.JournalCount < sev4journals) then
			set sev = 3;
		elseif (this_row.JournalCount >= sev4journals and this_row.JournalCount < sev5journals) then
			set sev = 4;
		elseif (this_row.JournalCount >= sev5journals) then
			set sev = 5;
		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW JOURNAL COUNT THRESHOLD BREACH
		if (sev != 0) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.journal Database Stats for ' +
				getservername(),
				get_prop_value('Hostname'), 'DBStatus', sev,
				'ALERT: journal count (alerts.journal) is high: ' +
				to_char(this_row.JournalCount),
				this_row.JournalCount, 86400, 1);
		end if;

		-- THIRD REPORT ON DETAILS IN alerts.details
		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfojournals = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW DETAILS COUNT
			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.details Database Stats for ' +
				getservername() + ':' + identifierappendixdetails,
				get_prop_value('Hostname'), 'DBStatus', 2,
				'Details count (alerts.details): ' + to_char(this_row.DetailCount),
				this_row.DetailCount, 300, 13);

		end if;

		-- RESET sev
		set sev = 0;

		-- CHECK IF DETAILS COUNT THRESHOLD HAS BEEN BREACHED
		if (this_row.DetailCount >= sev3details and this_row.DetailCount < sev4details) then
			set sev = 3;
		elseif (this_row.DetailCount >= sev4details and this_row.DetailCount < sev5details) then
			set sev = 4;
		elseif (this_row.DetailCount >= sev5details) then
			set sev = 5;
		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW DETAILS COUNT THRESHOLD BREACH
		if (sev != 0) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.details Database Stats for ' +
				getservername(),
				get_prop_value('Hostname'), 'DBStatus', sev,
				'ALERT: details count (alerts.details) is high: ' +
				to_char(this_row.DetailCount),
				this_row.DetailCount, 86400, 1);
		end if;

		-- UPDATE THE STORED TIMESTAMP OF THE LATEST REPORT
		update master.sm_activity set MasterStatsLast = this_row.StatTime where
			ReportTrigger='sm_db_stats';

		--  LOG TO FILE THE ROW COUNTS
		call procedure sm_log(
			'RowCounts: alerts.status: ' + to_char(this_row.EventCount) +
			', alerts.journal: ' + to_char(this_row.JournalCount) +
			', alerts.details: ' + to_char(this_row.DetailCount));

		break;
	end;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO GENERATE SYNTHETIC EVENTS FOR OBJECTSERVER DB OPERATION STATS
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_dbops_stats
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Creates synthetic events for DB operations stats.'
EVERY 60 SECONDS
declare
	lastreport int;
	sev int;

	last_StatusInserts int;
	last_JournalInserts int;
	last_DetailsInserts int;
	StatusInserts int;
	JournalInserts int;
	DetailsInserts int;

	sev3statusinserts int;
	enableinfo_si int;
	deduplicateinfo_si int;
	identifierappendix_si char(255);

	sev3journalinserts int;
	enableinfo_ji int;
	deduplicateinfo_ji int;
	identifierappendix_ji char(255);

	sev3detailsinserts int;
	enableinfo_di int;
	deduplicateinfo_di int;
	identifierappendix_di char(255);
begin

	-- INITIALISE VARIABLES
	set lastreport = 0;

	set last_StatusInserts = 0; 
	set last_JournalInserts = 0;
	set last_DetailsInserts = 0;

	set StatusInserts = 0;
	set JournalInserts = 0;
	set DetailsInserts = 0;

	set sev = 0;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds FOR STATUS INSERTS
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_dbops_stats_status_inserts'
	begin

		set sev3statusinserts = thresholds.Sev3;
		set enableinfo_si = thresholds.EnableInfo;
		set deduplicateinfo_si = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo_si = 0) then

		set identifierappendix_si = to_char(getdate());
	end if;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds FOR JOURNAL INSERTS
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_dbops_stats_journal_inserts'
	begin

		set sev3journalinserts = thresholds.Sev3;
		set enableinfo_ji = thresholds.EnableInfo;
		set deduplicateinfo_ji = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo_ji = 0) then

		set identifierappendix_ji = to_char(getdate());
	end if;

	-- GET THRESHOLD VALUES FROM master.sm_thresholds FOR DETAILS INSERTS
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_dbops_stats_details_inserts'
	begin

		set sev3detailsinserts = thresholds.Sev3;
		set enableinfo_di = thresholds.EnableInfo;
		set deduplicateinfo_di = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo_di = 0) then

		set identifierappendix_di = to_char(getdate());
	end if;

	-- FIND THE LAST TIME THIS TRIGGER RAN
	for each row this_row in master.sm_activity where
		this_row.ReportTrigger='sm_dbops_stats'
	begin

		-- RETRIEVE AND STORE THE TIMESTAMP OF THE LAST STATS REPORT PROCESSED
		set lastreport = this_row.MasterStatsLast;
	end;

	-- IF THIS IS THE FIRST TIME THIS TRIGGER HAS RUN, LASTREPORT WILL BE ZERO
	-- SKIP THIS ITERATION OF THE TRIGGER AND STORE THE CURRENT STATS FOR THE NEXT
	-- ITERATION
	if (lastreport = 0) then

		-- ITERATE OVER master.stats TO FIND THE MOST RECENT STATS REPORT
		for each row this_row in master.stats
        -- not used?
		begin

			-- STORE THE HIGHEST VALUE
			if (this_row.StatTime > lastreport) then

				set lastreport = this_row.StatTime;
			end if;
		end;

		-- STORE THE HIGHEST VALUE FOR THE NEXT RUN OF THIS TRIGGER
		update master.sm_activity set MasterStatsLast = lastreport where
			ReportTrigger='sm_dbops_stats';

		-- TERMINATE HERE
		cancel;
	end if;

	-- RETRIEVE THE PREVIOUS REPORT VALUES
	for each row last in master.stats where last.StatTime = lastreport
	begin

 		set last_StatusInserts = last.StatusInserts;
		set last_JournalInserts = last.JournalInserts;
		set last_DetailsInserts = last.DetailsInserts;
	end;

	-- FIND THE LATEST REPORT, IF IT EXISTS, AND UPDATE SYNTHETIC EVENT
	for each row this_row in master.stats where this_row.StatTime > lastreport
	begin
		
		-- CALCULATE THE DELTA BETWEEN THE LAST REPORT AND LATEST REPORT
		set StatusInserts = this_row.StatusInserts - last_StatusInserts;
		set JournalInserts = this_row.JournalInserts - last_JournalInserts;
		set DetailsInserts = this_row.DetailsInserts - last_DetailsInserts;

		-- FIRST REPORT ON NUMBER OF INSERTS INTO alerts.status
		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfo_si = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW alerts.status INSERTS
			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.status DB operations stats for ' +
				getservername() + ':' + identifierappendix_si,
				get_prop_value('Hostname'), 'DBStatus', 2,
				'Last 5 mins alerts.status (inserts/deduplications): ' +
				to_char(StatusInserts), StatusInserts, 300, 13);

		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW DETAILS COUNT THRESHOLD BREACH
		if (StatusInserts >= sev3statusinserts) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.status DB operations stats for ' +
				getservername(),
				get_prop_value('Hostname'), 'DBStatus', 3,
				'ALERT: last 5 mins alerts.status inserts/deduplications are high: ' +
				to_char(StatusInserts), StatusInserts, 86400, 1);
		end if;

		-- SECOND REPORT ON NUMBER OF INSERTS INTO alerts.journal
		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfo_ji = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW alerts.journal INSERTS
			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.journal DB operations stats for ' +
				getservername() + ':' + identifierappendix_ji,
				get_prop_value('Hostname'), 'DBStatus', 2,
				'Last 5 mins alerts.journal (inserts): ' + to_char(JournalInserts),
				JournalInserts, 300, 13);

		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW JOURNAL COUNT THRESHOLD BREACH
		if (JournalInserts >= sev3journalinserts) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.journal DB operations stats for ' +
				getservername(),
				get_prop_value('Hostname'), 'DBStatus', 3,
				'ALERT: last 5 mins alerts.journal inserts are high: ' +
				to_char(JournalInserts), JournalInserts, 86400, 1);
		end if;

		-- THIRD REPORT ON NUMBER OF INSERTS INTO alerts.details
		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfo_di = 1) then

			-- INSERT A SYNTHETIC INFORMATION EVENT TO SHOW alerts.details INSERTS
			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.details DB operations stats for ' +
				getservername() + ':' + identifierappendix_di,
				get_prop_value('Hostname'), 'DBStatus', 2,
				'Last 5 mins alerts.details (inserts): ' + to_char(DetailsInserts),
				DetailsInserts, 300, 13);

		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW DETAILS COUNT THRESHOLD BREACH
		if (DetailsInserts >= sev3detailsinserts) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : alerts.details DB operations stats for ' +
				getservername(),
				get_prop_value('Hostname'), 'DBStatus', 3,
				'ALERT: last 5 mins alerts.details inserts are high: ' +
				to_char(DetailsInserts), DetailsInserts, 86400, 1);
		end if;

		-- LOG TO FILE THE TABLE METRICS
		call procedure sm_log(
			'InsertCounts: Last 5 mins: alerts.status (inserts/deduplications): ' +
			to_char(StatusInserts)  + ', alerts.journal (inserts): ' +
			to_char(JournalInserts) + ', alerts.details (inserts): ' +
			to_char(DetailsInserts));

		-- UPDATE THE LAST REPORT TIME
		update master.sm_activity set MasterStatsLast = this_row.StatTime where
			ReportTrigger='sm_dbops_stats';

		break;
	end;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO RESTRICT WHICH EVENTS GET INSERTED AT DISPLAY SERVERS
-- FROM THE LAYERS BELOW TO AVOID THE DUPLICATION OF EVENTS IN THE GUI.
------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sm_block_events_from_gateway
GROUP self_monitoring_group
PRIORITY 1
COMMENT 'TRIGGER: block_sm_events_from_gateway
--
This trigger prevents the self monitoring events from being inserted into the
Display layer ObjectServers from the layers below.  This is to prevent
duplication of events within the GUI.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
WHEN getservername() like 'DIS'
begin

	-- DROP SELF-MONITORING EVENTS COMING FROM THE DISPLAY GATEWAY
	if (	%user.description = 'display_gate' and
		(	new.Class = 99999 or
			new.Class = 10500 or
			new.AlertGroup = 'ITNM Status' or
			new.Agent = 'OMNIbus SelfMonitoring' or
			new.Manager like 'Watch')) then

		cancel;
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE CUSTOM TABLE TO HOLD TOP NODES
------------------------------------------------------------------------------

CREATE TABLE master.sm_top_nodes VIRTUAL
(
	Node	varchar(64) primary key,
	Tally	int
);
go

------------------------------------------------------------------------------
-- CREATE TRIGGERS TO POPULATE TOP NODES TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_top_nodes_insert
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Populates the top Nodes table on insert.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
begin

	-- IF IT IS A PROBE PERFORMING THE INSERT
	if (%user.app_name = 'PROBE') then

		-- INCREMENT THE TALLY FOR THE INCOMING EVENT NODE
		insert into master.sm_top_nodes ( Node, Tally)
            values ( new.Node, 1);

	-- ELSE IF IT IS TopNodes INFO COMING FROM THE COLLECTION LAYER
	elseif (%user.description = 'collection_gate' and new.AlertGroup = 'TopNodesColl') then

		-- ADD THE INCOMING TOTAL TO THE LOCAL TALLY
		insert into master.sm_top_nodes ( Node, Tally)
            values ( new.Node, new.Grade);
	end if;
end;
go

CREATE OR REPLACE TRIGGER sm_top_nodes_reinsert
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Populates the top Nodes table on reinsert.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
begin

	-- IF IT IS A PROBE PERFORMING THE REINSERT
	if (%user.app_name = 'PROBE') then

		-- INCREMENT THE TALLY FOR THE INCOMING EVENT NODE
		insert into master.sm_top_nodes ( Node, Tally)
            values ( new.Node, 1);

	-- ELSE IF IT IS TopNodes INFO COMING FROM THE COLLECTION LAYER
	elseif (%user.description = 'collection_gate' and new.AlertGroup = 'TopNodesColl') then

		-- ADD THE INCOMING TOTAL TO THE LOCAL TALLY
		insert into master.sm_top_nodes ( Node, Tally)
            values ( new.Node, new.Grade);
	end if;
end;
go

CREATE OR REPLACE TRIGGER sm_top_nodes_deduplication
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Handles deduplications on the master.sm_top_nodes table.'
BEFORE REINSERT ON master.sm_top_nodes
FOR EACH ROW
begin

	-- INCREMENT THE TALLY FOR THE INCOMING EVENT NODE
	set old.Tally = old.Tally + new.Tally;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO PROCESS CONTENTS OF TOP NODES TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_process_top_nodes
group self_monitoring_group
priority 10
comment 'Creates synthetic events for top Nodes.'
every 300 seconds
declare

	sev		int;
	summary_string	char(255);	
	row_identifier	char(255);
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;
	identifierappendix char(255);
begin

	-- INITIALISE VARIABLES
	set sev = 0;
	set summary_string = '';
	set row_identifier = '';
	set identifierappendix = '';

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_top_nodes'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- PROCESS CONTENTS OF sm_top_nodes TABLE
	for each row this_row in master.sm_top_nodes
	begin

		-- SET IDENTIFIER FOR CURRENT NODE
		set row_identifier =
			'OMNIbus ObjectServer : top Node event rate for ' +
			this_row.Node + ':' + identifierappendix;

		-- CONSTRUCT SUMMARY STRING
		set summary_string = 'Last 5 mins: ' + this_row.Node + ' sent ' +
			to_char(this_row.Tally) + ' event(s)';

		-- INSERT THE SYNTHETIC EVENT AT COLLECTION OR AGGREGATION
		if (getservername() like 'AGG') then

			-- INSERT A SYNTHETIC EVENT IF ENABLED
			if (enableinfo = 1) then

				-- INSERT THE SYNTHETIC EVENT FOR CLASS COUNT
				call procedure sm_insert(
					row_identifier, this_row.Node, 'TopNodes', 2,
					summary_string, this_row.Tally, 300, 13);
			end if;

			-- RESET sev
			set sev = 0;

			-- CHECK IF NODE COUNT THRESHOLD HAS BEEN BREACHED
			if (this_row.Tally >= sev3 and this_row.Tally < sev4) then
				set sev = 3;
			elseif (this_row.Tally >= sev4 and this_row.Tally < sev5) then
				set sev = 4;
			elseif (this_row.Tally >= sev5) then
				set sev = 5;
			end if;

			-- INSERT A SYNTHETIC ALERT TO SHOW NODE COUNT THRESHOLD BREACH
			if (sev != 0) then

				call procedure sm_insert(
					'OMNIbus ObjectServer : top Node event rate for ' +
					this_row.Node + ':ALERT', this_row.Node, 'TopNodes',
					sev, 'ALERT: last 5 mins: high number of events sent by: ' +
					this_row.Node + ': ' + to_char(this_row.Tally),
					this_row.Tally, 86400, 1);
			end if;

		elseif (getservername() like 'COL') then

			-- SET IDENTIFIER FOR A COLLECTION INSERT
			set row_identifier =
				'OMNIbus ObjectServer : top Node event rate for ' +
				this_row.Node + ':' + to_char(getdate()) +
				':COLL' + getservername();

			call procedure sm_insert(
				row_identifier, this_row.Node, 'TopNodesColl', 2,
				summary_string, this_row.Tally, 300, 13);
		end if;
	end;

	-- CLEAN master.sm_top_nodes TABLE
	delete from master.sm_top_nodes;

	-- CLEAN UP ANY ROWS AT AGGREGATION RECEIVED FROM THE COLLECTION LAYER
	if (getservername() like 'AGG') then

		delete from alerts.status where AlertGroup = 'TopNodesColl';
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO INSPECT PROBE HEARTBEAT EVENTS
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_check_probe_heartbeats
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Check Probe heartbeat events and raise Severity of ones that have not heartbeated for more than 3 minutes.'
EVERY 60 SECONDS
WHEN get_prop_value('ActingPrimary') %= 'TRUE' and getservername() like 'AGG'
begin

	-- LOOK FOR UNCLEARED PROBE HEARTBEAT EVENTS THAT HAVE MISSED 3 OR MORE HEARTBEATS
	for each row heartbeat in alerts.status where
		heartbeat.Severity != 0 and
		heartbeat.LastOccurrence < (getdate() - 180) and
		heartbeat.Manager = 'ProbeWatch' and
		heartbeat.Identifier like 'Heartbeat'
	begin

		-- UPDATE SUMMARY AND SEVERITY
		set heartbeat.Summary =
			heartbeat.AlertKey + ' probe on ' +
			heartbeat.Node + ': ALERT: no heartbeat for current PID for ' +
			to_char(to_int((getdate() - heartbeat.LastOccurrence) / 60)) +
			' minutes.';

		set heartbeat.Severity = 3;
	end;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO CLEAN UP CLEARED SYNTHETIC EVENTS ON DISPLAY OBJECTSERVERS
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_delete_clears_display
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Delete clear synthetic alerts over 2 minutes old on Display ObjectServers.'
EVERY 60 SECONDS
WHEN getservername() like 'DIS'
begin

	delete from alerts.status where
		Severity = 0 and
		ServerName = getservername() and
		StateChange < (getdate() - 120);
end;
go

------------------------------------------------------------------------------
-- CREATE CUSTOM TABLE TO HOLD TOP PROBES
------------------------------------------------------------------------------

CREATE TABLE master.sm_top_probes VIRTUAL
(
	Identifier	varchar(255) primary key,
	Probe		varchar(64),
	Hostname	varchar(64),
	ConnectionID	int,
	Tally		int
);
go

------------------------------------------------------------------------------
-- CREATE TRIGGERS TO POPULATE TOP NODES TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_top_probes_insert
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Populates the top Probes table on insert.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
WHEN %user.app_name = 'PROBE'
begin

	-- INCREMENT THE TALLY FOR THE INCOMING EVENT PROBE
	insert into master.sm_top_probes ( Identifier, Probe, Hostname, ConnectionID, Tally)
        values ( getservername() + ':' +
			%user.description + ':' +
			%user.host_name + ':' +
			to_char(%user.connection_id),
		%user.description, %user.host_name, %user.connection_id, 1);
end;
go

CREATE OR REPLACE TRIGGER sm_top_probes_reinsert
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Populates the top Probes table on reinsert.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
WHEN %user.app_name = 'PROBE'
begin

	-- INCREMENT THE TALLY FOR THE INCOMING EVENT PROBE
	insert into master.sm_top_probes ( Identifier, Probe, Hostname, ConnectionID, Tally)
        values ( getservername() + ':' +
			%user.description + ':' +
			%user.host_name + ':' +
			to_char(%user.connection_id),
		%user.description, %user.host_name, %user.connection_id, 1);
end;
go

CREATE OR REPLACE TRIGGER sm_top_probes_deduplication
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Handles deduplications on the master.sm_top_probes table.'
BEFORE REINSERT ON master.sm_top_probes
FOR EACH ROW
begin

	-- INCREMENT THE TALLY FOR THE INCOMING EVENT NODE
	set old.Tally = old.Tally + 1;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO PROCESS CONTENTS OF TOP PROBES TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_process_top_probes
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Creates synthetic events for top Probes.'
EVERY 300 SECONDS
declare

	sev int;
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;
	identifierappendix char(255);
begin

	-- INITIALISE VARIABLE
	set sev = 0;
	set identifierappendix = '';

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_top_probes'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- PROCESS CONTENTS OF sm_top_probes TABLE
	for each row this_row in master.sm_top_probes
	begin

		-- INSERT A SYNTHETIC EVENT IF ENABLED
		if (enableinfo = 1) then

			-- INSERT THE EVENT COUNT EVENT
			call procedure sm_insert(
				'OMNIbus ObjectServer : top Probe event rate for ' +
				this_row.Identifier + ':' + identifierappendix,
				get_prop_value('Hostname'), 'ProbeStatus', 2,
				'Last 5 mins: ' + this_row.Probe + ' Probe on ' +
				this_row.Hostname + ' (ID: ' +
				to_char(this_row.ConnectionID) + '): sent ' +
				to_char(this_row.Tally) + ' event(s)',
				this_row.Tally, 300, 13);
		end if;

		-- RESET sev
		set sev = 0;

		-- CHECK IF PROBE COUNT THRESHOLD HAS BEEN BREACHED
		if (this_row.Tally >= sev3 and this_row.Tally < sev4) then
			set sev = 3;
		elseif (this_row.Tally >= sev4 and this_row.Tally < sev5) then
			set sev = 4;
		elseif (this_row.Tally >= sev5) then
			set sev = 5;
		end if;

		-- INSERT A SYNTHETIC ALERT TO SHOW PROBE COUNT THRESHOLD BREACH
		if (sev != 0) then

			call procedure sm_insert(
				'OMNIbus ObjectServer : top Probe event rate for ' +
				this_row.Identifier + ':ALERT',
				get_prop_value('Hostname'), 'ProbeStatus', sev,
				'ALERT: ' + this_row.Probe + ' Probe (Conn ID: ' +
				to_char(this_row.ConnectionID) +
				'): sent high number of events: ' +
				to_char(this_row.Tally), this_row.Tally, 86400, 1);
		end if;
	end;

	-- CLEAN master.sm_top_probes TABLE
	delete from master.sm_top_probes;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO EXPIRE SELF MONITORING EVENTS ON DISPLAY OBJECTSERVERS
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_expire_display_events
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Expire local self monitoring events on Display ObjectServers.'
EVERY 61 SECONDS
WHEN getservername() like 'DIS'
begin

	-- FIND LOCALLY GENERATED SELF MONITORING EVENTS THAT ARE DUE FOR EXPIRY
	for each row expire in alerts.status where
		expire.Severity != 0 and
		expire.ExpireTime != 0 and
		expire.LastOccurrence < (getdate() - expire.ExpireTime) and
		expire.ServerName = getservername()
	begin

		-- CLEAR EXPIRED EVENTS
		set expire.Severity = 0;
	end;
end;
go

------------------------------------------------------------------------------
-- CREATE CUSTOM TABLE TO HOLD TOP CLASSES
------------------------------------------------------------------------------

CREATE TABLE master.sm_top_classes VIRTUAL
(
	Class		int primary key,
	Tally		int
);
go

------------------------------------------------------------------------------
-- CREATE TRIGGERS TO POPULATE TOP CLASSES TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_top_classes_insert
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Populates the top Classes table on insert.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
begin

	-- IF IT IS A PROBE PERFORMING THE INSERT
	if (%user.app_name = 'PROBE') then

		-- INCREMENT THE TALLY FOR THE INCOMING EVENT PROBE
		insert into master.sm_top_classes ( Class, Tally)
            values ( new.Class, 1);

	-- ELSE IF IT IS TopClasses INFO COMING FROM THE COLLECTION LAYER
	elseif (%user.description = 'collection_gate' and new.AlertGroup = 'TopClassesColl') then

		-- ADD THE INCOMING TOTAL TO THE LOCAL TALLY
		insert into master.sm_top_classes ( Class, Tally)
            values ( new.Class, new.Grade);
	end if;
end;
go

CREATE OR REPLACE TRIGGER sm_top_classes_reinsert
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Populates the top Classes table on reinsert.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
begin

	-- IF IT IS A PROBE PERFORMING THE REINSERT
	if (%user.app_name = 'PROBE') then

		-- INCREMENT THE TALLY FOR THE INCOMING EVENT PROBE
		insert into master.sm_top_classes ( Class, Tally)
            values ( new.Class, 1);

	-- ELSE IF IT IS TopClasses INFO COMING FROM THE COLLECTION LAYER
	elseif (%user.description = 'collection_gate' and new.AlertGroup = 'TopClassesColl') then

		-- ADD THE INCOMING TOTAL TO THE LOCAL TALLY
		insert into master.sm_top_classes ( Class, Tally)
            values ( new.Class, new.Grade);
	end if;
end;
go

CREATE OR REPLACE TRIGGER sm_top_classes_deduplication
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Handles deduplications on the master.sm_top_classes table.'
BEFORE REINSERT ON master.sm_top_classes
FOR EACH ROW
begin

	-- INCREMENT THE TALLY FOR THE INCOMING EVENT NODE
	set old.Tally = old.Tally + new.Tally;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO PROCESS CONTENTS OF TOP CLASSES TABLE
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_process_top_classes
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'Creates synthetic events for top Classes.'
EVERY 300 SECONDS
declare

	sev int;
	class_conv char(64);
	summary_string char(255);
	row_identifier char(255);
	sev3 int;
	sev4 int;
	sev5 int;
	enableinfo int;
	deduplicateinfo int;
	identifierappendix char(255);
begin

	-- INITIALISE VARIABLES
	set sev = 0;
	set class_conv = '';
	set summary_string = '';
	set row_identifier = '';
	set identifierappendix = '';

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_top_classes'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
		set enableinfo = thresholds.EnableInfo;
		set deduplicateinfo = thresholds.DeduplicateInfo;
	end;

	-- PREPEND TIMESTAMP TO Identifier IF NO DEDUPLICATION
	if (deduplicateinfo = 0) then

		set identifierappendix = to_char(getdate());
	end if;

	-- PROCESS CONTENTS OF sm_top_classes TABLE
	for each row this_row in master.sm_top_classes
	begin

		-- SET IDENTIFIER FOR CURRENT CLASS
		set row_identifier =
			'OMNIbus ObjectServer : top Class event rate for ' +
			to_char(this_row.Class) + ':' + identifierappendix;

		-- SET DEFAULT CLASS CONVERSION
		set class_conv = 'UNKNOWN';

		-- LOOK UP CLASS CONVERSION IN CONVERSIONS TABLE
		for each row this_conversion in alerts.conversions where
			this_conversion.Colname = 'Class' and
			this_conversion.Value = this_row.Class
		begin

			-- SAVE CONVERSION
			set class_conv = this_conversion.Conversion;
			break;
		end;

		-- CONSTRUCT SUMMARY STRING
		set summary_string = 'Last 5 mins: received: ' +
			to_char(this_row.Tally) + ' event(s) of class: ' +
			class_conv + ' (' + to_char(this_row.Class) + ')';

		-- INSERT THE SYNTHETIC EVENTS AT COLLECTION OR AGGREGATION
		if (getservername() like 'AGG') then

			-- INSERT A SYNTHETIC EVENT IF ENABLED
			if (enableinfo = 1) then

				-- INSERT THE SYNTHETIC EVENT FOR CLASS COUNT
				call procedure sm_insert(
					row_identifier, get_prop_value('Hostname'),
					'TopClasses', 2, summary_string,
					this_row.Tally, 300, 13);
			end if;
		
			-- RESET sev
			set sev = 0;

			-- SET EVENT SEVERITY
			if (this_row.Tally >= sev3 and this_row.Tally < sev4) then
				set sev = 3;
			elseif (this_row.Tally >= sev4 and this_row.Tally < sev5) then
				set sev = 4;
			elseif (this_row.Tally >= sev5) then
				set sev = 5;
			end if;

			-- INSERT A SYNTHETIC ALERT TO SHOW CLASS COUNT THRESHOLD BREACH
			if (sev != 0) then

				call procedure sm_insert(
					'OMNIbus ObjectServer : top Class event rate for ' +
					to_char(this_row.Class) + ':ALERT',
					get_prop_value('Hostname'), 'TopClasses', sev,
					'ALERT: last 5 mins: high number of events for class: ' +
					class_conv + ' (' + to_char(this_row.Class) + '): ' +
					to_char(this_row.Tally), this_row.Tally, 86400, 1);
			end if;

		elseif (getservername() like 'COL') then

			-- SET IDENTIFIER FOR A COLLECTION INSERT
			set row_identifier =
				'OMNIbus ObjectServer : top Class event rate for ' +
				to_char(this_row.Class) + ':' + to_char(getdate()) +
				':COLL' + getservername();

			-- INSERT THE SYNTHETIC EVENT
			call procedure sm_insert(
				row_identifier, get_prop_value('Hostname'), 'TopClassesColl',
				2, summary_string, this_row.Tally, 300, 13);

			-- UPDATE THE CLASS FIELD OF THE NEWLY INSERTED EVENT
			update alerts.status set Class = this_row.Class where
				Identifier = row_identifier;
		end if;

	end;

	-- CLEAN master.sm_top_classes TABLE
	delete from master.sm_top_classes;

	-- CLEAN UP ANY ROWS AT AGGREGATION RECEIVED FROM THE COLLECTION LAYER
	if (getservername() like 'AGG') then

		delete from alerts.status where AlertGroup = 'TopClassesColl';
	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE TRIGGER TO MODIFY SEVERITY OF TIME TO DISPLAY EVENTS
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER sm_time_to_display_severity
GROUP self_monitoring_group
PRIORITY 10
COMMENT 'This trigger adjusts the Severity of time to display events based on the metric.'
EVERY 61 SECONDS
WHEN getservername() like 'DIS'
declare
	sev3 int;
	sev4 int;
	sev5 int;
begin

	-- GET THRESHOLD VALUES FROM master.sm_thresholds
	for each row thresholds in master.sm_thresholds where
		thresholds.ThresholdName = 'sm_time_to_display'
	begin

		set sev3 = thresholds.Sev3;
		set sev4 = thresholds.Sev4;
		set sev5 = thresholds.Sev5;
	end;

	-- FIND TIME TO DISPLAY EVENTS
	for each row ttd in alerts.status where
		ttd.Identifier = 'time_to_display'
	begin

		-- MODIFY SEVERITY BASED ON NUMBER
		if (ttd.Grade < sev3) then
			set ttd.Severity = 2;
		elseif ((ttd.Grade >= sev3) and (ttd.Grade < sev4)) then
			set ttd.Severity = 3;
		elseif ((ttd.Grade >= sev4) and (ttd.Grade < sev5)) then
			set ttd.Severity = 4;
		elseif (ttd.Grade >= sev5) then
			set ttd.Severity = 5;
		end if;
	end;
end;
go
----------------------------------------------------------------------
-- end of OMNIbus Self Monitoring
----------------------------------------------------------------------

-------------------------------------------------------------------------------
-- The following configuration is for SCA-LA integration
-------------------------------------------------------------------------------
-- ADD A NEW IDUC CHANNEL FOR THE MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE
-- IF CHANNEL ID = 1000 IS USED IN YOUR SYSTEM, PLEAES CHANGE IT TO A NEW VALUE

insert into iduc_system.channel (Name, ChannelID, Description) values ( 'scala', 1000, 'Channel for sending events to SCALA via SCALA gateway');

-- ADD A CHANNEL INTEREST FOR THE MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE. CONFIG THE
-- APPDESCRIPTION IN GATEWAY PROPERTY: Gate.Reader.Description: SCALA Gateway Reader
-- IF INTEREST ID = 1000 IS USED IN YOUR SYSTEM, PLEAES CHANGE IT TO A NEW VALUE

insert into iduc_system.channel_interest (InterestID, ElementName, IsGroup, Hostname, AppName, AppDescription, ChannelID) values (1000,'',0,'','','SCALA Gateway Reader',1000);

-- CREATE A CHANNEL SUMMARY ENTRY FOR THE ACCELERATED INSERTS CHANNEL
-- IF SUMMARY ID = 1000 IS USED IN YOUR SYSTEM, PLEASE CHANGE IT TO A NEW VALUE

insert into iduc_system.channel_summary (DatabaseName, TableName, ChannelID, SummaryID) values ('alerts','status',1000,1000);

-- DEFINE THE FIELDS TO BE FORWARDED OVER THE ACCELERATED INSERTS CHANNEL

insert into iduc_system.channel_summary_cols (ColumnName, SummaryID, Position, ChannelID) values('Serial',1000,0,1000);
go

-------------------------------------------------------------------------------
-- CREATE A TRIGGER GROUP FOR THE TRIGGERS RELATED TO THE
-- MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE
-------------------------------------------------------------------------------

create or replace trigger group scala_triggers;
go

alter trigger group scala_triggers set enabled false;
go

-------------------------------------------------------------------------------
-- CREATE A POST-INSERT TRIGGER TO FORWARD NEW INSERTS TO THE
-- MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE
-- IT'S DISABLED BY DEFAULT
-------------------------------------------------------------------------------

create or replace trigger scala_insert
group scala_triggers
enabled false
priority 20
comment 'Fast Track an event insert for alerts.status to message bus Gateway running in SCALA mode'
after insert on alerts.status
for each row
begin
	iduc evtft 'scala' , insert , new ;
end;
go

-------------------------------------------------------------------------------
-- CREATE A POST-INSERT TRIGGER TO FORWARD NEW REINSERTS TO THE 
-- MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE
-- IT'S DISABLED BY DEFAULT
-------------------------------------------------------------------------------

create or replace trigger scala_reinsert
group scala_triggers
enabled false
priority 20
comment 'Fast Track an event reinsert for alerts.status to message bus Gateway running in SCALA mode'
after reinsert on alerts.status
for each row
begin
	iduc evtft 'scala' , insert , new ;
end;
go
-------------------------------------------------------------------------------
-- End of SCA-LA configuration
-------------------------------------------------------------------------------

-- End of file
