-------------------------------------------------------------------------
--
--	Licensed Materials - Property of IBM
--
--	5724O4800
--
--	(C) Copyright IBM Corp. 2000, 2007. All Rights Reserved
--
--	US Government Users Restricted Rights - Use, duplication
--	or disclosure restricted by GSA ADP Schedule Contract
--	with IBM Corp.
--
--	Ident: $Id: application.sql 1.13 2003/08/11 14:03:18 ianj Development $
--
------------------------------------------------------------------------


--
-- The ALERTS database ...
-- This is the database that contains the default network event management application tables
--

create database alerts;
go

alter system set 'Store.DefaultPersistent' = 'table_store';
go

alter system set 'Store.DefaultVirtual' = 'virtual_store';
go

create table alerts.status persistent
(
	Identifier      varchar(255) primary key,
	Serial		incr,
	Node            varchar(64),
	NodeAlias       varchar(64),
	Manager         varchar(64),
	Agent           varchar(64),
	AlertGroup 	varchar(255),
	AlertKey        varchar(255),
	Severity        int,
	Summary         varchar(255),
	StateChange	time,
	FirstOccurrence time,
	LastOccurrence  time,
	InternalLast    time,
	Poll            int,
	Type            int,	
	Tally           int,
	Class           int,
	Grade           int,
	Location        varchar(64),
	OwnerUID        int,
	OwnerGID        int,		-- Groups Option
	Acknowledged    int,
	Flash    	int,		-- Flash Option
        EventId         varchar(255),    -- Required by Precision 3.x
        ExpireTime      int,
        ProcessReq      int,            -- Required by Precision 3.x
        SuppressEscl    int,
        Customer        varchar(64),
        Service         varchar(64),
        PhysicalSlot    int,
        PhysicalPort    int,
        PhysicalCard    varchar(64),
        TaskList        int,

        NmosSerial      varchar(64),   -- Required by Precision 3.x
        NmosObjInst     int,   -- Required by Precision 3.x
        NmosCauseType   int,            -- Required by Precision 3.x
	NmosDomainName 	varchar(64),
	NmosEntityId 	int,
	NmosManagedStatus int,	
	NmosEventMap	varchar(64),

        LocalNodeAlias  varchar(64),    -- Required by Precision 3.x
        LocalPriObj     varchar(255),
        LocalSecObj     varchar(255),
        LocalRootObj    varchar(255),   -- Required by Precision 3.x
        RemoteNodeAlias varchar(64),    -- Required by Precision 3.x
        RemotePriObj    varchar(255),
        RemoteSecObj    varchar(255),
        RemoteRootObj   varchar(255),

        X733EventType   int,
        X733ProbableCause       int,
        X733SpecificProb        varchar(64),
        X733CorrNotif   varchar(255),

	ServerName      varchar(64),
	ServerSerial    int,
	URL 		varchar(1024),
	ExtendedAttr	varchar(4096),
	OldRow		int,
	ProbeSubSecondId	int,
	BSM_Identity    varchar(1024) -- Required by Tivoli Business Service Manager (TBSM)
);
go

create index serial on alerts.status using hash (Serial);
go

create table alerts.journal persistent
(
	KeyField	varchar(255)	primary key,
	Serial		int,
	UID		int,
	Chrono		time,
	Text1		varchar(255),
	Text2		varchar(255),
	Text3		varchar(255),
	Text4		varchar(255),
	Text5		varchar(255),
	Text6		varchar(255),
	Text7		varchar(255),
	Text8		varchar(255),
	Text9		varchar(255),
	Text10		varchar(255),
	Text11		varchar(255),
	Text12		varchar(255),
	Text13		varchar(255),
	Text14		varchar(255),
	Text15		varchar(255),
	Text16		varchar(255)
);
go

create table alerts.details persistent
(
	KeyField   	varchar(255)	primary key,
	Identifier 	varchar(255),
	AttrVal    	int,
	Sequence   	int,
	Name       	varchar(255),
	Detail     	varchar(255)
);
go

create table alerts.objclass persistent
(
        Tag     int primary key,
        Name    varchar(64),
        Icon    varchar(255),
        Menu    varchar(64)
);
go

create table alerts.objmenus persistent
(
        Menu           varchar(64) primary key,
        Columns        int
);
go

create table alerts.objmenuitems persistent
(
        KeyField       varchar(255) primary key,
        Menu           varchar(64),
        Sequence       int,
        Title          varchar(64),
        Command1       varchar(255),
        Command2       varchar(255),
        Command3       varchar(255),
        Command4       varchar(255),
        RedirectStdin  int,
        RedirectStdout int,
        RedirectStderr int
);
go

