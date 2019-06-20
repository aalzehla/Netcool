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
-- SQL file contains schema, data and automation changes to be applied
-- to a 7.2.x ObjectServer instance to bring it up to v7.3
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



ALTER TABLE alerts.status ADD COLUMN OldRow int;
go

ALTER TABLE alerts.status ADD COLUMN ProbeSubSecondId int;
go

ALTER TABLE alerts.status ADD COLUMN NmosEventMap varchar(64);
go

CREATE INDEX serial ON alerts.status USING HASH (Serial);
go

CREATE TABLE iduc_system.iduc_stats PERSISTENT
(
	ServerName varchar(40) primary key,
	AppName varchar(40),
	AppDesc varchar(128) primary key,
	ConnectionId integer primary key,
	LastIducTime utc
);
go

ALTER TABLE alerts.problem_events ALTER COLUMN AlertGroup SET WIDTH 255;
go 

-- Set ActingPrimary property to TRUE
ALTER SYSTEM SET 'ActingPrimary' = TRUE;
go

---------------------------------------------------------------------------
-- Updated deduplication trigger to deduplicate probe events within 1 second
-- This trigger replaces the 7.2 deduplication trigger.
-- The existing trigger should be disabled and this one enabled if you wish
-- to use the updated trigger
---------------------------------------------------------------------------

create or replace trigger deduplication_73
group default_triggers
enabled false
priority 1
comment 'Deduplication processing for ALERTS.STATUS'
before reinsert on alerts.status
for each row
begin
	if( %user.app_name = 'PROBE' )
	then
		if( (old.LastOccurrence > new.LastOccurrence) or 
		   ((old.ProbeSubSecondId >= new.ProbeSubSecondId) and 
	  	    (old.LastOccurrence = new.LastOccurrence) ) )
		then
			cancel;
		end if;
	end if;

	set old.Tally = old.Tally + 1;
	set old.LastOccurrence =  new.LastOccurrence;
	set old.StateChange = getdate();
	set old.InternalLast = getdate();
	set old.Summary = new.Summary;
	set old.AlertKey = new.AlertKey;
	set old.ProbeSubSecondId = new.ProbeSubSecondId;
	if (( old.Severity = 0) and (new.Severity > 0))
	then
		set old.Severity = new.Severity;
	end if;
end;
go

---------------------------------------------------------------------------
-- Updated new_row trigger to set the LastOccurrence if it is O
-- This trigger replaces the 7.2 new_row trigger.
-- The existing trigger should be disabled and this one enabled if you wish
-- to use the updated trigger
---------------------------------------------------------------------------

create or replace trigger new_row_73
group default_triggers
enabled false
priority 1
comment 'Set default values for new alerts in ALERTS.STATUS'
before insert on alerts.status
for each row
begin
	if ( %user.is_gateway = false ) 
	then
              set new.Tally = 1;
	      set new.ServerName = getservername();
	end if;
	set new.StateChange = getdate();
	set new.InternalLast = getdate();

	if( new.ServerSerial = 0 )
	then
		set new.ServerSerial = new.Serial;
	end if;

	if( new.LastOccurrence = 0 )
	then
		set new.LastOccurrence = getdate();
	end if;

end;
go

-------------------------------------------------------------------
-- Triggers to record statistics for iduc clients
-------------------------------------------------------------------

create or replace trigger iduc_stats_insert
group iduc_triggers
priority 1
comment 'Insert client entry into iduc_system.iduc_stats table on signal iduc_connect'
on signal iduc_connect
declare
	failure_time utc;
begin
	set failure_time = getdate();
	for each row cnxn in iduc_system.iduc_stats where cnxn.AppDesc = %signal.description
		and cnxn.ConnectionId != %signal.conn_id and cnxn.ServerName = getservername()
		and cnxn.AppName = 'GATEWAY'
	begin
		set failure_time = cnxn.LastIducTime;
	end;
	-- delete entry for iduc client because connectionid is changed now
	-- but retain LastIducTime

	delete from iduc_system.iduc_stats where AppDesc = %signal.description and ConnectionId != %signal.conn_id and
