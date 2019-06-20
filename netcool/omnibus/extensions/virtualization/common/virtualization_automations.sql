-------------------------------------------------------------------------
--
-- Licensed Materials - Property of IBM
--
-- 5724O4800
--
-- (C) Copyright IBM Corp. 2009. All Rights Reserved
--
-- US Government Users Restricted Rights - Use, duplication
-- or disclosure restricted by GSA ADP Schedule Contract
-- with IBM Corp.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Add the trigger group
------------------------------------------------------------------------
create or replace trigger group vm_triggers;
go

------------------------------------------------------------------------
-- Create the vmstatus table
------------------------------------------------------------------------

create table custom.vmstatus persistent
(
   VMHostName  varchar(64) primary key,
   HyperHostName  varchar(64),
   VMStatus int,
   StateChange time
);
go

------------------------------------------------------------------------
-- Add an extra column to alerts.status to show relations
------------------------------------------------------------------------

alter table alerts.status add column ParentServerSerial int
go

insert into alerts.col_visuals values ( 'ParentServerSerial','Correlated Serial',15,64,1,2 );
go

alter table alerts.status add column ParentIdentifier varchar(255)
go

insert into alerts.col_visuals values ( 'ParentIdentifier','Correlated Identifier',15,64,1,2 );
go

alter table alerts.status add column CauseType int
go

insert into alerts.col_visuals values ( 'CauseType','Cause Type',15,64,1,0 );
go

insert into alerts.conversions values ( 'CauseType0','CauseType',0,'Unknown' );
insert into alerts.conversions values ( 'CauseType1','CauseType',1,'Root Cause' );
insert into alerts.conversions values ( 'CauseType2','CauseType',2,'Symptom' );
go

------------------------------------------------------------------------
-- Database triggers: custom.vmstatus
------------------------------------------------------------------------

create or replace trigger vms_new_row
group vm_triggers
priority 1
comment 'Set default value for new enties in CUSTOM.VMSTATUS'
before insert on custom.vmstatus
for each row
begin
   set new.StateChange = getdate();
end;
go


create or replace trigger vms_deduplication
group vm_triggers
priority 1
comment 'Deduplication processing for CUSTOM.VMSTATUS'
before reinsert on custom.vmstatus
for each row
begin
   set old.StateChange = getdate();
   if ( old.HyperHostName != new.HyperHostName)
   then
      -- We have a VMotion event, and need to update many events as a result

      -- Find all the events for this VM only
      for each row vm_event in alerts.status where vm_event.Node = old.VMHostName
      begin
         -- Our VM is being moved. This means any symptom events raised by this
         -- VM might be about to be resolved and should not longer point to a
         -- root cause event from the old hypervisor host. The root cause event
         -- may still be a root cause for errors on other VMs so will be left
         -- unchanged.
         update alerts.status via vm_event.Identifier set Severity = 2, CauseType = 0, ParentIdentifier = ''
            where CauseType = 2;

         -- Any faults on the VM that should be resolved by the move can have
         -- their severity reduced.
         update alerts.status via vm_event.Identifier set Severity = 2 where
            Severity > 2
            and
            AlertGroup in ('Memory Allocation Status', 'CPU Status', 'Network Link Status', 'Disk Status');
      end;

      -- If we are using ITM our virtual machine power events associated with the 
      -- old host will need clearing down. Our ITM VM Up and Down situations will 
      -- fire again after the move and so we will still have any faults reported.
      update alerts.status set Severity = 0 where Severity != 0 and Node = old.HyperHostName
         and Service = old.VMHostName and AlertKey in ('KVM_VM_Down', 'KVM_VM_Up');

      -- Alternatively if we are using SNMP then we need to change the host to the new host.
      update alerts.status set Node = new.HyperHostName where Severity != 0 and Node = old.HyperHostName
         and Service = old.VMHostName and AlertKey in ('Virtual Machine Status');

      set old.HyperHostName = new.HyperHostName;
   end if;

   -- This section is deliberately commented out and is an example or how you
   -- might use the state change of a VM going off-line.
   -- if (( old.VMStatus != new.VMStatus) and (new.VMStatus = 0))
   -- then
         -- Our VM has just gone down. This could be a root cause for many VM alerts.
         -- If our EIF probe were not configured to insert an event into alerts.status
         -- when this happens then we should do so here.
   --    insert into alert.status...
   --end if;
   set old.VMStatus = new.VMStatus;
