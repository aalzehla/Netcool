-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 1994, 2007. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--      Ident: $Id: automation.sql 1.21 2003/10/02 11:04:13 ianj Development ianj $
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SQL file contains schema, data and automation changes to be applied
-- to a 7.0.x ObjectServer instance to bring it up to v7.1
--
--  The contents of this file should be reviewed prior to adding it to 
--  the ObjectServer.
--  Applying this file may cause automations to be replaced, meaning
--  any customization of the automations will be lost
--
--  Prior to applying this file, it is advisable to backup your 
--  ObjectServer instance
--
------------------------------------------------------------------------


ALTER TABLE alerts.status ALTER COLUMN AlertGroup SET WIDTH 255;
ALTER TABLE alerts.status ALTER COLUMN EventId SET WIDTH 255;
go

update alerts.col_visuals set DefWidth = 20, MaxWidth = 255 where Colname = 'EventId';
update alerts.col_visuals set DefWidth = 18, MaxWidth = 255 where Colname = 'AlertGroup';
go

-- This table is used to send i18n safe IDUC client messages.
create table alerts.iduc_messages virtual
(
	MsgID		int primary key,
 	MsgText		varchar(4096),
 	MsgTime		time
);
go

 
-- Create a table of application types that will drive the connection watch messages
-- Database supports the definition of Alert Type and Severity to be used for 
-- connection and disconnection alerts.
--
-- Typically a client will create a Type 1 event on Connection, 
-- and a type 2 (Clear) for a disconnect
-- A probe or Gateway will create a Type 1 event warning for a disconnect, 
-- and a type 2 (clear) on a connect.
--
create table alerts.application_types persistent
(
         application             varchar(64) primary key, -- The internal application name as a regular expression for efficient string match
         description		varchar(64), -- The textual name for the alarm
         connect_type            int, -- The alarm type for the connect
         connect_severity        int, -- The alarm severity for the connect
         disconnect_type         int, -- The alarm type for the disconnect
         disconnect_severity     int, -- The alarm severity for the disconnect
         expire_time	integer, -- The expire time to be set (normally 0)
         discard	boolean -- True if the Alert is to be suppressed
);
go
 