AppName = 'GATEWAY'  and  ServerName = getservername();

	insert into iduc_system.iduc_stats (ServerName,AppName,AppDesc,ConnectionId,LastIducTime) values (getservername(),%signal.process,%signal.description,%signal.conn_id,failure_time);

end;
go
															 
CREATE OR REPLACE TRIGGER iduc_stats_update
GROUP iduc_triggers
PRIORITY 1
COMMENT 'update LastIducTime in iduc_system.iduc_stats table ON SIGNAL iduc_data_fetch'
ON SIGNAL iduc_data_fetch
BEGIN
	UPDATE iduc_system.iduc_stats SET LastIducTime = %signal.at WHERE ServerName = getservername()
		AND AppName = %signal.process AND AppDesc = %signal.description;
END;
go

create or replace trigger deduplicate_iduc_stats
group iduc_triggers
priority 1
comment 'Deduplicate rows on iduc_system.iduc_stats'
before reinsert on iduc_system.iduc_stats 
for each row
begin
	cancel; -- Do nothing. Allow the row to be discarded
end;
go

----------------------------------------------------------------------
-- Trigger to pass deletes across gateway during Update/Minimal resync
----------------------------------------------------------------------
CREATE OR REPLACE TRIGGER pass_deletes 
GROUP gateway_triggers
ENABLED false
PRIORITY 1
COMMENT 'Delete rows in destination server that do not exist in source after resync'
ON SIGNAL gw_resync_finish
BEGIN
	delete from alerts.status where OldRow = 1;
END;
go

----------------------------------------------------------------------
-- resync_finished trigger
---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER resync_finished
GROUP gateway_triggers
ENABLED true 
PRIORITY 1
COMMENT 'Resync finished' 
ON SIGNAL gw_resync_finish
WHEN (get_prop_value( 'BackupObjectServer' ) %= 'TRUE')
-- This is the backup server
BEGIN
	IF ( %user.description = 'failover_gate') THEN
                -- This is gw_resync_finish signal from failover gateway 
                -- update Backup OS's ActingPrimary to reflect it as backup
                ALTER SYSTEM SET 'ActingPrimary' = FALSE;
	END IF;
END;
go

----------------------------------------------------------------------
-- backup_counterpart_down trigger
---------------------------------------------------------------------
create or replace trigger backup_counterpart_down
group gateway_triggers
enabled false
priority 1
comment 'The counterpart server is down'
on signal gw_counterpart_down
-- This is the backup server
when get_prop_value( 'BackupObjectServer' ) %= 'TRUE' 
begin
	IDUC ACTCMD 'default','SWITCH TO BACKUP';       
	-- Enable the trigger groups that need to run in primary 
	execute procedure automation_enable;
	-- Set ActingPrimary property to TRUE
	alter system set 'ActingPrimary' = TRUE;
end;
go

----------------------------------------------------------------------
-- disconnect_iduc_missed trigger
---------------------------------------------------------------------
create or replace trigger disconnect_iduc_missed
group iduc_triggers
priority 1
comment 'Disconnects real-time clients that have not communicated with objectserver for 5 granularity periods'
on signal iduc_missed
begin
	if( %signal.missed_cycles > 10 )
	then
		insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey,OwnerUID) values(%signal.process+':'+%signal.node+':iducmissed:'+%signal.username, 'Disconnecting '+%signal.process+' process '+%signal.description+' connected as user '+%signal.username+'.Reason - Missed '+to_char(%signal.missed_cycles)+' iduc cycles.', %signal.node, 'SystemWatch', 1, 1, %signal.at, %signal.at,'IducMissed',%signal.process+':iducmissed',65534); 

		alter system drop connection %signal.connectionid;
	end if;
end;
go

