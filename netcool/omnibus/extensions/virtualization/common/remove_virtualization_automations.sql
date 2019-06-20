-------------------------------------------------------------------------
--
--	Licensed Materials - Property of IBM
--
--	5724O4800
--
--	(C) Copyright IBM Corp. 2009. All Rights Reserved
--
--	US Government Users Restricted Rights - Use, duplication
--	or disclosure restricted by GSA ADP Schedule Contract
--	with IBM Corp.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Drop all the vm triggers
------------------------------------------------------------------------
drop trigger vm_correlate;
go

drop trigger vms_new_row;
go

drop trigger vms_deduplication;
go

drop trigger vms_state_change;
go

drop trigger  vms_remove_old_enties;
go

------------------------------------------------------------------------
-- Remove trigger group
------------------------------------------------------------------------
drop trigger group vm_triggers;
go

------------------------------------------------------------------------
-- Drop the vmstatus and vm_events tables
------------------------------------------------------------------------
delete from custom.vmstatus;
go

drop table custom.vmstatus;
go

drop table custom.vm_events;
go

------------------------------------------------------------------------
-- Drop the column added to alerts.status
------------------------------------------------------------------------

alter table alerts.status drop column ParentServerSerial
go
delete from alerts.col_visuals via 'ParentServerSerial'
go
alter table alerts.status drop column ParentIdentifier
go
delete from alerts.col_visuals via 'ParentIdentifier'
go
alter table alerts.status drop column CauseType
go
delete from alerts.col_visuals via 'CauseType'
go
delete from alerts.conversions via 'CauseType0'
go
delete from alerts.conversions via 'CauseType1'
go
delete from alerts.conversions via 'CauseType2'
go

