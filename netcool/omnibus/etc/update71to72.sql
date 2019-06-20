-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2007. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

--------------------------------------------------------------------------------
--  SQL file contains schema, data and automation changes to be applied
--  to a 7.1.x ObjectServer instance to bring it up to v7.2
-- 
--  If migrating from a v7.0.x instance of the ObjectServer, then the
--  upgrade70to71.sql file should be applied before applying this file.
--
--  The contents of this file should be reviewed prior to adding it to 
--  the ObjectServer.
--  Applying this file may cause automations to be replaced, meaning
--  any customization of the automations will be lost
--
--  Prior to applying this file, it is advisable to backup your 
--  ObjectServer instance
--
--------------------------------------------------------------------------------

alter table alerts.status 
	add NmosDomainName varchar(64)
	add NmosEntityId int
	add NmosManagedStatus int
	add ExtendedAttr varchar(4096);
go

create or replace trigger group gateway_triggers;
go

create or replace trigger group primary_only;
go

create or replace trigger group sae;
alter trigger group sae set enabled false;
go

drop trigger system_watch_license_lost;
go

alter trigger delete_clears set group primary_only;
alter trigger expire set group primary_only;
alter trigger generic_clear set group primary_only;
go

--
-- Grouped profile reporter trigger
--
create or replace trigger profiler_group_report
group profiler_triggers
priority 2
comment 'Profiler application group reporting trigger'
on signal profiler_report
evaluate select AppName, sum( PeriodSQLTime ) as ClientTypeTotalTime
		from catalog.profiles
		where NumSubmits > 0
		group by AppName bind as profile_tt;
declare	header		boolean;
	total		real;
begin
	-- Initialise client's total period time
	set total = 0.0;

	-- Display header
	set header = true;

	-- Report grouped SQL timings
	for each row profile in profile_tt
	begin
		if( header = true ) then
			-- Header
			write into profiler_report
				values( to_char( %signal.report_time ) + ': Grouped user profiles:' );
			set header = false;
		end if;

		write into profiler_report
			values( to_char( %signal.report_time ) + ': Execution time for all connections whose application name is \'' +
				profile.AppName + '\': ' + to_char( profile.ClientTypeTotalTime ) + 's' );

		-- Accumulate the total time for all client types
		set total = total + profile.ClientTypeTotalTime;
	end;

	write into profiler_report
		values( to_char( %signal.report_time ) + ': Total time in the report period (' + to_char( %signal.report_period ) + 's): ' +
		      	to_char( total ) + 's' );
end;
go

------------------------------------------------------------------------
-- Signal triggers: gateway_triggers
------------------------------------------------------------------------
create or replace procedure automation_disable()
begin

	-- Disable the automations that should not be 
	-- running when it is a backup ObjectServer 
	for each row tg in catalog.triggers where 
			tg.GroupName = 'primary_only'
	begin
		alter trigger group tg.GroupName set enabled false;
	end;
end;
go

create or replace procedure automation_enable()
begin

	-- Enable the automations that should be 
	-- running when it is a primary ObjectServer 
	for each row tg in catalog.triggers where 
			tg.GroupName = 'primary_only'
	begin
		alter trigger group tg.GroupName set enabled true;
	end;
end;
go

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
end;
go

create or replace trigger backup_counterpart_up
group gateway_triggers
enabled false
priority 1
comment 'The counterpart server has come up'
on signal gw_counterpart_up
-- This is the backup server
when get_prop_value( 'BackupObjectServer' ) %= 'TRUE'
begin
	IDUC ACTCMD 'default','SWITCH TO PRIMARY';	
	-- Disable the trigger groups that need not to
	-- run when object server acts as backup 
	execute procedure automation_disable;
end;
go

create or replace trigger backup_startup
group gateway_triggers
enabled false
priority 1
comment 'On startup dont start the automations'
on signal startup
when (get_prop_value( 'BackupObjectServer' ) %= 'TRUE')
-- This is the backup server
begin
	-- Disable the trigger groups that need not to 
	-- run when object server acts as backup 
	execute procedure automation_disable;
end;
go

