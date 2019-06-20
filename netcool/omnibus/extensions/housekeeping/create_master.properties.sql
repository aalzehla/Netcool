
------------------------------------------------------------------------------
-- CREATE THE master.properties TABLE
--
-- THIS TABLE IS A PRE-REQUISITE TO ALL THE HOUSEKEEPING TRIGGERS AND MUST
-- BE CREATED PRIOR TO IMPORTING ANY HOUSEKEEPING AUTOMATIONS.  THIS SQL FILE
-- ONLY NEEDS TO BE APPLIED AGAINST YOUR OBJECTSERVER IF IT DOES NOT EXIST.
--

CREATE TABLE master.properties PERSISTENT
(
        Name            VARCHAR(40) PRIMARY KEY,
        CharValue       VARCHAR(255),
        IntValue        INTEGER
);
go