-- Default entries for trigger behaviour, add to, or amend these as required.
insert into alerts.application_types values ('^f@','Unix nco_admin',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT Admin@','Windows Administration',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT User Administration','Windows User Administration',1,2,2,1,0,false);
insert into alerts.application_types values ('^isql','isql',1,3,2,1,0,false);
insert into alerts.application_types values ('^sqsh','sqsh',1,3,2,1,0,false);
insert into alerts.application_types values ('^o@','Unix Objective View',1,2,2,1,0,false);
insert into alerts.application_types values ('^Java','Java client',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT Objective View@','Windows Objective View',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT NCOELCT','Windows ELCT',1,2,2,1,0,false);
insert into alerts.application_types values ('^Impact','Impact',1,2,2,1,0,false);
insert into alerts.application_types values ('^JJELD','JJELD',1,2,2,1,0,false);
insert into alerts.application_types values ('^PROBE','Probe',2,1,1,5,0,false);
insert into alerts.application_types values ('^MONITOR','Monitor',2,1,1,5,0,false);
insert into alerts.application_types values ('^GATEWAY','Gateway',2,1,1,5,0,false);
insert into alerts.application_types values ('^PROXY','Proxy Server',2,1,1,5,0,false);
insert into alerts.application_types values ('^JELD','JELD',1,2,2,1,0,false);
insert into alerts.application_types values ('^e@','Unix Event List',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT Event List@','Windows Event List',1,2,2,1,0,false);
insert into alerts.application_types values ('^ctisql','Unix nco_sql',1,3,2,1,0,false);
insert into alerts.application_types values ('^v@','Unix Objective View Editor',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT Conductor','Windows Conductor',1,2,2,1,0,false);
insert into alerts.application_types values ('^NT Event List','Windows Event List',1,2,2,1,0,false);
insert into alerts.application_types values ('^c@','Unix Conductor',1,2,2,1,0,false);
insert into alerts.application_types values ('^GET_LOGIN_TOKEN','GET_LOGIN_TOKEN',1,2,2,1,0,true);
insert into alerts.application_types values ('^JavaAdmin','Administration Tool',1,2,2,1,0,false);
go
 

create or replace trigger group iduc_triggers;
go
 
------------------------------------------------------------------------
-- Signal triggers: connection_watch
------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- This trigger replaces the 7.0 connection_watch_disconnect trigger
-- The existing trigger should be disabled and this one enabled if you wish
-- to use the updated trigger
--------------------------------------------------------------------------------

create or replace trigger connection_watch_disconnect2
group connection_watch 
debug false 
enabled false
priority 1
comment 'Create an alert when a client disconnects\nThe process name identified by the signal is matched against the applications table to identify the appropriate severity and event type for the disconnect.\nA gateway disconnection for example is treated as a problem, where as an eventlist disconnect is a resolution'
on signal disconnect
declare
	-- Define variables
	cseverity	int;
	alert_type	int;
	app_found	boolean;
	app_group	char(64);
begin
	-- Initialise variables to defaults 
	set cseverity = 2;
	set alert_type = 2;
	set app_found = FALSE;

	-- Some clients may not provide signal descriptions. For simplicity the Summary 
	-- format assumes that a description will be present. first set indicators that 
	-- determine which format of event to write and the Severity and Type for 
	-- the event
	for each row my_app in alerts.application_types where %signal.process like my_app.application
	begin
		if (my_app.discard = TRUE) then
			cancel;
		end if;
		set cseverity = my_app.disconnect_severity;
		set alert_type = my_app.disconnect_type;
		set app_group = my_app.description;
		set app_found = TRUE;
		break;
	end;
	if (%signal.process = 'PROBE' and %signal.description = 'syntax') then
	-- For a syntax check this is a test connection event that will clear 
	-- very quickly, set as a problem event over-riding the normal values 
	-- for a probe connect
			set alert_type = 2;
			set cseverity = 1;
	end if;
	
	-- No entry in the table for the process
	if ( app_found = FALSE ) then
		-- An unknown process, that doesn't have a name associated is
		-- disconnecting
		if  ( %signal.process = '' ) then
			set app_group = 'Unknown Application';
		else
		-- We don't have an entry in the table for the application but 
		-- it has supplied a non-null application name which we will use
			set app_group = %signal.process;
		end if;
	end if;
	
	if (%signal.username = '') then
		insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey, OwnerUID) values (%signal.process+':'+%signal.description+'@'+%signal.node+'disconnected '+to_char(%signal.at), 'A '+%signal.process+' process '+%signal.description+' running on '+%signal.node+' has disconnected', %signal.node, 'ConnectionWatch', alert_type, cseverity, %signal.at, %signal.at, app_group, %signal.process+':'+%signal.description, 65534);
	else
		insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey, OwnerUID) values (%signal.process+':'+%signal.description+'@'+%signal.node+'disconnected'+to_char(%signal.at), 'A '+%signal.process+' process '+%signal.description+' running on '+%signal.node+' has disconnected as username '+%signal.username, %signal.node, 'ConnectionWatch', alert_type, cseverity, %signal.at, %signal.at,app_group, %signal.process+':'+%signal.description, 65534);
	end if;
end;
go

--------------------------------------------------------------------------------
-- This trigger replaces the 7.0 connection_watch_connect trigger
-- The existing trigger should be disabled and this one enabled if you wish
-- to use the updated trigger
--------------------------------------------------------------------------------

create or replace trigger connection_watch_connect2 
group connection_watch 
debug false 
enabled false
priority 1
comment 'Create an alert when a new client connects\nThe process name identified by the signal is matched against the applications table to identify the appropriate severity and event type for the connect.\nA gateway connection for example is treated as a resolution (clearing a disconnect), whereas an eventlist connect is a Type 1 event which will be resolved by a disconnect) '
on signal connect
declare
	-- Define variables
	cseverity	int;
	alert_type	int;
	expire_time	int;
	app_found	boolean;
	app_group	char(64);
