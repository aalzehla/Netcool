drop trigger objserv_stats_update
go

drop trigger deduplicate_perf_per_minute
go

drop trigger flood_check
go

drop procedure set_prop_all_probes;
go

drop procedure set_probe_prop_http;
go

drop procedure set_probe_prop_https;
go

delete from master.performance_stats
go

drop table master.performance_stats
go

delete from master.perf_per_minute
go

drop table master.perf_per_minute
go

create or replace file flood_control getenv('OMNIHOME') + '/log/' + getservername + 'FloodControl.log' maxfiles 2 maxsize 1m;
go

alter trigger group stats_triggers set enabled true;
go

--Store the information to work out the rates
create table master.performance_stats virtual
(
	DatabaseName		varchar(64) primary key,
	LastUpdate		UTC,
	EventCount		int,
	TriggerTimeCount	Real
);
go

--Store the rates over time to dampen the effect of performance
--spikes. Defaultly set to 5 rows by the objserv_stats_update trigger
create table master.perf_per_minute virtual
(
	Minute 			int primary key,
	EventRate		Real,
	TriggerPercent		Real,
	ClientPercent		Real
);
go

-- We need to be able to control probe properties using the bi-dir
-- interface. Any username or password for the bi-dir http interface
-- can be stored in $OMNIHOME/etc/nco_http.props
create or replace procedure set_probe_prop_http(in hostname char(255), in port int, in name char(255), in value char(255))
executable '$OMNIHOME/bin/nco_setprobeprop'
host 'localhost'
user 0
group 0
arguments '-host', '\''+hostname+'\'', '-port', to_char(port), '-name', '\'' + name + '\'', '-value', '\'' + value + '\'';
go

create or replace procedure set_probe_prop_https(in hostname char(255), in port int, in name char(255), in value char(255))
executable '$OMNIHOME/bin/nco_setprobeprop'
host 'localhost'
user 0
group 0
arguments '-ssl', '-host', '\''+hostname+'\'', '-port', to_char(port), '-name', '\'' + name + '\'', '-value', '\'' + value + '\'';
go

create or replace procedure set_prop_all_probes
(
	in name char(255),
	in value char(255)
)
begin
	for each probe in registry.probes
	begin
		if ( probe.HTTPS_port != 0 )
		then
			execute set_probe_prop_https(probe.Hostname, probe.HTTPS_port,
								name, value);
		else
			execute set_probe_prop_http(probe.Hostname, probe.HTTP_port,
								name, value);
		end if
	end;
end;
go

create or replace trigger deduplicate_perf_per_minute
group stats_triggers
priority 20
comment 'Deduplication to allow wrapping of performance data'
before reinsert on master.perf_per_minute
for each row
begin
	set old.EventRate = new.EventRate;
	set old.TriggerPercent = new.TriggerPercent;
	set old.ClientPercent = new.ClientPercent;
end;
go

--Collect performance information from information available
--internally to the object server.
create or replace trigger objserv_stats_update
group stats_triggers
priority 19
comment 'Calculate the current load on this object server'
on signal profiler_report
declare
	elapsed 		UTC;
	first_run 		boolean;
	current_event_count 	integer;
	current_trigger_time 	real;
	current_client_time 	real;
	window_size		integer;
begin
	--The size of our timing window. If this number is larger then the
	--system will have greater insulation against performance spikes
	set window_size = 5;

	set first_run = true;

	--Count the event tallies
	set current_event_count = 0;
	for each row srow in master.activity_stats where srow.DatabaseName = 'alerts'
	begin
		set current_event_count = srow.StatusNewInserts + srow.StatusDedups + srow.JournalInserts + srow.DetailsInserts;
	end;

	--Count time in of all the triggers
	set current_trigger_time = 0.0;
	for each row srow in catalog.trigger_stats
	begin
		set current_trigger_time = current_trigger_time + srow.TotalTime;
	end;

	--Read the average client time
	set current_client_time = 0.0;
	for each row srow in catalog.profiles where srow.AppName = 'PROBE'--where probe or proxy
	begin
		set current_client_time = current_client_time + srow.PeriodSQLTime;
	end;


	--Read the single row of master.performance_stats
	for each row mrow in master.performance_stats
	begin
		--Calculate the time that has elapsed since the last call of this trigger
		set elapsed = getdate() - mrow.LastUpdate;
		insert into master.perf_per_minute values(mod(minuteofhour(), window_size) , to_real((current_event_count - mrow.EventCount)) / to_real(elapsed) , (current_trigger_time - mrow.TriggerTimeCount) / to_real(elapsed), current_client_time / to_real(elapsed));
		update master.performance_stats via 'alerts' set LastUpdate = getdate(), EventCount = current_event_count , TriggerTimeCount = current_trigger_time;

		set first_run = false;
	end;

	--If this is the first run of this trigger then we enter the initial measurements
	--into the performance_stats table
	if(first_run = true) then
		insert into master.performance_stats values('alerts', getdate(), current_event_count ,current_trigger_time);
	end if;
