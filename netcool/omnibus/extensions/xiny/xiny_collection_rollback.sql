------------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 2013. All Rights Reserved
--
--      US Government Users Restricted Right - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- X in Y THRESHOLDING FUNCTIONALITY
--
-- This file removes the X in Y thresholding functionality.
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- STEP 1 OF 4:
--
-- REMOVE XinY REINSERT TRIGGER
--

DROP TRIGGER xiny_on_reinsert;
go

------------------------------------------------------------------------------
-- STEP 2 OF 4:
--
-- REMOVE XinY INSERT TRIGGER
--

DROP TRIGGER xiny_on_insert;
go

------------------------------------------------------------------------------
-- STEP 3 OF 4:
--
-- REMOVE X IN Y PROCEDURE
--

DROP PROCEDURE xiny_add_timestamp;
go

------------------------------------------------------------------------------
-- STEP 4 OF 4:
--
-- DELETE NEW OBJECTSERVER FIELDS
--

ALTER TABLE alerts.status
	DROP COLUMN XinY
	DROP COLUMN NumXinY
	DROP COLUMN XEvents
	DROP COLUMN YSeconds;
go

