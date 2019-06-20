-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2009. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Temporary table to work with connections
------------------------------------------------------------------------

create table iduc_system.temp_connections virtual
(
        ConnectionId int primary key,
        AppName varchar(40),
        AppDesc varchar(128),
        Pending int
);
go

------------------------------------------------------------------------
-- Controlled Shutdown procedures and triggers
------------------------------------------------------------------------

create or replace trigger group control_shutdown_triggers;
go

alter trigger group control_shutdown_triggers set enabled false;
go

create or replace procedure disable_control_shutdown()
begin
	alter trigger group control_shutdown_triggers set enabled false; 
end;
go

create or replace procedure enable_control_shutdown()
begin
	alter trigger group control_shutdown_triggers set enabled true;
end;
go


------------------------------------------------------------------------
-- Signal trigger to block client connections after control_shutdown
-- Priority of default connection_watch_connect trigger is altered to 2
-- in order to cancel action of connection_watch_connect if client is blocked.
------------------------------------------------------------------------
alter trigger connection_watch_connect set priority 2;
go

create or replace trigger block_clients_during_control_shutdown
group control_shutdown_triggers 
debug false
enabled true
priority 1
comment 'Trigger to block new client connections if OS is undergoing controlled shutdown'
on signal connect
begin
	if (	%signal.process <> 'isql' and 
		%signal.process <> 'GET_LOGIN_TOKEN' )
	then 
		alter system drop connection %signal.connectionid;
	end if;
end;
go

-----------------------------------------------------------------------
-- External procedure to shutdown OS using nco_pa_stop
-- 'omnihost' -  need to be replaced with hostname where external procedure
-- 		 will be executed.
-- 'user' - user name to execute external procedure
-- 'group' - group name to execute external procedure. 
-----------------------------------------------------------------------

create or replace procedure ext_shutdown (in process_name Char(255), in username Char(255), in pass Char(255), in paserver Char(255)) 
executable '$OMNIHOME/bin/nco_pa_stop'
host  'omnihost'  
user 0 group 0 
arguments ' -process ' + process_name +  ' -user ' + username + ' -password ' + pass + ' -server ' + paserver
go

------------------------------------------------------------------------
-- Procedure to drop and flush connections for controlled shutdown
------------------------------------------------------------------------

create or replace procedure control_shutdown()
declare
	iduc_clients int;
begin
	set iduc_clients = 0;

	-- Delete any data from temporary connections table

	delete from iduc_system.temp_connections;

	-- Populate temporary connections table from catalog.connections

	for each row cnxn in catalog.connections
	begin
		insert into iduc_system.temp_connections ( ConnectionId, AppName, AppDesc, Pending )
				values ( cnxn.ConnectionID, cnxn.AppName, cnxn.AppDescription, 0);
	end;

	-- set Pending = 1 for clients that need IDUC flush

	for each row conniduc in iduc_system.iduc_stats where conniduc.ServerName = getservername()
	begin
		update iduc_system.temp_connections set Pending = 1 where ConnectionId = conniduc.ConnectionId
				and AppDesc = conniduc.AppDesc and AppName = conniduc.AppName;
	end;

	-- Enable trigger to check if GET IDUC is finished for all the clients.
	execute procedure enable_control_shutdown;

	-- Drop or Flush client depending on Pending flag
	
	for each row conntemp in iduc_system.temp_connections
	begin
		if( conntemp.Pending = 0 )
		then
			-- Drop all Non-IDUC client connections
			alter system drop connection conntemp.ConnectionId;
		else
			-- Send IDUC flush to clients 
			iduc flush conntemp.ConnectionId;
			set iduc_clients = iduc_clients + 1;
		end if;
	end;
	if ( iduc_clients = 0 )
	then
		-- Disable trigger to check if GET IDUC is finished for all the clients.
		execute procedure disable_control_shutdown;

		-- call external procedure to shutdown OS using nco_pa_stop
		-- Replace 'MasterObjectServer' with ObjectServer process name in PA conf file
		-- Replace 'USERNAME' with username to execute nco_pa_stop.
		-- Replace 'PASSWORD' with password to execute nco_pa_stop.
		-- Replace 'PASERVER' with PA server name to connect.
		execute procedure ext_shutdown ( 'MasterObjectServer', 'USERNAME', 'PASSWORD', 'PASERVER' );
	end if;
end;
go

------------------------------------------------------------------------------
-- Trigger to reset Pending flag on  GET IDUC from all clients
-----------------------------------------------------------------------------

create or replace trigger final_shutdown
group control_shutdown_triggers
enabled true 
priority 2
comment 'Trigger to reset Pending flag in case of controlled shutdown'
on signal iduc_data_fetch
declare
	pending_cnt int;
begin
	set pending_cnt = 0;

	-- Update Pending flag for client who sent GET IDUC request.
	
	update iduc_system.temp_connections set Pending = 0 where ConnectionId = %signal.connectionid;

	-- Now check if we have pending flag cleared for all the clients

	for each row conntemp in iduc_system.temp_connections where conntemp.Pending = 1
	begin
		set pending_cnt = pending_cnt+1;
	end;
	
	if( pending_cnt = 0 ) then
		-- disable this trigger group and shutdown ObjectServer.
		execute procedure disable_control_shutdown;
                -- call external procedure to shutdown OS using nco_pa_stop
                -- Replace 'MasterObjectServer' with ObjectServer process name in PA conf file 
		-- Replace 'USERNAME' with username to execute nco_pa_stop.
		-- Replace 'PASSWORD' with password to execute nco_pa_stop.
		-- Replace 'PASERVER' with PA server name to connect.
		execute procedure ext_shutdown ( 'MasterObjectServer', 'USERNAME', 'PASSWORD', 'PASERVER' );
	end if;
end;
go