create or replace trigger disconnect_iduc_missed
group iduc_triggers
priority 1
comment 'Disconnects real-time clients that have not communicated with objectserver for 5 granularity periods'
on signal iduc_missed
begin
if(%signal.missed_cycles>5)
then
	insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey,OwnerUID) values(%signal.process+':'+%signal.node+':iducmissed:'+%signal.username, 'Disconnecting '+%signal.process+' process '+%signal.description+' connected as user '+%signal.username+'.Reason - Missed '+to_char(%signal.missed_cycles)+' iduc cycles.', %signal.node, 'SystemWatch', 1, 1, %signal.at, %signal.at,'IducMissed',%signal.process+':iducmissed',65534); 

	alter system drop connection %signal.connectionid;
end if;
end;
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

--
-- Create a precision database. This database will be used by precision to 
-- implement Service Affecting Events application 
--
create database precision;
go

create table precision.entity_service persistent
(
        NmosEntityId    integer primary key,
        ServiceEntityId integer primary key
);
go
create table precision.service_details persistent
(
        ServiceEntityId integer primary key,
        Type            varchar(255),
        Name            varchar(255),
        Customer        varchar(255)
);
go
create table precision.service_affecting_event virtual
(
        ServiceEntityId integer primary key
);
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
                        AlertGroup, OwnerUID, Type, EventId)
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
                        'nco_objserv', 65534, 1, serv_detail.Type );
        end;

end;
go

insert into tools.action_access values ( 33,-1,8001,7 );
insert into tools.action_access values ( 34,-1,8001,8 );
insert into tools.action_access values ( 35,-1,-1,2 );
insert into tools.action_access values ( 36,-1,-1,14 );
go

insert into tools.actions values ( 33,'Show SAE Related Events',-1,1,'','','','',0,'','','','',0,1,'$OMNIHOME/bin/nco_elct -server "%server" -username "%username" -password "%password" -vfile "$OMNIHOME/desktop/default.elv" -ftext "( NmosEntityId in ( select NmosEntityId from precision.entity_service where ServiceEntityId = @NmosEntityId ) )"','','','',0,0,1,'UNIX','','','','',0,0 );
insert into tools.actions values ( 34,'Show SAE Related Events (Windows)',-1,1,'','','','',0,'','','','',0,1,'"$(OMNIHOME)/desktop/ncoelct.exe" -server "%server" -username "%username" -password "%password" -elv "$(OMNIHOME)/ini/default.elv" -elf "$(OMNIHOME)/ini/tool.elf" -params "( NmosEntityId in ( select NmosEntityId from precision.entity_service where Servic','eEntityId = @NmosEntityId ) )"','','',0,0,1,'NT','','','','',0,0 );
insert into tools.actions values ( 35,'Show SAE Related Services',-1,1,'','','','',0,'','','','',0,1,'$OMNIHOME/bin/nco_elct -server "%server" -username "%username" -password "%password" -vfile "$OMNIHOME/desktop/default.elv" -ftext "( NmosEntityId in ( select ServiceEntityId from precision.entity_service where NmosEntityId = @NmosEntityId ) )"','','','',0,0,1,'UNIX','','','','',0,0 );
insert into tools.actions values ( 36,'Show SAE Related Services (Windows)',-1,1,'','','','',0,'','','','',0,1,'"$(OMNIHOME)/desktop/ncoelct.exe" -server "%server" -username "%username" -password "%password" -elv "$(OMNIHOME)/ini/default.elv" -elf "$(OMNIHOME)/ini/tool.elf" -params "( NmosEntityId in ( select ServiceEntityId from precision.entity_service where Nmos','EntityId = @NmosEntityId ) )"','','',0,0,1,'NT','','','','',0,0 );
go

insert into tools.menu_items values ( '0:108',0,108,'Show SAE Related Events','',1,0,33,10,'' );
insert into tools.menu_items values ( '0:109',0,109,'Show &SAE Related Events','',1,0,34,12,'' );
insert into tools.menu_items values ( '0:110',0,110,'Show SAE Related Services','',1,0,35,13,'' );
insert into tools.menu_items values ( '0:111',0,111,'Show SAE Related Services','',1,0,36,14,'' );
go

