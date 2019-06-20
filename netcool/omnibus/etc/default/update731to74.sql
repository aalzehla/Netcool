-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2012. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SQL file contains schema, data and automation changes to be applied
-- to a 7.3.1 ObjectServer instance to bring it up to v7.4.0
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

-- The registry database
-- This is the database that contains information about OMNIbus
-- distributed configuration.

create database registry;
go

-- Probe registry.
create table registry.probes virtual
(
	-- Columns by probe
	Name            varchar(128) primary key,  -- Size of catalog.connection.AppDescription
	Hostname        varchar(64) primary key,   -- Size of alerts.status.Node
	PID             int,
	Status          int,                       -- 0=dead, 1=running 
	HTTP_port       int,                       -- The port that can be used to communicate
                                                   -- with the probe. 
	HTTPS_port      int,
	StartTime       time,
	ProbeType       varchar(128),

	
	-- Columns populated by ObjectServer Triggers
	ConnectionID    int,
	LastUpdate      time                       -- time of most recent update
);
go

--
-- Tivoli OSLC Foundation Registry Services - Service Provider Registrations
--
create table registry.oslcsp persistent
(
	Name			varchar(64),
	RegistryURI		varchar(1024) primary key,
	RegistryUsername	varchar(64),
	RegistryPassword	varchar(64),

	Registered		int,
	RegistrationURI		varchar(1024),
	LastRegistered		time
);
go

--
-- Tivoli OSLC Foundation Registry Service - Administartion role.
--
create role 'OSLCAdmin' comment 'OSLC Service Provider Registration Administration';
grant insert on table registry.oslcsp to role 'OSLCAdmin';
grant delete on table registry.oslcsp to role 'OSLCAdmin';
grant select on table registry.oslcsp to role 'OSLCAdmin';
go

-- Grants of the OSLC administartion role.
grant role 'OSLCAdmin' to group 'Administrator';
go

grant role 'OSLCAdmin' to group 'System';
go

--
-- Registry trigger group.
--
create or replace trigger group registry_triggers;
go 

-- Registry triggers: Maintain the registry database.
------------------------------------------------------------------------

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
set new.LastUpdate = getdate;
end;
go

create or replace trigger registry_reinsert_probe
group registry_triggers
enabled true 
priority 10
comment 'Treat inserts to existing PROBE.REGISTRY entry as though they were updates. Time stamp the record to keep track of the last time this entry was updated. Only probes directly connected, or connected via a proxy server, are allowed to re-insert into the table. Other applications must use UPDATE to modify the probe registry.'
before reinsert on registry.probes
for each row
begin
if (%user.app_name = 'PROBE') or (%user.app_name = 'PROXY') then
	set old.PID = new.PID;
	set old.Status = new.Status;
	set old.HTTP_port = new.HTTP_port;
	set old.HTTPS_port = new.HTTPS_port;
	set old.StartTime = new.StartTime;
	set old.ProbeType = new.ProbeType;

	set old.ConnectionID = %user.connection_id;
	set old.LastUpdate = getdate;
else
	cancel;
end if;
end;
go

create or replace trigger registry_probe_disconnect
group registry_triggers
enabled true 
priority 10
comment 'Remove disconnecting probes from the probe registry'
on signal disconnect
begin
	if (%signal.process = 'PROBE') then
		delete from registry.probes where ConnectionID = %signal.connectionid;
	elseif (%signal.process = 'PROXY') then
		delete from registry.probes where Status = 0;
	end if;
end;
go

-- Registry database: Security
------------------------------------------------------------------------
create role 'RegisterProbe' comment 'Probe registration';
grant insert on table registry.probes to role 'RegisterProbe';
grant update on table registry.probes to role 'RegisterProbe';
go

create role 'RegistryReader' comment 'Access the registry';
grant select on table registry.probes to role 'RegistryReader';
go

