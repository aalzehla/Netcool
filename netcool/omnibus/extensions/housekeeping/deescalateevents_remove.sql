
-------------------------------------------------------------------
-- DROP THE DE-ESCALATION TRIGGER

DROP TRIGGER hk_de_escalate_events;
go

-------------------------------------------------------------------
-- DROP THE HOUSEKEEPING TRIGGER GROUP
-- DISABLED BY DEFAULT AS IT IS USED BY OTHER TRIGGERS

-- DROP TRIGGER GROUP housekeeping_triggers;
-- go

-------------------------------------------------------------------
-- REMOVE THE PROPERTIES

delete from master.properties where Name like 'HKDeescalate';
go