insert into alerts.col_visuals values ( 'NmosManagedStatus','Managed Status',15,64,1,0 );
insert into alerts.col_visuals values ( 'NmosDomainName','Precision Domain',18,64,1,0 );
insert into alerts.col_visuals values ( 'NmosEntityId','Prec. Entity ID',15,17,1,2 );
go

insert into alerts.conversions values ( 'Class1150','Class',1150,'Socket probe' );
insert into alerts.conversions values ( 'Class1175','Class',1175,'FDF probe' );
insert into alerts.conversions values ( 'Class12540','Class',12540,'CALLMANAGER_Syslog' );
insert into alerts.conversions values ( 'Class12541','Class',12541,'CBB_Syslog' );
insert into alerts.conversions values ( 'Class12542','Class',12542,'CDR_INSERT_Syslog' );
insert into alerts.conversions values ( 'Class12543','Class',12543,'CTI_Syslog' );
insert into alerts.conversions values ( 'Class12544','Class',12544,'DB_LAYER_Syslog' );
insert into alerts.conversions values ( 'Class12545','Class',12545,'JAVA_APPS_Syslog' );
insert into alerts.conversions values ( 'Class12546','Class',12546,'MEDIA_STREAMING_APP_Syslog' );
insert into alerts.conversions values ( 'Class12547','Class',12547,'RIS_Syslog' );
insert into alerts.conversions values ( 'Class12548','Class',12548,'SUMI_Syslog' );
insert into alerts.conversions values ( 'Class12549','Class',12549,'TCD_Syslog' );
insert into alerts.conversions values ( 'Class12550','Class',12550,'TFTP_Syslog' );
insert into alerts.conversions values ( 'Class12700','Class',12700,'SSM' );
insert into alerts.conversions values ( 'Class12701','Class',12701,'SSM-MS SQL' );
insert into alerts.conversions values ( 'Class12702','Class',12702,'SSM-MS Exchange' );
insert into alerts.conversions values ( 'Class12703','Class',12703,'SSM-MS IIS' );
insert into alerts.conversions values ( 'Class12704','Class',12704,'SSM-Oracle' );
insert into alerts.conversions values ( 'Class12705','Class',12705,'SSM-Apache' );
insert into alerts.conversions values ( 'Class12707','Class',12707,'SSM-NT Services' );
insert into alerts.conversions values ( 'Class12709','Class',12709,'SSM-Active Directory' );
insert into alerts.conversions values ( 'Class12710','Class',12710,'SSM-WebSphere' );
insert into alerts.conversions values ( 'Class12712','Class',12712,'SSM-WebLogic' );
insert into alerts.conversions values ( 'Class12715','Class',12715,'SSM-SAP' );
insert into alerts.conversions values ( 'Class1305','Class',1305,'Lucent_naviscore_tmf814' );
insert into alerts.conversions values ( 'Class1350','Class',1350,'Lucent JMTE' );
insert into alerts.conversions values ( 'Class1355','Class',1355,'Lucent_wa' );
insert into alerts.conversions values ( 'Class1360','Class',1360,'Telcordia_wa' );
insert into alerts.conversions values ( 'Class1405','Class',1405,'Nortel_oam5' );
insert into alerts.conversions values ( 'Class1410','Class',1410,'Nortel CEMS' );
insert into alerts.conversions values ( 'Class1415','Class',1415,'Nortel BSSM' );
insert into alerts.conversions values ( 'Class1755','Class',1755,'Tellabs 8600' );
insert into alerts.conversions values ( 'Class1757','Class',1757,'Tellabs MetroWatch' );
insert into alerts.conversions values ( 'Class2055','Class',2055,'Motorola-OMCR-3gpp' );
insert into alerts.conversions values ( 'Class2060','Class',2060,'Motorola SSRN' );
insert into alerts.conversions values ( 'Class2065','Class',2065,'Motorola_OMCR_3gpp_V560' );
insert into alerts.conversions values ( 'Class2070','Class',2070,'Motorola_OMCR1620_v65' );
insert into alerts.conversions values ( 'Class2075','Class',2075,'Motorola_muno' );
insert into alerts.conversions values ( 'Class2470','Class',2470,'eci_lightsoft_tmf814' );
insert into alerts.conversions values ( 'Class2475','Class',2475,'Kodiak EMS' );
delete from alerts.conversions where KeyField =  'Class2500' and Colname = 'Class' and Value = 2500 and Conversion = 'Modular Probe';
insert into alerts.conversions values ( 'Class2550','Class',2550,'MOM probe' );
insert into alerts.conversions values ( 'Class2750','Class',2750,'generic_3gpp_V551' );
insert into alerts.conversions values ( 'Class2945','Class',2945,'Siemens_corba_v2' );
insert into alerts.conversions values ( 'Class2950','Class',2950,'siemens_rc_corba' );
insert into alerts.conversions values ( 'Class2955','Class',2955,'siemens_ac_corba' );
insert into alerts.conversions values ( 'Class2960','Class',2960,'Nec_director_corba' );
insert into alerts.conversions values ( 'Class32000','Class',32000,'NeuSecure' );
delete from alerts.conversions where KeyField =  'Class40030' and Colname = 'Class' and Value = 40030 and Conversion = 'Atrica';
insert into alerts.conversions values ( 'Class40030','Class',40030,'Atrica (SNMP Trap)' );
insert into alerts.conversions values ( 'Class40252','Class',40252,'Netscreen Technologies(ScreenOS)' );
insert into alerts.conversions values ( 'Class40342','Class',40342,'Tellabs 5500 NGX Digital Cross Connect' );
insert into alerts.conversions values ( 'Class40463','Class',40463,'Covaro Networks(NID)' );
delete from alerts.conversions where KeyField =  'Class40480' and Colname = 'Class' and Value = 40480 and Conversion = 'NEC (Pasolink)';
insert into alerts.conversions values ( 'Class40480','Class',40480,'NEC (Pasolink NEO)' );
insert into alerts.conversions values ( 'Class40482','Class',40482,'NEC (Pasolink PNMSj)' );
delete from alerts.conversions where KeyField =  'Class40500' and Colname = 'Class' and Value = 40500 and Conversion = 'Ciena (Lightstack MXA)';
delete from alerts.conversions where KeyField =  'Class40501' and Colname = 'Class' and Value = 40501 and Conversion = 'Ciena (Lightstack GSLAM)';
delete from alerts.conversions where KeyField =  'Class40502' and Colname = 'Class' and Value = 40502 and Conversion = 'Ciena (Lightstack MX)';
delete from alerts.conversions where KeyField =  'Class40503' and Colname = 'Class' and Value = 40503 and Conversion = 'Ciena (Lighthandler OA)';
delete from alerts.conversions where KeyField =  'Class40504' and Colname = 'Class' and Value = 40504 and Conversion = 'Ciena(Wavesmith)';
insert into alerts.conversions values ( 'Class40500','Class',40500,'Ciena (CN2300) TL1' );
insert into alerts.conversions values ( 'Class40501','Class',40501,'Ciena (CN4300) TL1' );
insert into alerts.conversions values ( 'Class40502','Class',40502,'Ciena (CN2200)' );
insert into alerts.conversions values ( 'Class40503','Class',40503,'Ciena (CN4200) TL1' );
insert into alerts.conversions values ( 'Class40504','Class',40504,'Ciena (Wavesmith DN7xxx) SNMP' );
insert into alerts.conversions values ( 'Class40505','Class',40505,'Ciena (OnLine Metro)' );
insert into alerts.conversions values ( 'Class40506','Class',40506,'Ciena (CN4200) SNMP' );
insert into alerts.conversions values ( 'Class40530','Class',40530,'Oracle (Enterprise Manager)' );
insert into alerts.conversions values ( 'Class40535','Class',40535,'Hatteras Networks' );
insert into alerts.conversions values ( 'Class40538','Class',40538,'Laurel Networks (ST Series Service Edge Router)' );
insert into alerts.conversions values ( 'Class40540','Class',40540,'McAfee(Intrushield)' );
insert into alerts.conversions values ( 'Class40541','Class',40541,'McAfee(Foundstone)' );
insert into alerts.conversions values ( 'Class40542','Class',40542,'Lucent Metropolis WSM' );
insert into alerts.conversions values ( 'Class40545','Class',40545,'Pedestal Networks (UBS)' );
insert into alerts.conversions values ( 'Class40550','Class',40550,'Atrica (Syslog)' );
insert into alerts.conversions values ( 'Class40555','Class',40555,'Lucent Feature Server 3000' );
insert into alerts.conversions values ( 'Class40560','Class',40560,'NetTest (MasterQuest)' );
insert into alerts.conversions values ( 'Class40565','Class',40565,'ADVA AG Optical Networking(FSP-NM)' );
insert into alerts.conversions values ( 'Class40570','Class',40570,'Brix Networks' );
insert into alerts.conversions values ( 'Class40575','Class',40575,'Huawei Technologies(OptiX Metro MSTP (NG-SONET))' );
insert into alerts.conversions values ( 'Class40576','Class',40576,'Huawei N2000' );
insert into alerts.conversions values ( 'Class40577','Class',40577,'Huawei AR-series' );
insert into alerts.conversions values ( 'Class40578','Class',40578,'Huawei S-Series' );
insert into alerts.conversions values ( 'Class40579','Class',40579,'Huawei NetEngine' );
insert into alerts.conversions values ( 'Class40580','Class',40580,'Huawei Optix Metro' );
insert into alerts.conversions values ( 'Class40581','Class',40581,'Huawei T2000' );
insert into alerts.conversions values ( 'Class40582','Class',40582,'Huawei M2000' );
insert into alerts.conversions values ( 'Class40583','Class',40583,'Huawei I2000' );
insert into alerts.conversions values ( 'Class40605','Class',40605,'Empirix (Hammer XMS)' );
insert into alerts.conversions values ( 'Class40620','Class',40620,'Dorado Software(RedCell)' );
insert into alerts.conversions values ( 'Class40625','Class',40625,'Infinera (Mpower)' );
insert into alerts.conversions values ( 'Class40630','Class',40630,'Marconi XCD5000 SoftSwitch' );
insert into alerts.conversions values ( 'Class40635','Class',40635,'Opvista(Wavemaster)' );
insert into alerts.conversions values ( 'Class40640','Class',40640,'MetaSwitch EMS' );
insert into alerts.conversions values ( 'Class40642','Class',40642,'Mazu Networks' );
insert into alerts.conversions values ( 'Class40645','Class',40645,'Panduit (Managed Network Solutions)' );
insert into alerts.conversions values ( 'Class40650','Class',40650,'Aktino (AK4000)' );
insert into alerts.conversions values ( 'Class40653','Class',40653,'Apertio One' );
insert into alerts.conversions values ( 'Class40655','Class',40655,'Fujitsu FlashWave' );
insert into alerts.conversions values ( 'Class40660','Class',40660,'Foundry Networks' );
insert into alerts.conversions values ( 'Class40665','Class',40665,'Schmid Telecom - watson TDM' );
insert into alerts.conversions values ( 'Class40670','Class',40670,'AlterPoint DeviceAuthority' );
insert into alerts.conversions values ( 'Class40675','Class',40675,'Radcom Omni-Q' );
insert into alerts.conversions values ( 'Class40676','Class',40676,'Quest Controls' );
insert into alerts.conversions values ( 'Class40677','Class',40677,'Airwave Wireless' );
insert into alerts.conversions values ( 'Class4850','Class',4850,'Tandem_SCP' );
insert into alerts.conversions values ( 'Class4905','Class',4905,'Alcatel 5580 HDM' );
insert into alerts.conversions values ( 'Class4910','Class',4910,'Alcatel_s12' );
insert into alerts.conversions values ( 'Class4955','Class',4955,'Alcatel_SAM' );
insert into alerts.conversions values ( 'Class4957','Class',4957,'Alcatel 5620 sam v5' );
insert into alerts.conversions values ( 'Class4960','Class',4960,'cisco_ctm_corba' );
insert into alerts.conversions values ( 'Class5101','Class',5101,'Nortel OSSI' );
insert into alerts.conversions values ( 'Class5150','Class',5150,'Nortel_evdo' );
insert into alerts.conversions values ( 'Class5155','Class',5155,'Nortel IEMS' );
insert into alerts.conversions values ( 'Class5157','Class',5157,'Nortel_mtosi_V11' );
insert into alerts.conversions values ( 'Class5159','Class',5159,'Nortel CNM' );
insert into alerts.conversions values ( 'Class5161','Class',5161,'Nortel C-EMS' );
insert into alerts.conversions values ( 'Class5450','Class',5450,'SMS' );
insert into alerts.conversions values ( 'Class5550','Class',5550,'MMS' );
insert into alerts.conversions values ( 'Class5650','Class',5650,'WAP' );
insert into alerts.conversions values ( 'Class5749','Class',5749,'Wireless ServiceMonitors (End)' );
insert into alerts.conversions values ( 'Class5750','Class',5750,'TFTP ISM' );
insert into alerts.conversions values ( 'Class61006','Class',61006,'SDEE' );
insert into alerts.conversions values ( 'Class62001','Class',62001,'Cisco ACS' );
insert into alerts.conversions values ( 'Class69000','Class',69000,'PsyQ' );
insert into alerts.conversions values ( 'Class7115','Class',7115,'DSCDEX' );
insert into alerts.conversions values ( 'Class7325','Class',7325,'Alcatel_OMCR_3GPP' );
insert into alerts.conversions values ( 'Class7330','Class',7330,'Lucent_OMC_3GPP' );
insert into alerts.conversions values ( 'Class7706','Class',7706,'Marconi PSB' );
insert into alerts.conversions values ( 'Class7707','Class',7707,'Marconi PSBv42' );
insert into alerts.conversions values ( 'Class7960','Class',7960,'Serviceon_access' );
delete from alerts.conversions where KeyField =  'Class8000' and Colname = 'Class' and Value = 8000 and Conversion = 'Precision';
insert into alerts.conversions values ( 'Class8000','Class',8000,'Precision [Start]' );
insert into alerts.conversions values ( 'Class8001','Class',8001,'NCP SAE' );
insert into alerts.conversions values ( 'Class8049','Class',8049,'Precision [End]' );
insert into alerts.conversions values ( 'Class86001','Class',86001,'Network Assure alarm forwarder' );
insert into alerts.conversions values ( 'Class86002','Class',86002,'Service Assure alarm forwarder' );
insert into alerts.conversions values ( 'Class86003','Class',86003,'Service Assure KQI State Change' );
insert into alerts.conversions values ( 'Class86004','Class',86004,'Service Assure CEM Alarms' );
insert into alerts.conversions values ( 'Class86005','Class',86005,'Service Assure SLA Violation' );
insert into alerts.conversions values ( 'Class8888','Class',8888,'Huawei_N2000_corba' );
insert into alerts.conversions values ( 'Class8889','Class',8889,'Huawei_T2000_corba' );
insert into alerts.conversions values ( 'Class8890','Class',8890,'Huawei_M2000_MML' );
insert into alerts.conversions values ( 'Class8891','Class',8891,'Huawei_M2000_corba' );
insert into alerts.conversions values ( 'Class8895','Class',8895,'TMF814_v2' );
insert into alerts.conversions values ( 'Class8900','Class',8900,'siemens_tnms_TMF814' );
insert into alerts.conversions values ( 'Class9400','Class',9400,'Lucent 5ESS' );
insert into alerts.conversions values ( 'Class9450','Class',9450,'Lucent_nfm' );
insert into alerts.conversions values ( 'Class950','Class',950,'Multiheaded  Ntlog probe' );
insert into alerts.conversions values ( 'NmosManagedStatus0','NmosManagedStatus',0,'Managed' );
insert into alerts.conversions values ( 'NmosManagedStatus1','NmosManagedStatus',1,'Not Managed' );
insert into alerts.conversions values ( 'NmosManagedStatus2','NmosManagedStatus',2,'Not Managed' );
insert into alerts.conversions values ( 'NmosManagedStatus3','NmosManagedStatus',3,'Out Of Scope' );
insert into alerts.conversions values ( 'X733ProbableCause100168','X733ProbableCause',100168,'I/O Device Error (X.733)' );
insert into alerts.conversions values ( 'X733ProbableCause100169','X733ProbableCause',100169,'Software Program Error (X.733)' );
insert into alerts.conversions values ( 'X733ProbableCause100170','X733ProbableCause',100170,'Authentication Failure (X.736)' );
go
-- End of file
