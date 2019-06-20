--
-- Probe Statistics
--
-- Part of the extensions/roi package
--

--
-- create the probestats_report file in the log directory
--
create or replace file probestats_report getenv('OMNIHOME') + '/log/' + getservername + '_probestats.log' maxfiles 2 maxsize 25m;
go

--
-- master.probestats table containing statistics
--
create table master.probestats persistent
(
	SeqNos			incr,
	KeyField		varchar(128) primary key,	-- StatTime + ProbeId
	StatTime		time,		-- UTC Timestamp
	ProbeUpTime		int,		-- Probe Uptime in seconds
	ProbeAgent		varchar(32),	-- Probe Agent field
	ProbeHost		varchar(64),	-- Probe Host
	ProbeId			varchar(96),	-- Agent @ Host
	ProbePID		int,	-- PID
-- Statistics go below here
	NumEventsProcessed	int,	-- number of events entering rules file
	NumEventsGenerated	int,	-- number of new events generated with genevent()
	NumEventsDiscarded	int,	-- number of events discarded by rules file
	RulesFileTimeSec	int,	-- in seconds
	AvgRulesFileTime	int,	-- millionths of a second
	CPUTimeSec		int,	-- in seconds
	ProbeMemory		int	-- in kilobytes
);
go

--
-- Create a holding table for last stats report time
--
create table master.activity_probestats persistent
(
	ReportAgent		char(32) primary key, -- objservlog or itmagent
	ProbeStatsLastSeqNos	int,
	MasterStatsLast		time
);
go

--
-- Stats report automation
--
create or replace trigger probe_statistics_report
group stats_triggers
enabled true
priority 2
comment 'Produce probestats report'
every 30 seconds
declare
	lastseq_probe	int;
	lastreport	int;
	newlast		int;
