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
--	Ident: $Id: system.sql 1.15 2003/10/10 16:25:48 britta Development $
--
------------------------------------------------------------------------

-- DO NOT MODIFY THIS FILE

create database security;
go

alter system set 'Store.DefaultPersistent' = 'master_store';
go

create table security.owners persistent
(
	ApplicationID	int primary key,
	ObjectType	int primary key,
	Object		varchar(255) primary key,
	OwnerType	int,
	OwnerID		int
);
go

create memstore table_store persistent hard limit 500M soft limit 450M;
go

insert into security.owners values( 1, 1, '', 0, 0 ); 
insert into security.owners values( 3, 1, 'nco_ccserv', 0, 0 ); 
insert into security.owners values( 3, 2, 'nco_ccserv.file', 0, 0 ); 
insert into security.owners values( 3, 2, 'nco_ccserv.security', 0, 0 ); 
insert into security.owners values( 3, 2, 'nco_ccserv.objserv', 0, 0 ); 
go

create table security.users persistent
(
	UserID		int primary key,
	UserName	varchar(64),
	SystemUser	int,
	FullName	varchar(255),
	Passwd		varchar(64),
	UsePAM		boolean,
	Enabled		boolean
);
go
	
create table security.roles persistent
(
	RoleID		int primary key,
	RoleName	varchar(64),
	SystemRole	boolean,
	Description	varchar(255),
	RoleScope	int
);
go

create table security.role_grants persistent
(
	GranteeType	int primary key,
	GranteeID	int primary key,
	RoleID		int primary key
);
go

create table security.permissions persistent
(
	ApplicationID	int primary key,
	ObjectType	int primary key,
	Object		varchar(255) primary key,
	GranteeType	int primary key,
	GranteeID	int primary key,
	Allows		int64,
	Denies		int64,
	GrantOptions	int64
);
go

create table security.groups persistent
(
	GroupID		int primary key,
	GroupName	varchar(64),
	SystemGroup	boolean,
	Description	varchar(255),
	Enabled		boolean
);
go

create table security.group_members persistent
(
	UserID		int primary key,
	GroupID		int primary key,
	Compat		varchar(64)
);
go

create table security.restriction_filters persistent
(
	GranteeType	int primary key,
	GranteeID	int primary key,
	RestrictionName	varchar(40) primary key,
	DatabaseName	varchar(40),
	TableName	varchar(40)
);
go

insert into security.users values( 0, 'root', 1, 'Root User', '', FALSE, TRUE );
insert into security.users values( 65534, 'nobody', 4, 'Nobody', '', FALSE, FALSE );
insert into security.permissions values( 1, 1, '', 0, 0, 65535 , 0, 65535 );
insert into security.permissions values( 3, 1, 'nco_ccserv', 0, 0, 65535 , 0, 65535 );
insert into security.permissions values( 3, 2, 'nco_ccserv.objserv', 0, 0, 65535 , 0, 65535 );
insert into security.permissions values( 3, 2, 'nco_ccserv.security', 0, 0, 65535 , 0, 65535 );
insert into security.permissions values( 3, 2, 'nco_ccserv.file', 0, 0, 65535 , 0, 65535 );
insert into security.roles values( -1, 'SuperUser', TRUE, 'Super User', 0);
insert into security.roles values( 0, 'Public', TRUE, 'Any User', 0);
insert into security.roles values( 2, 'Administrator', TRUE, 'Administrator', 0);
insert into security.roles values( 3, 'Normal', TRUE, 'Normal User', 0);
insert into security.role_grants values( 0, 0, 0);
insert into security.groups values( 0, 'Public', TRUE, 'Public Group' );
insert into security.groups values( 1, 'System', TRUE, 'System Group' );
insert into security.groups values( 2, 'Administrator', TRUE, 'Admin Group' );
insert into security.groups values( 3, 'Normal', TRUE, 'Normal Group' );
insert into security.group_members values( 0, 1 );
insert into security.group_members values( 0, 0 );
insert into security.group_members values( 65534, 0); 
insert into security.group_members values( 65534, 1);
go

create database transfer;
go

create table transfer.users persistent
(
	UserID		int primary key,
	UserName	varchar(64),
	SystemUser	int,
	FullName	varchar(255),
	Passwd		varchar(64),
	UsePAM		boolean,
	Enabled		boolean
);
go
	
create table transfer.roles persistent
(
	RoleID		int primary key,
	RoleName	varchar(64),
	SystemRole	boolean,
	Description	varchar(255),
	RoleScope	int
);
go

create table transfer.role_grants persistent
(
	GranteeType	int primary key,
	GranteeID	int primary key,
	RoleID		int primary key
);
go

create table transfer.permissions persistent
(
	ApplicationID	int primary key,
	ObjectType	int primary key,
	Object		varchar(255) primary key,
	GranteeType	int primary key,
	GranteeID	int primary key,
	Allows		int64,
	Denies		int64,
	GrantOptions	int64
);
go

create table transfer.groups persistent
(
	GroupID		int primary key,
	GroupName	varchar(64),
	SystemGroup	boolean,
	Description	varchar(255),
	Enabled		boolean
);
go

create table transfer.group_members persistent
(
	UserID		int primary key,
	GroupID		int primary key,
	Compat		varchar(64)
);
go

create table transfer.restrictions persistent
(
	RestrictionName	varchar(40) primary key,
	TableName	varchar(40), 
	DatabaseName	varchar(40), 
	ConditionText	varchar(16384),
	CreationText	varchar(16384)
);
go

create table transfer.security_restrictions persistent
(
	GranteeType	int primary key,
	GranteeID	int primary key,
	RestrictionName	varchar(40) primary key,
	DatabaseName	varchar(40),
	TableName	varchar(40)
);
go

insert into transfer.users values( 0, 'root', 1, 'Root User', '', FALSE, TRUE );
insert into transfer.users values( 65534, 'nobody', 4, 'Nobody', '', FALSE, FALSE );
insert into transfer.permissions values( 1, 1, '', 0, 0, 65535 , 0, 65535 );
insert into transfer.permissions values( 3, 1, 'nco_ccserv', 0, 0, 65535 , 0, 65535 );
insert into transfer.permissions values( 3, 2, 'nco_ccserv.objserv', 0, 0, 65535 , 0, 65535 );
insert into transfer.permissions values( 3, 2, 'nco_ccserv.security', 0, 0, 65535 , 0, 65535 );
insert into transfer.permissions values( 3, 2, 'nco_ccserv.file', 0, 0, 65535 , 0, 65535 );
insert into transfer.roles values( -1, 'SuperUser', TRUE, 'Super User', 0);
insert into transfer.roles values( 0, 'Public', TRUE, 'Any User', 0);
insert into transfer.roles values( 2, 'Administrator', TRUE, 'Administrator', 0);
insert into transfer.roles values( 3, 'Normal', TRUE, 'Normal User', 0);
insert into transfer.role_grants values( 0, 0, 0);
insert into transfer.groups values( 0, 'Public', TRUE, 'Public Group' );
insert into transfer.groups values( 1, 'System', TRUE, 'System Group' );
insert into transfer.groups values( 2, 'Administrator', TRUE, 'Admin Group' );
insert into transfer.groups values( 3, 'Normal', TRUE, 'Normal Group' );
insert into transfer.group_members values( 0, 1 );
insert into transfer.group_members values( 0, 0 );
insert into transfer.group_members values( 65534, 0); 
insert into transfer.group_members values( 65534, 1);
go