create table alerts.resolutions persistent
(
        KeyField        varchar(255) primary key,
        Tag             int,
        Sequence        int,
        Title           varchar(64),
        Resolution1     varchar(255),
        Resolution2     varchar(255),
        Resolution3     varchar(255),
        Resolution4     varchar(255)
);
go

create table alerts.conversions persistent
(
        KeyField        varchar(255) primary key,
        Colname         varchar(255),
        Value           int,
        Conversion      varchar(255)
);
go

create table alerts.col_visuals persistent
(
        Colname         varchar(255) primary key,
        Title           varchar(255),
        DefWidth        int,
        MaxWidth        int,
        TitleJustify    int,
        DataJustify     int
);
go

-- This table is required for the NT desktop
create table alerts.colors persistent
(
        Severity        int primary key,
        AckedRed        int,
        AckedGreen      int,
        AckedBlue       int,
        UnackedRed      int,
        UnackedGreen    int,
        UnackedBlue     int
);
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


-- The following database and table are required for the additional features
-- to support the Internet Service Monitors

create database service;
go

create table service.status persistent
(
	Name            varchar(255) primary key,      -- Service Name
	CurrentState    int,            -- Good, Marginal, Bad, Unknown
	StateChange     time,           -- Time of last service state change
	LastGoodAt      time,           -- Time service was last good
	LastBadAt       time,           -- Time service was last bad
	LastMarginalAt  time,           -- Time service was last marginal
	LastReportAt    time            -- Time of last service status report
);
go

--
-- This database and tables are required for the desktop dynamic tools.
--
create database tools;
go

create table tools.actions persistent
(
        ActionID        int primary key,
        Name            varchar(64),
        Owner           int,
        Enabled         int,
        Description1    varchar(255),
        Description2    varchar(255),
        Description3    varchar(255),
        Description4    varchar(255),
        HasInternal     int,
        InternalEffect1 varchar(255),
        InternalEffect2 varchar(255),
        InternalEffect3 varchar(255),
        InternalEffect4  varchar(255),
        InternalForEach int,
        HasExternal      int,
        ExternalEffect1  varchar(255),
        ExternalEffect2  varchar(255),
        ExternalEffect3  varchar(255),
        ExternalEffect4  varchar(255),
        ExternalForEach  int,
        RedirectOut      int,
        RedirectErr      int,
        Platform         varchar(255),
        JournalText1     varchar(255),
        JournalText2     varchar(255),
        JournalText3     varchar(255),
        JournalText4     varchar(255),
        JournalForEach   int,
        HasForcedJournal int
);
go

create table tools.action_access persistent
(
        ActionID        int,
        GID             int,
        ClassID         int,
        ActionAccessID  int primary key
);
go

create table tools.menus persistent
(
        MenuID          int primary key,
        Name            varchar(64),
        Owner           int,
        Enabled         int
);
go


create table tools.menu_items persistent
(
        KeyField        varchar(32) primary key, -- menu_id:menu_item_id
        MenuID          int,
        MenuItemID      int,
        Title           varchar(64),
        Description     varchar(255),
        Enabled         int,
        InvokeType      int, -- What type of invocation: Action/Submenu
        InvokeID        int,
        Position        int,
        Accelerator     varchar(32)
);
go

create table tools.menu_defs persistent
(
        Name            varchar(64) primary key,
        DatabaseName    varchar(64),
        TableName       varchar(64),
        ShowField       varchar(64),
        AssignField     varchar(64),
        OrderbyField    varchar(64),
        WhereClause     varchar(255),
        Direction       int
);
go

create table tools.prompt_defs persistent
(
        Name            varchar(64) primary key,
        Prompt          varchar(64),
        Default         varchar(64),
        Value           varchar(255),
        Type            int
);
go

--
-- The 'master' database
-- Repository for user information and profiles
--
create database master;
go

--
-- 3.x Compatibility views.
--
create view master.names as select UserName as Name, UserID as UID, UserID - UserID as GID, Passwd, SystemUser as Type from security.users;
create view master.groups as select GroupName as Name, GroupID as GID from security.groups;
create view master.members as select Compat as KeyField, UserID as UID, GroupID as GID from security.group_members;
go

create table master.permissions persistent
(
	UID		int primary key,
	AllowISQLWrite  int
);
go

create table master.profiles persistent
(
 	UID     	int primary key,
 	HasRestriction	int,
 	Restrict1       varchar(255),
 	Restrict2       varchar(255),
 	Restrict3       varchar(255),
 	Restrict4       varchar(255),
 	AllowISQL       int
);
go

create table master.servergroups persistent
(
	ServerName		varchar(64) primary key,
	GroupID			int,
	Weight			int
);
go