begin
	-- Get most recent reports run
	set lastseq_probe = 0;
	set lastreport = 0;
	-- Find time of last report if present
	for each row my_row in master.activity_probestats where my_row.ReportAgent='objservlog'
        begin
		-- One or zero rows
		set lastreport = my_row.MasterStatsLast;
		set lastseq_probe = my_row.ProbeStatsLastSeqNos;
	end;
	-- Do report on any master.stats entries later than lastreport
	set newlast = 0;
	for each row s in master.stats where s.StatTime > lastreport
	begin
		write into probestats_report values (
			to_char( s.StatTime ) + ': master.stats report:' );
		write into probestats_report values (
			to_char( s.StatTime ) + ': NumClients: ' + to_char( s.NumClients ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': NumRealtime: ' + to_char( s.NumRealtime ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': NumProbes: ' + to_char( s.NumProbes ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': NumGateways: ' + to_char( s.NumGateways ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': NumMonitors: ' + to_char( s.NumMonitors ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': NumProxys: ' + to_char( s.NumProxys ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': EventCount: ' + to_char( s.EventCount ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': JournalCount: ' + to_char( s.JournalCount ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': DetailCount: ' + to_char( s.DetailCount ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': StatusInserts: ' + to_char( s.StatusInserts ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': StatusNewInserts: ' + to_char( s.StatusNewInserts ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': StatusDedups: ' + to_char( s.StatusDedups ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': JournalInserts: ' + to_char( s.JournalInserts ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': DetailsInserts: ' + to_char( s.DetailsInserts ) );
		write into probestats_report values (
			to_char( s.StatTime ) + ': master.stats report end' );
		if( s.StatTime > newlast ) then
			-- Keep track of greatest s.StatTime value we have processed
			set newlast = s.StatTime;
		end if;
	end;
	if( newlast > lastreport ) then
		-- Store greatest s.StatTime value we have processed, to be updated later
		set lastreport = newlast;
	end if;
	-- Do report on any master.stats entries later than lastreport
	set newlast = 0;
	for each row ps in master.probestats where ps.SeqNos > lastseq_probe
	begin
		write into probestats_report values (
			to_char( ps.StatTime ) + ': master.probestats report:' );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': ProbeId: ' + ps.ProbeId );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': ProbeAgent: ' + ps.ProbeAgent );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': ProbeHost: ' + ps.ProbeHost );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': ProbeUpTime: ' + to_char( ps.ProbeUpTime ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': ProbePID: ' + to_char( ps.ProbePID ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': NumEventsProcessed: ' + to_char( ps.NumEventsProcessed ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': NumEventsGenerated: ' + to_char( ps.NumEventsGenerated ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': NumEventsDiscarded: ' + to_char( ps.NumEventsDiscarded ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': RulesFileTimeSec: ' + to_char( ps.RulesFileTimeSec ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': AvgRulesFileTime: ' + to_char( ps.AvgRulesFileTime ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': CPUTimeSec: ' + to_char( ps.CPUTimeSec ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': ProbeMemory: ' + to_char( ps.ProbeMemory ) );
		write into probestats_report values (
			to_char( ps.StatTime ) + ': master.probestats report end' );

		if( ps.SeqNos > newlast ) then
			-- Keep track of greatest ps.SeqNos value we have processed
			set newlast = ps.SeqNos;
		end if;
	end;
	if( newlast > lastseq_probe ) then
		-- Store greatest ps.SeqNos value we have processed, to be updated later
		set lastseq_probe = newlast;
	end if;
	-- Update master.activity_probestats entry, delete existing entry
	delete from master.activity_probestats where ReportAgent='objservlog';
	insert into master.activity_probestats values ( 'objservlog', lastseq_probe, lastreport );
end;
go

--
-- Delete probe statistics that are over an hour old.
-- The trigger is disabled by default.
--
create or replace trigger probe_statistics_cleanup
group stats_triggers
enabled false
priority 20
comment 'Delete probe statistics over an hour old'
every 1 hours
begin
	delete from master.probestats where StatTime < (getdate() - 3600);
end;
go

--
-- Signal trigger that handles the raising of the
-- statistics reset signal
-- probestats version
--
create or replace trigger probestats_reset
group stats_triggers
enabled true
priority 2
comment 'Reset the probe statistics data'
on signal stats_reset
begin
	delete from master.probestats;
	delete from master.activity_probestats;
	insert into master.activity_probestats values ( 'objservlog', 1, 0);
end;
go


--
-- Simple cancel trigger for deduplicated probestats entries
--
create or replace trigger deduplicate_probestats
group stats_triggers
enabled true
priority 1
comment 'Handle duplicate rows on master.probestats'
before reinsert on master.probestats
for each row
begin
	cancel; -- Do nothing. Allow the new row to be discarded
end;
go

--
-- Push data from probestat (re)inserts into appropriate fields in master.probestats
--
create or replace procedure probestats_data ( in rowdata row of alerts.status )
declare
	ProbePID	int;
	StatTime	int;
begin
	-- copy data out into new row in master.probestats
	set ProbePID=to_int( nvp_get( rowdata.ExtendedAttr, 'ProbePID' ));
	set StatTime=to_int( nvp_get( rowdata.ExtendedAttr, 'StatTime' ));
	insert into master.probestats
		( KeyField,
			StatTime, ProbeUpTime, ProbeAgent, ProbeHost,
			ProbeId, ProbePID,
			NumEventsProcessed,
			NumEventsGenerated,
			NumEventsDiscarded,
			RulesFileTimeSec,
			AvgRulesFileTime,
			CPUTimeSec,
			ProbeMemory ) values
		( rowdata.Agent+'@'+rowdata.Node+':'+to_char( StatTime )+':'+to_char( ProbePID ),
			StatTime, to_int(nvp_get( rowdata.ExtendedAttr, 'ProbeUpTime' )), rowdata.Agent,
			rowdata.Node, rowdata.Agent+'@'+rowdata.Node, ProbePID,
			to_int( nvp_get( rowdata.ExtendedAttr, 'NumEventsProcessed' ) ),
			to_int( nvp_get( rowdata.ExtendedAttr, 'NumEventsGenerated' ) ),
			to_int( nvp_get( rowdata.ExtendedAttr, 'NumEventsDiscarded' ) ),
			to_int( nvp_get( rowdata.ExtendedAttr, 'RulesFileTimeSec' ) ),
			to_int( nvp_get( rowdata.ExtendedAttr, 'AvgRulesFileTime' ) ),
			to_int( nvp_get( rowdata.ExtendedAttr, 'CPUTimeSec' ) ),
			to_int( nvp_get( rowdata.ExtendedAttr, 'ProbeMemory' ) )
		);
	-- done
end;

--
-- Trap probestat events and push data into appropriate fields
--
create or replace trigger probestat_insert
group stats_triggers
enabled true
priority 2
comment 'Trap probestat events and copy data to master.probestats table'
before insert on alerts.status
for each row
begin
	-- probestat event sent by Heartbeat section of probewatch.include
	if( new.Identifier = 'probestat' ) then
		-- call the common probestats_data procedure on this row
		call procedure probestats_data ( new );
		-- cancel causes the alerts.status insert to be dropped
		cancel;
	end if;
end;
go

--
-- Trap probestat reinserts (in case row already exists)
--
-- Note: Changes to this trigger should also be made to probestat_insert above
--
create or replace trigger probestat_reinsert
group stats_triggers
enabled true
priority 2
comment 'Trap probestat events and copy data to master.probestats table'
before reinsert on alerts.status
for each row
begin
	-- probestat event sent by Heartbeat section of probewatch.include
	if( new.Identifier = 'probestat' ) then
		-- call the common probestats_data procedure on this row
		call procedure probestats_data ( new );
		-- cancel causes the alerts.status insert to be dropped
		cancel;
	end if;
end;
go