end;
go


create or replace trigger flood_check
group stats_triggers
priority 20
comment 'Determine if the system is current in flood'
on signal profiler_report
declare
	row_count		int;
	avg_event_rate		real;
	avg_trigger_per		real;
	avg_client_per		real;
	in_flood		boolean;
	was_in_flood		boolean;
	flood_start_time	UTC;
	elapsed			UTC;
begin
	set row_count = 0;
	set avg_event_rate = 0.0;
	set avg_trigger_per = 0.0;
	set avg_client_per = 0.0;

	--Add up all of the metrics stored in perf_per_minute
	for each row srow in master.perf_per_minute
	begin
		set avg_event_rate = avg_event_rate + srow.EventRate;
		set avg_trigger_per = avg_trigger_per + srow.TriggerPercent;
		set avg_client_per = avg_client_per + srow.ClientPercent;
		set row_count = row_count + 1;
	end;

	--Calculate the average of each metric over our time window
	if (row_count > 0)
	then
		set avg_event_rate = avg_event_rate / to_real(row_count);
		set avg_trigger_per = avg_trigger_per / to_real(row_count);
		set avg_client_per = avg_client_per / to_real(row_count);
	end if;

	--Remember if we were in flood.
	set was_in_flood = in_flood;
	set in_flood = FALSE;

	--50% of time spent in triggers (30 seconds in 60 seconds)
	if( avg_trigger_per >= 0.5 )
	then
		set in_flood = TRUE;
	end if;

	--66% of time processing clients (40 seconds in 60 seconds)
	if( avg_client_per >= 0.66 )
	then
		set in_flood = TRUE;
	end if;

	--Calculate how much time has elapsed since we entered flood.
	set elapsed = getdate() - flood_start_time;
	if( in_flood = TRUE )
	then
		if( was_in_flood = TRUE )
		then
			--already in flood control
			write into flood_control values ( avg_event_rate, ' ' , avg_trigger_per, ' ' , avg_client_per, ' Still elapsed is: ' , elapsed);
		else
			--trigger flood control now
			write into flood_control values ( avg_event_rate, ' ' , avg_trigger_per, ' ' , avg_client_per, ' True');
			exec set_prop_all_probes('FloodControl', 'flood');
			insert into alerts.status (
				Identifier,
				Summary,
				Node,
				Manager,
				Type,
				Severity,
				FirstOccurrence,
				LastOccurrence,
				AlertGroup,
				AlertKey,
				Agent,
				OwnerUID)
			values (
				'ObjectServer_flood_beginning@' + getservername(),
				'ObjectServer ' + getservername() + ' is currently in flood',
				get_prop_value('Hostname'),
				'FloodControl',
				1,
				5,
				getdate(),
				getdate(),
				'nco_objserv',
				getservername(),
				'FloodControl',
				65534);
			--Remember when the flood started
			set flood_start_time = getdate();
		end if;
	else
		--Only turn off flood control after 5 minutes of it being on.
		if( elapsed >= 300 )
		then
			--turn off flood control
			write into flood_control values ( avg_event_rate, ' ' , avg_trigger_per, ' ' , avg_client_per, ' False');
			if( was_in_flood = TRUE )
			then
				write into flood_control values ( avg_event_rate, ' ' , avg_trigger_per, ' ' , avg_client_per, ' False and send message');
				exec set_prop_all_probes('FloodControl', 'normal');
				insert into alerts.status (
					Identifier,
					Summary,
					Node,
					Manager,
					Type,
					Severity,
					FirstOccurrence,
					LastOccurrence,
					AlertGroup,
					AlertKey,
					Agent,
					OwnerUID)
				values (
					'ObjectServer_flood_ending@' + getservername(),
					'ObjectServer ' + getservername() + ' is ending flood control',
					get_prop_value('Hostname'),
					'FloodControl',
					2,
					1,
					getdate(),
					getdate(),
					'nco_objserv',
					getservername(),
					'FloodControl',
					65534);
			end if;
		else
			--We have dropped below the flood thresholds but would like to stay in flood control for a minimum of 5 minutes
			write into flood_control values ( avg_event_rate, ' ' , avg_trigger_per, ' ' , avg_client_per, ' False but waiting to disengage. Elapsed is: ' , elapsed);
			--It is important to remember we are still in flood
			set in_flood = TRUE;
		end if;
	end if;
end;
go

