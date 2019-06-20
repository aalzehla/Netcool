-------------------------------------------------------------------------------
-- Probe rules management triggers: probe_management
-------------------------------------------------------------------------------

-- The probe management triggers write events in the 'Probe management' alert group to the probe management log file.
-- They will redirect probewatch messages relevant to rules file management to the log. Probes are required 
-- to include the 'probewatch.include' file.

create trigger group probe_management;
go

alter trigger group probe_management set enabled true;
go

create or replace file probemanagementlog getenv('OMNIHOME') + '/log/' + getservername() + '_probemanagement.log'  maxfiles 2 maxsize 10m;
go

--
-- Log  probe watch messages about rules management
--
create or replace trigger probeevent_insert
group probe_management
enabled true
priority 2
comment 'Redirect probe management events to log file'
before insert on alerts.status for each row
declare
	now utc;
begin
	-- Rules event sent by extensions/roi/probewatch.include
	if( new.Manager = 'ProbeWatch' and new.AlertGroup = 'Probe management' ) then
		set now = getdate();
		write into probemanagementlog values(to_char(now) + ' ' + new.Summary);
	end if;
end;
go

--
-- Log probe watch messages about rules management
--
create or replace trigger probeevent_reinsert
group probe_management
enabled true
priority 2
comment 'Redirect probe management events to log file'
before reinsert on alerts.status for each row
declare
	now utc;
begin
	-- Rules event sent by extensions/roi/probewatch.include
	if( new.Manager = 'ProbeWatch' and new.AlertGroup = 'Probe management' ) then
		set now = getdate();
		write into probemanagementlog values(to_char(now) + ': ' + new.Summary);
	end if;
end;
go

--
-- Request a probe reloads its rules file
-- Requires remote management is enabled in the probe.
---
-- Usage: 
-- call do_probereloadrules address port
-- where 'address' is the host running the probe and 'port' the probe's HTTP interface port.
--
create or replace procedure do_probereloadrules ( in address character(1), in port integer )
  executable '$OMNIHOME/bin/nco_probereloadrules'
  host 'localhost'
  user 0 group 0
  arguments '-host ' + address + ' -port ' + to_char(port);
go

--
-- Request a probe reloads its rules file
-- Requires remote management is enabled in the probe.
---
-- Usage: 
-- call do_probereloadrules address port
-- where 'address' is the host running the probe and 'port' the probe's HTTPS interface port.
--
create or replace procedure do_probereloadrulesusingssl( in address character(1), in port integer )
	executable '$OMNIHOME/bin/nco_probereloadrules'
  	host 'localhost'
  	user 0 group 0
  	arguments '-host ' + address + ' -port ' + to_char( port )  + ' -ssl';
go

--
-- Request all registered probes reload their rules.
-- Requires probes have remote management enabled.
--
-- Usage: 
-- call reloadrules_allprobes
--
create or replace procedure reloadrules_allprobes()
declare
	requests_sent	int;
  	http_inactive int;
  	not_running   int;
  	now           utc;
begin
	set now = getdate();
  	write into probemanagementlog values(to_char(now) + ' ' + 'Reload all probe rules request ');
  
  	-- refresh all registered probes
  	for each row probe in registry.probes
  	begin
     		-- A status of 1 means the probe is running
    		if( probe.Status = 1 )
    		then
			if( probe.HTTPS_port != 0 )
			then
				execute do_probereloadrulesusingssl( probe.Hostname, probe.HTTPS_port );
				set now = getdate();
				write into probemanagementlog values( to_char(now) + ' Sent HTTPS reload rules request to ' + probe.Name + ' on ' + probe.Hostname + ':' + to_char(probe.HTTPS_port) );
				set requests_sent = requests_sent + 1;
		 	elseif( probe.HTTP_port!=0 )
			then
				execute do_probereloadrules( probe.Hostname, probe.HTTP_port );
				set now = getdate();
				write into probemanagementlog values( to_char(now) + ' Sent HTTP reload rules request to ' + probe.Name + ' on ' + probe.Hostname + ':' + to_char(probe.HTTP_port) );
				set requests_sent = requests_sent + 1;
			else
				set now = getdate();
				write into probemanagementlog values( to_char(now) + ' HTTP interface not active for ' + probe.Name + ' on ' + probe.Hostname );
				set http_inactive = http_inactive + 1;	
			end if;
    		else
			set now = getdate();
			write into probemanagementlog values( to_char(now) + ' ' +  probe.Name + ' on ' + probe.Hostname + ' is not running' );
			set not_running = not_running + 1;	
    		end if;
  	end;
  	set now = getdate();
  	write into probemanagementlog values( to_char(now) +  ' Reload all rules summary: managed probes ' + to_char(requests_sent) + ', unmanaged probes ' + to_char(http_inactive) + ', probes not running ' + to_char(not_running) );
end;
go