GRANT SELECT ON TABLE master.servergroups TO ROLE 'AlertsGateway';
GRANT INSERT ON TABLE master.servergroups TO ROLE 'AlertsGateway';
GRANT UPDATE ON TABLE master.servergroups TO ROLE 'AlertsGateway';
GRANT DELETE ON TABLE master.servergroups TO ROLE 'AlertsGateway';
GRANT SELECT ON TABLE iduc_system.iduc_stats TO ROLE 'AlertsGateway';
GRANT INSERT ON TABLE iduc_system.iduc_stats TO ROLE 'AlertsGateway';
GRANT UPDATE ON TABLE iduc_system.iduc_stats TO ROLE 'AlertsGateway';
GRANT DELETE ON TABLE iduc_system.iduc_stats TO ROLE 'AlertsGateway';
GRANT RAISE ON SIGNAL gw_counterpart_down TO ROLE 'AlertsGateway';
GRANT RAISE ON SIGNAL gw_counterpart_up TO ROLE 'AlertsGateway';
GRANT RAISE ON SIGNAL gw_resync_start  TO ROLE 'AlertsGateway';
GRANT RAISE ON SIGNAL gw_resync_finish  TO ROLE 'AlertsGateway';
go

GRANT SELECT ON TABLE catalog.indexes TO ROLE 'CatalogUser';
GRANT CREATE INDEX ON TABLE alerts.status TO ROLE 'DatabaseAdmin';
GRANT CREATE INDEX ON TABLE alerts.journal TO ROLE 'DatabaseAdmin';
GRANT CREATE INDEX ON TABLE alerts.details TO ROLE 'DatabaseAdmin';
GRANT DROP INDEX ON TABLE alerts.status TO ROLE 'DatabaseAdmin';
GRANT DROP INDEX ON TABLE alerts.journal TO ROLE 'DatabaseAdmin';
GRANT DROP INDEX ON TABLE alerts.details TO ROLE 'DatabaseAdmin';
go