begin
	-- Initialise variables to defaults 
	set cseverity = 2;
	set alert_type = 1;
	set expire_time = 0;
	set app_found = FALSE;

	-- Some clients may not provide signal descriptions. For simplicity the 
	-- Summary format assumes that a description will be present. First set 
	-- indicators that determine which format of event to write and the 
	-- Severity and Type for the event

	for each row my_app in alerts.application_types where %signal.process like my_app.application
	begin
		if (my_app.discard = TRUE) then
			cancel;
		end if;
		set cseverity = my_app.connect_severity;
		set alert_type = my_app.connect_type;
		set app_group = my_app.description;
		set app_found = TRUE;
		break;
	end;
	if (%signal.process = 'PROBE' and %signal.description = 'syntax') then
	-- For a syntax check this is a test connection event that will clear 
	-- very quickly, set as a problem event over-riding the normal values 
	-- for a probe connect
		set alert_type = 1;
		set cseverity = 1;
		set expire_time = 180;
	end if;

	-- No entry in the table for the process
	if ( app_found = FALSE ) then
		-- An unknown process, that doesn't have a name associated
		-- with it has connected. Insert the event with a high severity
		if  ( %signal.process = '' ) then
			set app_group = 'Unknown Application';
			set cseverity = 4;
		else
		-- We don't have an entry in the table for the application but 
		-- it has supplied a non-null application name which we will use
			set app_group = %signal.process;
		end if;
	end if;

	if (%signal.username = '') then
		insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey, OwnerUID, ExpireTime) values (%signal.process+':'+%signal.description+'@'+%signal.node+' connected '+to_char(%signal.at), 'A '+%signal.process+' process '+%signal.description+' running on '+%signal.node+' has connected', %signal.node, 'ConnectionWatch', alert_type, cseverity, %signal.at, %signal.at, app_group, %signal.process+':'+%signal.description, 65534, expire_time);
	else
		insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey, OwnerUID,ExpireTime) values (%signal.process+':'+%signal.description+'@'+%signal.node+'connected'+to_char(%signal.at), 'A '+%signal.process+' process '+%signal.description+' running on '+%signal.node+' has connected as username '+%signal.username, %signal.node, 'ConnectionWatch', alert_type, cseverity, %signal.at, %signal.at,app_group, %signal.process+':'+%signal.description, 65534,expire_time);
	end if;
end;
go

 
--------------------------------------------------------------------------------
-- This procedure replaces the 7.0 jinsert procedure.
-- This version is safe to use with multibyte data.
-- 
--------------------------------------------------------------------------------
--
-- Procedure inserts a record into the alerts.journal table. Automations that 
-- require journal entries should execute this procedure.
--
-- Usage:  
--  call procedure jinsert( old.Serial, %user.user_id, getdate, 'This is my journal entry');
--
create or replace procedure jinsert
( in serial int,
  in uid int,
  in tstamp utc,
  in msg char(4080) )
begin
--
-- Procedure inserts a record into the alerts.journal table. Automations that 
-- require journal entries should execute this procedure.
--
-- Usage:  
--  call procedure jinsert( old.Serial, %user.user_id, getdate, 'This is my journal entry');
--
        insert into alerts.journal values (
		journal_keyfield( to_int( serial ), to_int( uid ), tstamp ), -- KeyField
                serial,                         -- Serial
                uid,                            -- UID
                tstamp,                         -- Chrono
                split_multibyte(msg, 1, 255),   -- Text1
                split_multibyte(msg, 2, 255),   -- Text2
                split_multibyte(msg, 3, 255),   -- Text3
                split_multibyte(msg, 4, 255),   -- Text4
                split_multibyte(msg, 5, 255),   -- Text5
                split_multibyte(msg, 6, 255),   -- Text6
                split_multibyte(msg, 7, 255),   -- Text7
                split_multibyte(msg, 8, 255),   -- Text8 
                split_multibyte(msg, 9, 255),   -- Text9 
                split_multibyte(msg, 10, 255),  -- Text10
                split_multibyte(msg, 11, 255),  -- Text11
                split_multibyte(msg, 12, 255),  -- Text12
                split_multibyte(msg, 13, 255),  -- Text13
                split_multibyte(msg, 14, 255),  -- Text14
                split_multibyte(msg, 15, 255),  -- Text15
                split_multibyte(msg, 16, 255)   -- Text16
	);
end;
go

------------------------------------------------------------------------
-- Automation triggers: iduc_triggers
------------------------------------------------------------------------
create or replace trigger iduc_messages_tblclean
group iduc_triggers
priority 1
comment 'Housekeeping cleanup of ALERTS.IDUC_MESSAGES'
every 60 seconds
begin
	delete from alerts.iduc_messages where (MsgTime + 120) <= getdate;
end;
go

grant select on table alerts.iduc_messages to role 'AlertsUser';
grant delete on table alerts.iduc_messages to role 'DesktopAdmin';
go