end;
go

create or replace trigger vms_state_change
group vm_triggers
priority 1
comment 'State change processing for CUSTOM.VMSTATUS'
before update on custom.vmstatus
for each row
begin
   set new.StateChange = getdate();
end;
go

------------------------------------------------------------------------
-- Temporal triggers: custom.vmstatus
------------------------------------------------------------------------

create or replace trigger vms_remove_old_enties
group vm_triggers
priority 20
comment 'Delete virtual machine enties in CUSTOM.VMSTATUS that have been powered off and unchanged for over 2 weeks'
every 300 minutes
begin
   delete from custom.vmstatus where VMStatus = 0 and StateChange < (getdate() - 1209600);
end;
go


------------------------------------------------------------------------
-- Temporal triggers: vm_correlate
------------------------------------------------------------------------

-- A workspace table for the virtual machine to host machine correlation
create table custom.vm_events virtual
(
   VM_Identifier  varchar(255) primary key,
   ErrorType      varchar(64),
   HyperHostName  varchar(64),
   RC_Identifier  varchar(255),
   RC_ServerSerial     int
);
go

create or replace trigger vm_correlate
group vm_triggers
priority 2
comment 'Virtual machine to hypervisor host event correlation'
every 20 seconds
begin
   -- Populate a temporary table with uncorrelated events that
   -- are not already classed as symptoms or root cause and are
   -- of a type that may have a hypervisor host root cause.
   -- Please note the netcool probes running on the VMs should
   -- have rules files that create the AlertGroups being tested
   -- for here.
   for each row vm_corr_cand in alerts.status where
      vm_corr_cand.Severity > 1
      and
      vm_corr_cand.CauseType = 0
      and
      vm_corr_cand.AlertGroup in ('Memory Allocation Status', 'CPU Status', 'Network Link Status', 'Disk Status')
      and
      vm_corr_cand.Node in (select VMHostName from custom.vmstatus)
   begin
         for each row vm_row in custom.vmstatus where vm_corr_cand.Node = vm_row.VMHostName
         begin
            insert into custom.vm_events values (vm_corr_cand.Identifier, vm_corr_cand.AlertGroup, vm_row.HyperHostName);
         end;
   end;

   -- Having found possible symptom events see if we have any
   -- corresponding root cause events.
   for each row root_cause in alerts.status where
      root_cause.Severity > 0
      and
      root_cause.CauseType != 2
      and
      root_cause.AlertGroup in (select ErrorType from custom.vm_events)
      and
      root_cause.Node in (select HyperHostName from custom.vm_events)
   begin
      update custom.vm_events set RC_Identifier = root_cause.Identifier, RC_ServerSerial = root_cause.ServerSerial where
         HyperHostName = root_cause.Node
         and
         ErrorType = root_cause.AlertGroup;
         -- We could add more flexability for different types of root causes here
   end;

   -- Now modify the events if a correlation has been found
   for each row corr_event in custom.vm_events where
      corr_event.RC_Identifier != ''
   begin
      -- At the moment we do the minimum to indicate that we have found a root cause and symptom pair.
      -- The symptom will now point at the root cause via the ParentIdentifier and ParentServerSerial fields
      update alerts.status via corr_event.VM_Identifier set CauseType = 2, ParentServerSerial = corr_event.RC_ServerSerial, ParentIdentifier = corr_event.RC_Identifier, Severity = 2;
      update alerts.status via corr_event.RC_Identifier set CauseType = 1, Severity = 5;
   end;

   -- Clear down our temporary table   
   delete from custom.vm_events;
end;
go

