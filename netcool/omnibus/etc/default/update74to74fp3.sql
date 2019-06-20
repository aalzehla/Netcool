-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2013. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SQL file contains schema, data and automation changes to be applied
-- to a 7.4 FP1/FP2 ObjectServer instance to bring it up to v7.4.0 FP3.
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

--
-- Tivoli OSLC JazzSM Registry Services - Resource Registry Event Collection 
-- Identifier Patterns.
--
create table registry.oslcecip persistent
(
	CIPId			incr,
	ResourceType		varchar(1024) primary key,
	Name			varchar(128),
	Description		varchar(1024),
	QueryPattern		varchar(4096)
);
go

create index oslcecip_ididx on registry.oslcecip using hash (CIPId);
go

--
-- Tivoli OSLC JazzSM Registry Services - Resource Registry Event Collection 
-- Identifier Pattern registry registrations.
--
create table registry.oslcecip_regs persistent
(
	CIPId			int primary key,
	RegistryURI		varchar(1024) primary key,
	RequestTime		time,

	Registered		int,
	RegistrationURI		varchar(1024),
	LastRegistered		time
);
go

--
-- Tivoli OSLC JazzSM Registry Service - Grant necessary permissions to the
-- OSLC Administartion role.
--
grant insert on table registry.oslcecip to role 'OSLCAdmin';
grant update on table registry.oslcecip to role 'OSLCAdmin';
grant delete on table registry.oslcecip to role 'OSLCAdmin';
grant select on table registry.oslcecip to role 'OSLCAdmin';
grant insert on table registry.oslcecip_regs to role 'OSLCAdmin';
grant update on table registry.oslcecip_regs to role 'OSLCAdmin';
grant delete on table registry.oslcecip_regs to role 'OSLCAdmin';
grant select on table registry.oslcecip_regs to role 'OSLCAdmin';
go

--
-- Tivoli OSLC JazzSM Registry Services - Default template Event Collection 
-- Identifier Patterns.
--
------------------------------------------------------------------------
-- ECIP = ComputerSystem
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#ComputerSystem',
	 	'ComputerSystem', 'The event collection identifier pattern for a ComputerSystem resource.',
		'Node=\'@http://open-services.net/ns/crtv#fqdn\'');
go

------------------------------------------------------------------------
-- ECIP = IPAddress
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#IPAddress',
		'IPAddress','The event collection identifier pattern for an IPAddress resource.',
		'NodeAlias=\'@http://open-services.net/ns/crtv#address\' OR Node=\'@http://open-services.net/ns/crtv#address\'');
go

------------------------------------------------------------------------
-- ECIP = ServcieInstance
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#ServiceInstance',
		'ServiceInstance','The event collection identifier pattern for a ServiceInstance resource.',
		'Service=\'@http://open-services.net/ns/crtv#name\'');
go

------------------------------------------------------------------------
-- ECIP = ServerAccessPoint
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#ServerAccessPoint',
		'ServerAccessPoint','The event collection identifier pattern for a ServerAccessPoint resource.',
		'NodeAlias=\'@http://open-services.net/ns/crtv#ipAddress{http://open-services.net/ns/crtv#address}\' AND Summary like \'@http://open-services.net/ns/crtv#portNumber\'');
go

------------------------------------------------------------------------
-- ECIP = SoftwareServer
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#SoftwareServer',
		'SoftwareServer','The event collection identifier pattern for a SoftwareServer resource.',
		'Service=\'@http://open-services.net/ns/crtv#name\' AND Node=\'@http://open-services.net/ns/crtv#runsOn{http://open-services.net/ns/crtv#fqdn}\''); 
go

------------------------------------------------------------------------
-- ECIP = SoftwareModule
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#SoftwareModule',
		'SoftwareModule','The event collection identifier pattern for a SoftwareModule resource.',
		'Service=\'@http://open-services.net/ns/crtv#deployedTo{http://open-services.net/ns/crtv#name}\' AND Node=\'@http://open-services.net/ns/crtv#deployedTo{http://open-services.net/ns/crtv#runsOn{http://open-services.net/ns/crtv#fqdn}}\' AND Summary like \'@http://open-services.net/ns/crtv#name\'');
go

------------------------------------------------------------------------
-- ECIP = Database
------------------------------------------------------------------------
insert into registry.oslcecip 
		(ResourceType,Name,Description,QueryPattern)
	values (
		'http://open-services.net/ns/crtv#Database',
		'Database','The event collection identifier pattern for a Database resource.',
		'Summary like \'@http://open-services.net/ns/crtv#name\' AND Node=\'@http://open-services.net/ns/crtv#dbinstance{http://open-services.net/ns/crtv#runsOn{http://open-services.net/ns/crtv#fqdn}}\'');