create role 'RegistryAdmin' comment 'Registry data administration';
grant insert on table registry.probes to role 'RegistryAdmin';
grant update on table registry.probes to role 'RegistryAdmin';
grant select on table registry.probes to role 'RegistryAdmin';
grant delete on table registry.probes to role 'RegistryAdmin';
go

grant create table on database registry to role 'DatabaseAdmin';
grant alter on table registry.probes to role 'DatabaseAdmin';
grant drop on table registry.probes to role 'DatabaseAdmin';
grant create index on table registry.probes to role 'DatabaseAdmin';
grant drop index on table registry.probes to role 'DatabaseAdmin';
go

grant create trigger on trigger group registry_triggers to role 'AutoAdmin';
grant alter on trigger group registry_triggers to role 'AutoAdmin';
grant drop on trigger group registry_triggers to role 'AutoAdmin';
go

grant alter on trigger registry_new_probe to role 'AutoAdmin';
grant alter on trigger registry_reinsert_probe to role 'AutoAdmin';
grant alter on trigger registry_probe_disconnect to role 'AutoAdmin';
grant drop on trigger registry_new_probe to role 'AutoAdmin';
grant drop on trigger registry_reinsert_probe to role 'AutoAdmin';
grant drop on trigger registry_probe_disconnect to role 'AutoAdmin';
go

grant role 'RegisterProbe' to group 'Probe';
grant role 'RegistryReader' to group 'Normal';
grant role 'RegistryAdmin' to group 'Administrator';
go

--
-- Service Affecting Events (SAE) plug-in is now NmosDomainName
-- aware so that multiple SAE (ITNM) domains can safely use the same
-- Tivoli/Netcool OMNIbus ObjectServer.
--
alter table precision.entity_service add column NmosDomainName  varchar(255);
go

alter table precision.service_details add column NmosDomainName  varchar(255);
go


------------------------------------------------------------------------
-- SAE triggers:Precision SAE application related trigger 
------------------------------------------------------------------------
create or replace trigger update_service_affecting_events
group sae
priority 1
comment 'Update Service Affecting Events'
every 60 seconds
evaluate
	-- group by is used for "select distinct"
	select ServiceEntityId, count(*)
	from precision.entity_service
	-- there must be an nmos-id in alerts.status for this service-id
	where NmosEntityId in
	(select NmosEntityId from alerts.status
		where NmosEntityId != 0 and Severity = 5)
		group by ServiceEntityId
	bind as services
begin
	-- since we can't do a for each row on a transtable
	-- with a where clause, we first populate a virtual table
	delete from precision.service_affecting_event;

	for each row serv in services
	begin
		insert into precision.service_affecting_event
		values (serv.ServiceEntityId);
	end;

	-- service_affecting_event now contains all the service-ids for which a
	-- service affecting event should exist.

	-- first delete any sae which shouldn't exist; could make
	-- alerts.status smaller
	delete from alerts.status
	where Class = 8001
	and NmosEntityId not in
		(select ServiceEntityId from precision.service_affecting_event);

	-- retrieve the details of the service
	for each row serv_detail in precision.service_details
	where
		serv_detail.ServiceEntityId in
		(select ServiceEntityId from precision.service_affecting_event)
	and
		serv_detail.ServiceEntityId not in
		(select NmosEntityId from alerts.status where Class = 8001)
	begin
		-- create sae for service
		insert into alerts.status (Identifier,
			NmosEntityId, Severity, ServerName,
			Summary, Manager, Class,
			FirstOccurrence, LastOccurrence,
			AlertGroup, OwnerUID, Type, EventId, NmosDomainName)
		values
			('SAE for ' + serv_detail.Name + '-' +
			serv_detail.Customer,
			serv_detail.ServiceEntityId,
			4,
			getservername,
			serv_detail.Type + ' ' + serv_detail.Name +
			' affected (' + serv_detail.Customer + ')',
			'Service Automation',
			8001,
			getdate, getdate,
			'nco_objserv', 65534, 1, serv_detail.Type,
			serv_detail.NmosDomainName );
	end;