-- This table is not for 3.x compatibility, it holds the class hierarcy used
-- by the instance_of() sql function which must be populated by the user.
create table master.class_membership persistent
(
	Class		int primary key,
	Parent		int primary key,
	ClassName	varchar(255)
);
go

--
-- The IDUC system database: This is the database that contains all of the
-- required IDUC application support tables for event fast tracking, sending
-- informational messages and action command invocation.
--
create database iduc_system;
go

create table iduc_system.channel persistent
(
	Name		varchar(64) primary key,
	ChannelID	int primary key,
	Description	varchar(2048)
);

create table iduc_system.channel_interest persistent
(
	InterestID	int primary key,
	ElementName	varchar(64),
	IsGroup		int,
	Hostname	varchar(255),
	AppName		varchar(255),
	AppDescription	varchar(255),
	ChannelID	int
);

create table iduc_system.channel_summary persistent
(
	DatabaseName	varchar(64) primary key,
	TableName	varchar(64) primary key,
	ChannelID	int primary key,
	SummaryID	int
);

create table iduc_system.channel_summary_cols persistent
(
	ColumnName	varchar(64) primary key,
	SummaryID	int primary key,
	Position	int,
	ChannelID	int
);
go

create table iduc_system.iduc_stats persistent
(
        ServerName varchar(40) primary key,
        AppName varchar(40),
        AppDesc varchar(128) primary key,
        ConnectionId integer primary key,
        LastIducTime utc
);
go


-- Default entries for iduc channel definitions, add to, or amend as required.
insert into iduc_system.channel values('default',0,'The default iduc channel. This channel defines an interest for any real-time client connected to the server. It also provides a default summary column list for event fast tracking messages sent directly to a client via is SPID, rather than by a channel name.');
go

insert into iduc_system.channel_interest values (0,'',0,'','','',0);
go

insert into iduc_system.channel_summary values ('alerts','status',0,0);
go

insert into iduc_system.channel_summary_cols values('Node',0,0,0);
insert into iduc_system.channel_summary_cols values('NodeAlias',0,1,0);
insert into iduc_system.channel_summary_cols values('Class',0,2,0);
insert into iduc_system.channel_summary_cols values('Summary',0,3,0);
insert into iduc_system.channel_summary_cols values('Serial',0,4,0);
go

-------------------------------------------------------------------------------
-- The following configuration is for SCA-LA integration
-------------------------------------------------------------------------------
-- ADD A NEW IDUC CHANNEL FOR THE MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE
-- IF CHANNEL ID = 1000 IS USED IN YOUR SYSTEM, PLEAES CHANGE IT TO A NEW VALUE

insert into iduc_system.channel (Name, ChannelID, Description) values ( 'scala', 1000, 'Channel for sending events to SCALA via SCALA gateway');
go

-- ADD A CHANNEL INTEREST FOR THE MESSAGE BUS GATEWAY RUNNING IN SCA-LA MODE. CONFIG THE
-- APPDESCRIPTION IN GATEWAY PROPERTY: Gate.Reader.Description: SCALA Gateway Reader
-- IF INTEREST ID = 1000 IS USED IN YOUR SYSTEM, PLEAES CHANGE IT TO A NEW VALUE

insert into iduc_system.channel_interest (InterestID, ElementName, IsGroup, Hostname, AppName, AppDescription, ChannelID) values (1000,'',0,'','','SCALA Gateway Reader',1000);
go

-- CREATE A CHANNEL SUMMARY ENTRY FOR THE ACCELERATED INSERTS CHANNEL
-- IF SUMMARY ID = 1000 IS USED IN YOUR SYSTEM, PLEASE CHANGE IT TO A NEW VALUE

insert into iduc_system.channel_summary (DatabaseName, TableName, ChannelID, SummaryID) values ('alerts','status',1000,1000);
go

-- DEFINE THE FIELDS TO BE FORWARDED OVER THE ACCELERATED INSERTS CHANNEL

insert into iduc_system.channel_summary_cols (ColumnName, SummaryID, Position, ChannelID) values('Serial',1000,0,1000);
go
-------------------------------------------------------------------------------
-- End of SCA-LA configuration
-------------------------------------------------------------------------------

-- The registry database
-- This is the database that contains information about OMNIbus
-- distributed configuration.

create database registry;
go

-- Probe registry.
create table registry.probes persistent
(
	-- Columns populated by probe
        Name            varchar(128) primary key,  -- Size of catalog.connection.AppDescription
	Hostname	varchar(64) primary key,   -- Size of alerts.status.Node
	HTTP_port       int,                       -- The ports that can be used to communicate
	HTTPS_port      int,                       -- with the probe.

	PID		int,                       -- Process ID
	Status		int,                       -- 0=dead, 1=running
	StartTime	time,                      -- Time probe started running.

	RulesChecksum	char(40),                  -- Rules File aggregate checksum
	ProbeType       varchar(128),
	ApiVersion	varchar(20),               -- Probe API product version
	ApiReleaseID	varchar(20),               -- Probe API release ID

	-- Columns populated by ObjectServer Triggers
	ConnectionID	int,                       -- ObjectServer connection ID, 0 =  not connected
	LastUpdate	time                       -- time of most recent update
);
go