go

------------------------------------------------------------------------
-- OSLC Triggers:Trigger support for OSLC registrations.
------------------------------------------------------------------------
create or replace trigger group oslc;
go

create or replace procedure oslcecip_regs_delete
(
	in cipid int
)
begin
	delete from registry.oslcecip_regs where CIPId=cipid;
end;
go

create or replace procedure oslcecip_regs_insert
(
	in cipid int
)
begin
	-- Walk the set of service provider registrations.
	for each row provider in registry.oslcsp
	where
		provider.Registered = 1
	begin
		-- Insert ECIP registration for this provider.
		insert into registry.oslcecip_regs (CIPId,RegistryURI)
			values (cipid, provider.RegistryURI);
	end;
end;
go

create or replace trigger oslcreg_sp_delete_before
group oslc
enabled true 
priority 10
comment 'Cleanup OSLC ECIP registrations for delete Provider registration.'
before delete on registry.oslcsp
for each row
begin
	delete from registry.oslcecip_regs where RegistryURI=old.RegistryURI;
end;
go

create or replace trigger oslcreg_ecipregs_new
group oslc
enabled true 
priority 10
comment 'Set the RequestTime to now for the registration request row.'
before insert on registry.oslcecip_regs
for each row
begin
	set new.RequestTime = getdate();
end;
go

create or replace trigger oslcreg_ecip_new
group oslc
enabled true 
priority 10
comment 'Generate OSLC Service Provider registrations for inserted ECIP.'
after insert on registry.oslcecip
for each row
begin
	-- Insert all of the required registration requests for this ECIP.
	execute oslcecip_regs_insert(new.CIPId);
end;
go

create or replace trigger oslcreg_ecip_update_after
group oslc
enabled true 
priority 10
comment 'Update OSLC Service Provider registrations for updated ECIP.'
after update on registry.oslcecip
for each row
begin
	-- Delete all of the existing registrations for this ECIP.
	execute oslcecip_regs_delete(new.CIPId);

	-- Insert all of the required registration requests for this ECIP.
	execute oslcecip_regs_insert(new.CIPId);
end;
go

create or replace trigger oslcreg_ecip_dedup_before
group oslc
enabled true 
priority 10
comment 'Update OSLC Service Provider registrations for updated ECIP.'
before reinsert on registry.oslcecip
for each row
begin
	set old.Name = new.Name;
	set old.Description = new.Description;
	set old.QueryPattern = new.QueryPattern;
end;
go

create or replace trigger oslcreg_ecip_dedup_after
group oslc
enabled true 
priority 10
comment 'Update OSLC Service Provider registrations for updated ECIP.'
after reinsert on registry.oslcecip
for each row
begin
	-- Delete all of the existing registrations for this ECIP.
	execute oslcecip_regs_delete(new.CIPId);

	-- Insert all of the required registration requests for this ECIP.
	execute oslcecip_regs_insert(new.CIPId);
end;
go

create or replace trigger oslcreg_ecip_delete_after
group oslc
enabled true 
priority 10
comment 'Cleanup OSLC Service Provider registrations for ECIP.'
after delete on registry.oslcecip
for each row
begin
	delete from registry.oslcecip_regs where
		CIPId not in (select CIPId from registry.oslcecip) or
		RegistryURI not in (select RegistryURI from registry.oslcsp);
end;
go

create or replace trigger oslcreg_ecipreg_delete
group oslc
enabled true 
priority 1
comment 'Cleanup OSLC Service Provider registrations for ECIP.'
every 60 seconds
begin
	delete from registry.oslcecip_regs where
		CIPId not in (select CIPId from registry.oslcecip) or
		RegistryURI not in (select RegistryURI from registry.oslcsp);
end;
go

create or replace trigger oslcreg_sp_new
group oslc
enabled true 
priority 10
comment 'Generate OSLC Service Provider registrations for ECIP for registered provider.'
every 60 seconds
begin
	-- Walk the set of service provider registrations.
	for each row provider in registry.oslcsp
	where
		provider.Registered = 1
	begin
		-- Delete any failed registrations.
		delete from registry.oslcecip_regs where
			RegistryURI=provider.RegistryURI and
			Registered = 0 and
			RequestTime >= (getdate() - 240);

		-- Walk the set of ECIP definitions to add any missing 
		-- registrations. This will force a retry of any that failed.
		for each row ecip in registry.oslcecip
		where
			ecip.CIPId not in (select CIPId from
						registry.oslcecip_regs
					where RegistryURI=provider.RegistryURI)
		begin
			-- Insert ECIP registration for this provider.
			insert into registry.oslcecip_regs (CIPId,RegistryURI)
				values (ecip.CIPId, provider.RegistryURI);
		end;
	end;
end;
go