end;
go

--
-- New and updated Conversions
--

update alerts.conversions set Conversion = 'Genband IEMS' where KeyField =  'Class5155';
update alerts.conversions set Conversion = 'Ciena SNMP' where KeyField = 'Class4506';
go

insert into alerts.conversions values ( 'Class1050','Class',1050,'Radware' );
insert into alerts.conversions values ( 'Class1380','Class',1380,'Flash Networks' );
insert into alerts.conversions values ( 'Class1450','Class',1450,'Kentrox, Inc.' );
insert into alerts.conversions values ( 'Class1505','Class',1505,'Alvarion' );
insert into alerts.conversions values ( 'Class1510','Class',1510,'Openet Telecom' );
insert into alerts.conversions values ( 'Class2080','Class',2080,'Dell Server' );
insert into alerts.conversions values ( 'Class2085','Class',2085,'Dell EqualLogic' );
insert into alerts.conversions values ( 'Class2115','Class',2115,'HP Operations Manager' );
insert into alerts.conversions values ( 'Class3350','Class',3350,'Itron OpenWay Collection Engine Probe' );
insert into alerts.conversions values ( 'Class3351','Class',3351,'Itron OpenWay Control Probe' );
insert into alerts.conversions values ( 'Class3360','Class',3360,'VMWare' );
insert into alerts.conversions values ( 'Class402','Class',402,'HP NNM WS' );
insert into alerts.conversions values ( 'Class4020','Class',4020,'MRV Communications - Megavision NMS' );
insert into alerts.conversions values ( 'Class40700','Class',40700,'Riverbed Technology' );
insert into alerts.conversions values ( 'Class4920','Class',4920,'Alcatel XMC CORBA Probe' );
insert into alerts.conversions values ( 'Class4963','Class',4963,'Alcatel 5620 SAM V8 Corba' );
insert into alerts.conversions values ( 'Class4964','Class',4964,'Alcatel 5620 SAM v9' );
insert into alerts.conversions values ( 'Class5201','Class',5201,'Nolio' );
insert into alerts.conversions values ( 'Class5202','Class',5202,'Retalix' );
insert into alerts.conversions values ( 'Class5203','Class',5203,'Intellinx Ltd' );
insert into alerts.conversions values ( 'Class5210','Class',5210,'Indeni Limited' );
insert into alerts.conversions values ( 'Class87010','Class',87010,'Trilliant' );
insert into alerts.conversions values ( 'Class87360','Class',87360,'TNPFA' );
insert into alerts.conversions values ( 'Class87726','Class',87726,'IBM Proventia' );
insert into alerts.conversions values ( 'Class87727','Class',87727,'IBM PureApplication System' );
insert into alerts.conversions values ( 'Class87728','Class',87728,'IBM Workload Deployer' );
insert into alerts.conversions values ( 'Class89001','Class',89001,'UCSM' );
insert into alerts.conversions values ( 'Class89002','Class',89002,'CUCM' );
insert into alerts.conversions values ( 'Class89003','Class',89003,'CUCxN' );
insert into alerts.conversions values ( 'Class89004','Class',89004,'CUP' );
insert into alerts.conversions values ( 'Class89005','Class',89005,'Cisco DCNM LAN' );
insert into alerts.conversions values ( 'Class89006','Class',89006,'Cisco DCNM SAN' );
insert into alerts.conversions values ( 'Class89007','Class',89007,'UCCE' );
insert into alerts.conversions values ( 'Class89008','Class',89008,'CVP' );
insert into alerts.conversions values ( 'Class89120','Class',89120,'Tivoli Endpoint Manager Exception Events' );
insert into alerts.conversions values ( 'Class89121','Class',89121,'TEM Network AP Status Events' );
insert into alerts.conversions values ( 'Class89122','Class',89122,'TEM Network Topology Notifications' );
insert into alerts.conversions values ( 'Class89350','Class',89350,'TSAA Events' );
insert into alerts.conversions values ( 'Class925','Class',925,'Windows 2008/v7 Eventlog Probe' );
go

