-------------------------------------------------------------------------
--
--	Licensed Materials - Property of IBM
--
--	5724O4800
--
--	(C) Copyright IBM Corp. 1994, 2007. All Rights Reserved
--
--	US Government Users Restricted Rights - Use, duplication
--	or disclosure restricted by GSA ADP Schedule Contract
--	with IBM Corp.
--
--	Ident: $Id: desktopserver.sql 1.4 2003/09/05 16:57:32 stephenc Development $
--
------------------------------------------------------------------------

--
-- Desktop server configuration
--
create table master.national persistent
(
	KeyField	incr primary key,
	MasterServer	varchar(29),
	DualWrite	int
);
go

grant select on table master.national to role 'Normal';
grant role 'Normal' to group 'Normal';
grant role 'Normal' to group 'Administrator';
go

alter table alerts.status add column MasterSerial int;
go

-- Disable standard triggers.
alter trigger group default_triggers set enabled false;
alter trigger group automatic_backup_system set enabled false;
alter trigger group profiler_triggers set enabled false;
alter trigger group connection_watch set enabled false;
alter trigger group sae set enabled false;



create or replace trigger group dsd_triggers;
go

-- Enable cleanup triggers to handle orphaned journals and details
alter trigger clean_journal_table set group dsd_triggers;
alter trigger clean_details_table set group dsd_triggers;
go

create or replace trigger prevent_desktop_inserts
group dsd_triggers
priority 1
comment 'Stop the eventlist inserting new rows into the desktop server.'
before insert on alerts.status
for each row
begin
        if ( %user.is_eventlist = true ) then
              cancel;
        end if
end;
go

create or replace trigger dsd_state_change
group dsd_triggers
priority 1
comment 'State change processing for ALERTS.STATUS in a desktop server setup - required by the Web GUI'
before update on alerts.status
for each row
begin
	set new.StateChange = getdate();
end;
go

create or replace trigger deduplicate_journal
group dsd_triggers
priority 10
comment 'Deduplication for journal entries'
before reinsert on alerts.journal
for each row
begin
	set row old = new;
end;
go

