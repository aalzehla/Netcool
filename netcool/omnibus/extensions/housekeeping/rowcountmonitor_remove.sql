
-------------------------------------------------------------------
-- DROP THE DEFAULT EVENT THRESHOLD PURGE TRIGGER

DROP TRIGGER hk_row_counter;
go

-------------------------------------------------------------------
-- DROP THE HOUSEKEEPING TRIGGER GROUP
-- DISABLED BY DEFAULT AS IT IS USED BY OTHER TRIGGERS

-- DROP TRIGGER GROUP housekeeping_triggers;
-- go

-------------------------------------------------------------------
-- REMOVE THE PROPERTIES

delete from master.properties where Name like 'HKThreshold';
go