-- Create the probe rules/loopup file hash value table
--
-- Tivoli OSLC JazzSM Registry Services - Service Provider Registrations
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

--
-- Create a custom database. This is the database into which custom tables
-- should be added that require manipulation by probes.
--
create database custom;
go

--
-- Create a precision database. This database will be used by precision to
-- implement Service Affecting Events application
--
create database precision;
go
create table precision.entity_service persistent
(
        NmosEntityId    integer primary key,
        ServiceEntityId integer primary key,
	NmosDomainName	varchar(255)
);
go
create table precision.service_details persistent
(
        ServiceEntityId integer primary key,
        Type            varchar(255),
        Name            varchar(255),
        Customer        varchar(255),
	NmosDomainName	varchar(255)
);
go
create table precision.service_affecting_event virtual
(
        ServiceEntityId integer primary key
);
go


------------------------------------------------------------------------
-- Self Monitoring
------------------------------------------------------------------------
------------------------------------------------------------------------------
-- CREATE A HOLDING TABLE FOR THE LAST STATS REPORT TIMESTAMPS
------------------------------------------------------------------------------
CREATE TABLE master.sm_activity PERSISTENT
(
	ReportTrigger		char(255) primary key,
	ProbeStatsLastSeqNos	int,
	MasterStatsLast		time
);
go

INSERT INTO master.sm_activity VALUES ('sm_db_stats', 1, 0);
go

INSERT INTO master.sm_activity VALUES ('sm_dbops_stats', 1, 0);
go


INSERT INTO master.sm_activity VALUES ('sm_connections', 1, 0);
go

------------------------------------------------------------------------------
-- CREATE A TABLE FOR THE SYNTHETIC EVENT SEVERITY THRESHOLDS
------------------------------------------------------------------------------
CREATE TABLE master.sm_thresholds PERSISTENT
(
        ThresholdName           char(64) primary key,
	DisplayName		char(64),
	Sev1			int,
	Sev2			int,
	Sev3			int,
	Sev4			int,
	Sev5			int,
	EnableInfo		int,
	DeduplicateInfo		int
);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_memstore

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_memstore', 'SM Memstore', 0, 0, 75, 85, 95, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_triggers

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_triggers_individual', 'SM Triggers Individual', 0, 0, 20, 25, 30, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_triggers_total', 'SM Triggers Total', 0, 0, 50, 70, 90, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_triggers_reporting_period', 'SM Triggers Reporting Period', 0, 0, 61, 70, 90, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_client_time

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_client_time_individual', 'SM Client Time Individual', 0, 0, 30, 40, 50, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_client_time_total', 'SM Client Time Total', 0, 0, 40, 60, 90, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_connections

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_connections', 'SM Connections', 0, 0, 50, 30, 10, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_db_stats

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_db_stats_event_count', 'SM DB Stats Event Count', 0, 0, 80000, 90000, 100000, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_db_stats_journal_count', 'SM DB Stats Journal Count', 0, 0, 20000, 35000, 50000, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_db_stats_details_count', 'SM DB Stats Details Count', 0, 0, 3000, 10000, 20000, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_dbops_stats

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_dbops_stats_status_inserts', 'SM DB Ops Stats Status Inserts', 0, 0, 10000, 0, 0, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_dbops_stats_journal_inserts', 'SM DB Ops Stats Journal Inserts', 0, 0, 10000, 0, 0, 1, 1);
go

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_dbops_stats_details_inserts', 'SM DB Ops Stats Details Inserts', 0, 0, 10000, 0, 0, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_top_nodes

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_top_nodes', 'SM Top Nodes', 0, 0, 100, 200, 500, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_top_probes

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_top_probes', 'SM Top Probes', 0, 0, 600, 800, 1000, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_top_classes

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_top_classes', 'SM Top Classes', 0, 0, 600, 800, 1000, 1, 1);
go

------------------------------------------------------------------------------
-- CREATE THRESHOLDS FOR TRIGGER sm_time_to_display

INSERT INTO master.sm_thresholds (
	ThresholdName, DisplayName, Sev1, Sev2, Sev3, Sev4, Sev5, EnableInfo, DeduplicateInfo)
VALUES (
	'sm_time_to_display', 'SM Time to Display', 0, 0, 60, 120, 180, 1, 1);
go

-- End of file
