-------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2015. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- SQL file contains automation changes to be applied
-- to a v8.1.0 ObjectServer instance to bring it up to v8.1.0 fixpack 5
-- The is file contains changes to the SCA-LA integration triggers only
-- and does not need to be applied if you are not integrating with SCA-LA.
--
-- You should apply this file if you have upgraded the OMNIbusInsightPack
-- to version 1.3.0.2 and are using the xml1302.map file with the
-- MessageBus Gateway version 7.
--
-- The contents of this file should be reviewed prior to adding it to
-- the ObjectServer.
-- Applying this file may cause automations to be replaced, meaning
-- any customization of the automations will be lost
--
-- Prior to applying this file, it is advisable to backup your
-- ObjectServer instance
--
----------------------------------------------------------------------

-------------------------------------------------------------------------------
-- The following configuration is for Smart Cloud Log Analysis (LA) integration
-- NOTE: You will need to re-enable all triggers in the scala_triggers group after 
-- applying this file. 
-- Also NOTE: You should not apply this file if you have installed the NetworkManager Insight
-- Pack for LA integration triggers in the extensions/scala directory. In that case
-- you should apply the 'extensions/scala/update81to81fp5.sql' file.
-- 
-------------------------------------------------------------------------------

create or replace trigger scala_reinsert
group scala_triggers
enabled false
priority 20
comment 'Fast Track an event reinsert for alerts.status to message bus Gateway running in SCALA mode'
after reinsert on alerts.status
for each row
begin
	iduc evtft 'scala' , update , new ;
end;
go