update alerts.conversions set Conversion = 'Infinera (Fault Integration Server)' where KeyField = 'Class40625';
update alerts.conversions set Conversion = 'Hammerhead Systems' where KeyField = 'Class40679';
go
insert into alerts.conversions values ( 'Class3701','Class',3701,'TimeView2' );
insert into alerts.conversions values ( 'Class4915','Class',4915,'Alcatel OMCR 1353 RA-B10 Q3 probe' );
insert into alerts.conversions values ( 'Class4951','Class',4951,'Alcatel 5529 oad' );
insert into alerts.conversions values ( 'Class4959','Class',4959,'Alcatel 9753 OMC WR' );
insert into alerts.conversions values ( 'Class4961','Class',4961,'Alcatel 5620 SAM v7' );
insert into alerts.conversions values ( 'Class5010','Class',5010,'ZTE Corba wcdma' );
insert into alerts.conversions values ( 'Class5011','Class',5011,'ZTE Corba fixednms' );
insert into alerts.conversions values ( 'Class30505','Class',30505,'XML Probe' );
insert into alerts.conversions values ( 'Class40110','Class',40110,'F5 Networks BIG-IP' );
insert into alerts.conversions values ( 'Class40343','Class',40343,'Tellabs 7190 Element Manager' );
insert into alerts.conversions values ( 'Class40626','Class',40626,'Infinera DTN' );
insert into alerts.conversions values ( 'Class40689','Class',40689,'Ericsson ServiceOn Microwave' );
insert into alerts.conversions values ( 'Class40690','Class',40690,'ECI Telecom - OPS Management System' );
insert into alerts.conversions values ( 'Class87350','Class',87350,'IBM Director' );
insert into alerts.conversions values ( 'Class87700','Class',87700,'Zenulta(Zen)' );
insert into alerts.conversions values ( 'Class87705','Class',87705,'SysMech(TeMIP)' );
insert into alerts.conversions values ( 'Class87720','Class',87720,'Tivoli Storage Manager' );
insert into alerts.conversions values ( 'Class87721','Class',87721,'Tivoli Application Dependency Discovery Manager' );
insert into alerts.conversions values ( 'Class87722','Class',87722,'IBM Tivoli Monitoring' );
insert into alerts.conversions values ( 'Class87723','Class',87723,'IBM Tivoli Monitoring Agent' );
insert into alerts.conversions values ( 'Class89100','Class',89100,'PL Series SNMP Agent' );
insert into alerts.conversions values ( 'Class89200','Class',89200,'TPC Rules' );
insert into alerts.conversions values ( 'Class89210','Class',89210,'Netcool Message Bus probe' );
insert into alerts.conversions values ( 'Class89220','Class',89220,'CBE Message Bus probe' );
insert into alerts.conversions values ( 'Class89230','Class',89230,'WEF Message Bus Probe' );
insert into alerts.conversions values ( 'Class89240','Class',89240,'WBE (WebSphere Business Events) Message Bus Probe' );
insert into alerts.conversions values ( 'Class89300','Class',89300,'Predictive Events' );
insert into alerts.conversions values ( 'Class89320','Class',89320,'SA z/OS' );
go
update alerts.objclass set Name = 'Infinera (Fault Integration Server)' where Tag = 40625;
update alerts.objclass set Name = 'Hammerhead Systems' where Tag = 40679;
go
insert into alerts.objclass values ( 3701,'TimeView2','Default.xpm','' );
insert into alerts.objclass values ( 4915,'Alcatel OMCR 1353 RA-B10 Q3 probe','Default.xpm','' );
insert into alerts.objclass values ( 4951,'Alcatel 5529 oad','Default.xpm','' );
insert into alerts.objclass values ( 4959,'Alcatel 9753 OMC WR','Default.xpm','' );
insert into alerts.objclass values ( 4961,'Alcatel 5620 SAM v7','Default.xpm','' );
insert into alerts.objclass values ( 5010,'ZTE Corba wcdma','Default.xpm','' );
insert into alerts.objclass values ( 5011,'ZTE Corba fixednms','Default.xpm','' );
insert into alerts.objclass values ( 30505,'XML Probe','Default.xpm','' );
insert into alerts.objclass values ( 40110,'F5 Networks BIG-IP','Default.xpm','' );
insert into alerts.objclass values ( 40343,'Tellabs 7190 Element Manager','Default.xpm','' );
insert into alerts.objclass values ( 40626,'Infinera DTN','Default.xpm','' );
insert into alerts.objclass values ( 40689,'Ericsson ServiceOn Microwave','Default.xpm','' );
insert into alerts.objclass values ( 40690,'ECI Telecom - OPS Management System','Default.xpm','' );
insert into alerts.objclass values ( 87350,'IBM Director','Default.xpm','' );
insert into alerts.objclass values ( 87700,'Zenulta(Zen)','Default.xpm','' );
insert into alerts.objclass values ( 87705,'SysMech(TeMIP)','Default.xpm','' );
insert into alerts.objclass values ( 87720,'Tivoli Storage Manager','Default.xpm','' );
insert into alerts.objclass values ( 87721,'Tivoli Application Dependency Discovery Manager','Default.xpm','' );
insert into alerts.objclass values ( 87722,'IBM Tivoli Monitoring','Default.xpm','' );
insert into alerts.objclass values ( 87723,'IBM Tivoli Monitoring Agent','Default.xpm','' );
insert into alerts.objclass values ( 89100,'PL Series SNMP Agent','Default.xpm','' );
insert into alerts.objclass values ( 89200,'TPC Rules','Default.xpm','' );
insert into alerts.objclass values ( 89210,'Netcool Message Bus probe','Default.xpm','' );
insert into alerts.objclass values ( 89220,'CBE Message Bus probe','Default.xpm','' );
insert into alerts.objclass values ( 89230,'WEF Message Bus Probe','Default.xpm','' );
insert into alerts.objclass values ( 89240,'WBE (WebSphere Business Events) Message Bus Probe','Default.xpm','' );
insert into alerts.objclass values ( 89300,'Predictive Events','Default.xpm','' );
insert into alerts.objclass values ( 89320,'SA z/OS','Default.xpm','' );
go
