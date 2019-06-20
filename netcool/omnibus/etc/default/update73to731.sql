-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2010. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SQL file contains schema, data and automation changes to be applied
-- to a 7.3.0 ObjectServer instance to bring it up to v7.3.1
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

ALTER TABLE alerts.status ADD COLUMN BSM_Identity varchar(1024);
go

----------------------------------------------------------------------
-- Updated and new conversions since the 7.3 release
----------------------------------------------------------------------
update alerts.conversions set Conversion = 'Siemens EWSD Server' where KeyField = 'Class10600';
insert into alerts.conversions values ( 'Class2105','Class',2105,'NetQoS' );
insert into alerts.conversions values ( 'Class2107','Class',2107,'Packet Design' );
insert into alerts.conversions values ( 'Class2109','Class',2109,'HP Procurve SNMP' );
insert into alerts.conversions values ( 'Class2110','Class',2110,'HP Procurve Syslog' );
insert into alerts.conversions values ( 'Class401','Class',401,'HP NNMv8' );
insert into alerts.conversions values ( 'Class40141','Class',40141,'Sandvine' );
insert into alerts.conversions values ( 'Class40142','Class',40142,'Agilent' );
insert into alerts.conversions values ( 'Class5001','Class',5001,'RuggedCom' );
insert into alerts.conversions values ( 'Class5012','Class',5012,'ZTE E300' );
insert into alerts.conversions values ( 'Class5013','Class',5013,'ZTE M31' );
insert into alerts.conversions values ( 'Class2460','Class',2460,'Eaton' );
insert into alerts.conversions values ( 'Class4962','Class',4962,'Alcatel 5620 SAM v8' );
insert into alerts.conversions values ( 'Class40143','Class',40143,'Miltel Communications' );
insert into alerts.conversions values ( 'Class40144','Class',40144,'DDL Systems' );
insert into alerts.conversions values ( 'Class87702','Class',87702,'Common Alerting Protocol Events' );
insert into alerts.conversions values ( 'Class87724','Class',87724,'ITNCM' );
insert into alerts.conversions values ( 'Class87725','Class',87725,'Tivoli System Automation' );
update alerts.objclass set Name = 'Siemens EWSD Server' where Tag = 10600;
insert into alerts.objclass values ( 2105,'NetQoS','Default.xpm','' );
insert into alerts.objclass values ( 2107,'Packet Design','Default.xpm','' );
insert into alerts.objclass values ( 2109,'HP Procurve SNMP','Default.xpm','' );
insert into alerts.objclass values ( 2110,'HP Procurve Syslog','Default.xpm','' );
insert into alerts.objclass values ( 401,'HP NNMv8','Default.xpm','' );
insert into alerts.objclass values ( 40141,'Sandvine','Default.xpm','' );
insert into alerts.objclass values ( 40142,'Agilent','Default.xpm','' );
insert into alerts.objclass values ( 5001,'RuggedCom','Default.xpm','' );
insert into alerts.objclass values ( 5012,'ZTE E300','Default.xpm','' );
insert into alerts.objclass values ( 5013,'ZTE M31','Default.xpm','' );
insert into alerts.objclass values ( 2460,'Eaton','Default.xpm','' );
insert into alerts.objclass values ( 4962,'Alcatel 5620 SAM v8','Default.xpm','' );
insert into alerts.objclass values ( 40143,'Miltel Communications','Default.xpm','' );
insert into alerts.objclass values ( 40144,'DDL Systems','Default.xpm','' );
insert into alerts.objclass values ( 87702,'Common Alerting Protocol Events','Default.xpm','' );
insert into alerts.objclass values ( 87724,'ITNCM','Default.xpm','' );
insert into alerts.objclass values ( 87725,'Tivoli System Automation','Default.xpm','' );
go

---------------------------------------------------------------------------
-- Updated disconnect_iduc_missed trigger to increase the maximum no of 
-- iduc_missed signals to 100 before the client is disconnected
-- This trigger replaces the 7.3 disconnect_iduc_missed trigger.
-- The existing trigger should be disabled and this one enabled if you wish
-- to use the updated trigger
---------------------------------------------------------------------------

create or replace trigger disconnect_iduc_missed_731
group iduc_triggers
enabled false
priority 1
comment 'Disconnects real-time clients that have not communicated with objectserver for 100 granularity periods'
on signal iduc_missed
begin
	if( %signal.missed_cycles > 100 )
	then
		insert into alerts.status (Identifier, Summary, Node, Manager, Type, Severity, FirstOccurrence, LastOccurrence, AlertGroup, AlertKey,OwnerUID) values(%signal.process+':'+%signal.node+':iducmissed:'+%signal.username, 'Disconnecting '+%signal.process+' process '+%signal.description+' connected as user '+%signal.username+'.Reason - Missed '+to_char(%signal.missed_cycles)+' iduc cycles.', %signal.node, 'SystemWatch', 1, 1, %signal.at, %signal.at,'IducMissed',%signal.process+':iducmissed',65534); 

		alter system drop connection %signal.connectionid;
	end if;
end;
go

---------------------------------------------------------------------------
-- Updated webtop_compatibility trigger by removing the part dealing with 
-- restriction filters and increased the interval it runs at to more
-- closely match the interval WebGUI polls for the information.
-- The query to fetch the users with ISQL permission has been improved
-- which will reduce the triggers runtime.
-- This trigger replaces all previous versions of the webtop_compatibility 
-- trigger.
-- The existing trigger should be disabled and this one enabled if you wish
-- to use the updated trigger
---------------------------------------------------------------------------

create or replace trigger webtop_compatibility_731
group compatibility_triggers 
enabled false
priority 10
comment 'Populates the master.profiles table for the WebGUI to read.\nNote the 
         trigger can be be disabled if no users are permitted to use the interactive SQL tool within the WebGUI'
every 60 minutes
begin

        -- clean master.profiles
        delete from master.profiles;

        -- Create a row in the master.profiles table for all users
        for each row mpuser in security.users
        begin
                insert into master.profiles ( UID, HasRestriction, Restrict1, Restrict2, Restrict3, Restrict4, AllowISQL )
                        values ( mpuser.UserID, 0, '', '', '', '', 0 );
        end;

        -- Update the users that are allowed to use ISQL
        -- Selects users who are a member of a group which has been assigned a role which has the ISQL permission granted to it.
        for each row isqluser in security.users where isqluser.UserID in ( 
		select UserID from security.group_members where GroupID in ( 
			select GranteeID from security.role_grants where GranteeType = 2 and RoleID in ( 
				select GranteeID from security.permissions where GranteeType = 1 and ObjectType = 1 and ApplicationID = 1 and Object = '' 
                                        and ((Allows & 16777216 ) = 16777216)
                                ) 
                        ) 
                )
        begin
                update master.profiles via isqluser.UserID set AllowISQL = 1;
        end;
end; 
go