update alerts.objclass set Name = 'Ciena SNMP' where Tag = 40506;
update alerts.objclass set Name = 'Genband IEMS' where Tag = 5155;
go

insert into alerts.objclass values ( 1050,'Radware','Default.xpm','' );
insert into alerts.objclass values ( 1380,'Flash Networks','Default.xpm','' );
insert into alerts.objclass values ( 1450,'Kentrox, Inc.','Default.xpm','' );
insert into alerts.objclass values ( 1505,'Alvarion','Default.xpm','' );
insert into alerts.objclass values ( 1510,'Openet Telecom','Default.xpm','' );
insert into alerts.objclass values ( 2080,'Dell Server','Default.xpm','' );
insert into alerts.objclass values ( 2085,'Dell EqualLogic','Default.xpm','' );
insert into alerts.objclass values ( 2115,'HP Operations Manager','Default.xpm','' );
insert into alerts.objclass values ( 3350,'Itron OpenWay Collection Engine Probe','Default.xpm','' );
insert into alerts.objclass values ( 3351,'Itron OpenWay Control Probe','Default.xpm','' );
insert into alerts.objclass values ( 3360,'VMWare','Default.xpm','' );
insert into alerts.objclass values ( 402,'HP NNM WS','Default.xpm','' );
insert into alerts.objclass values ( 4020,'MRV Communications - Megavision NMS','Default.xpm','' );
insert into alerts.objclass values ( 40700,'Riverbed Technology','Default.xpm','' );
insert into alerts.objclass values ( 4920,'Alcatel XMC CORBA Probe','Default.xpm','' );
insert into alerts.objclass values ( 4963,'Alcatel 5620 SAM V8 Corba','Default.xpm','' );
insert into alerts.objclass values ( 4964,'Alcatel 5620 SAM v9','Default.xpm','' );
insert into alerts.objclass values ( 5201,'Nolio','Default.xpm','' );
insert into alerts.objclass values ( 5202,'Retalix','Default.xpm','' );
insert into alerts.objclass values ( 5203,'Intellinx Ltd','Default.xpm','' );
insert into alerts.objclass values ( 5210,'Indeni Limited','Default.xpm','' );
insert into alerts.objclass values ( 87010,'Trilliant','Default.xpm','' );
insert into alerts.objclass values ( 87360,'TNPFA','Default.xpm','' );
insert into alerts.objclass values ( 87726,'IBM Proventia','Default.xpm','' );
insert into alerts.objclass values ( 87727,'IBM PureApplication System','Default.xpm','' );
insert into alerts.objclass values ( 87728,'IBM Workload Deployer','Default.xpm','' );
insert into alerts.objclass values ( 89001,'UCSM','Default.xpm','' );
insert into alerts.objclass values ( 89002,'CUCM','Default.xpm','' );
insert into alerts.objclass values ( 89003,'CUCxN','Default.xpm','' );
insert into alerts.objclass values ( 89004,'CUP','Default.xpm','' );
insert into alerts.objclass values ( 89005,'Cisco DCNM LAN','Default.xpm','' );
insert into alerts.objclass values ( 89006,'Cisco DCNM SAN','Default.xpm','' );
insert into alerts.objclass values ( 89007,'UCCE','Default.xpm','' );
insert into alerts.objclass values ( 89008,'CVP','Default.xpm','' );
insert into alerts.objclass values ( 89120,'Tivoli Endpoint Manager Exception Events','Default.xpm','' );
insert into alerts.objclass values ( 89121,'TEM Network AP Status Events','Default.xpm','' );
insert into alerts.objclass values ( 89122,'TEM Network Topology Notifications','Default.xpm','' );
insert into alerts.objclass values ( 89350,'TSAA Events','Default.xpm','' );
insert into alerts.objclass values ( 925,'Windows 2008/v7 Eventlog Probe','Default.xpm','' );
go
