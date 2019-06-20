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
-- This functionality works by storing successive LastOccurrence timestamps
-- in a custom field XinY.  The timestamps are set, retrieved and updated by
-- means of the NVP functions in the ObjectServer.
--
-- The timestamps are stored in descending chronological order with the most
-- recent value at the front.  Example contents of the XinY field:
--
--    t1="1332419954";t2="1332419954";t3="1332419954";t4="1332419954"
--
-- When a reinserted event is received, the existing values are all shuffled
-- along one space to the right.  For example, the value stored in slot t1
-- gets moved to slot t2, the value stored in slot t2 gets moved along to
-- slot t3, and so on.
--
-- The maximum number of values stored is defined by the threshold value
-- XEvents.  It is not necessary to store any more than this number of
-- timestamps since only XEvents number of values will ever be used in any
-- threshold calculations.  Not storing more that this number of values also
-- prevents the XinY field from filling up unnecessarily - thereby wasting
-- space and unnecessarily increasing the ObjectServer's memory footprint.
--
-- The threshold calculation is not done at the Collection layer.  Instead
-- the values are passed up to the Aggregation layer for inclusion with
-- the master copy of the event.  The threshold calculation will be
-- carried out at the Aggregation layer at this time.
--
-- NOTE: THIS FILE SHOULD ONLY BE APPLIED TO *COLLECTION* LAYER OBJECTSERVERS.
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- STEP 1 OF 4:
--
-- CREATE NEW FIELDS IN COLLECTION OBJECTSERVER
--
-- XinY		THIS IS A NVP FIELD THAT STORES A CHRONOLOGICALLY ORDERED LIST
-- 		OF SUCCESSIVE TIMESTAMPS OF OCCURRENCES OF THIS EVENT
-- NumXinY	THIS KEEPS A TALLY OF THE NUMBER OF INSTANCES OF THE
--		SUPPRESSED EVENT THAT HAVE BEEN RECEIVED
-- XEvents	THIS IS THE FIELD TO HOLD THE FIRST PART OF THE THRESHOLD
--		INFORMATION: THE NUMBER OF EVENTS
-- YSeconds	THIS IS THE FIELD TO HOLD THE SECOND PART OF THE THRESHOLD
--		INFORMATION: THE NUMBER OF SECONDS 

ALTER TABLE alerts.status
	ADD COLUMN XinY VARCHAR(4096)
	ADD COLUMN NumXinY INTEGER
	ADD COLUMN XEvents INTEGER
	ADD COLUMN YSeconds INTEGER;
go

------------------------------------------------------------------------------
-- STEP 2 OF 4:
--
-- CREATE X IN Y PROCEDURES
--
-- PROCEDURE xiny_add_timestamp
-- THE PURPOSE OF THIS PROCEDURE IS TO ADD A NEW TIMESTAMP TO THE XinY FIELD:
-- XinY.  THE XinY FIELD WILL BE ENABLE THRESHOLDING CALCULATIONS TO BE MADE.

CREATE OR REPLACE PROCEDURE xiny_add_timestamp (
IN OUT XinY CHAR(4096),
IN OUT NumXinY INTEGER,
IN XEvents INTEGER,
IN YSeconds INTEGER,
IN ValueToAdd INTEGER)

DECLARE

	MyValueToAdd INTEGER;
	MyNumValues INTEGER;
	MyIndex INTEGER;
	MyPosition INTEGER;
	MyCounter INTEGER;
	ThisTimestamp INTEGER;
	OKtoAdd INTEGER;

BEGIN

	-----------------------------------------------
	-- PROCEDURE xiny_add_timestamp
	-- THE PURPOSE OF THIS PROCEDURE IS TO ADD A NEW TIMESTAMP TO THE ARRAY OF
	-- VALUES STORED IN XinY.  THE VALUES STORED IN THE XinY FIELD ARE USED TO
	-- CALCULATE XinY THRESHOLD BREACHES.
	--
	-- USAGE: execute xiny_add_timestamp (XinY, NumXinY, XEvents, YSeconds, ValueToAdd);

	-----------------------------------------------
	-- INITIALISE VARIABLES

	-- MyValueToAdd: IF THE INCOMING VALUE IS NOT ZERO, THEN THE
	-- VALUE TO ADD WILL BE THE INCOMING VALUE.  IF THE INCOMING
	-- VALUE IS ZERO HOWEVER, THEN SIMPLY ADD THE CURRENT TIMESTAMP
	-- INTO THE XinY ARRAY.

	if (ValueToAdd <> 0) then

		set MyValueToAdd = ValueToAdd;
	else

		set MyValueToAdd = getdate();
	end if;

	-- MyNumValues: THIS VALUE REPRESENTS THE NUMBER OF VALUES
	-- CURRENTLY STORED IN XinY AND MAY BE A VALUE BETWEEN ZERO
	-- AND THE THRESHOLD VALUE.
	-- NumXinY HOLDS THE TOTAL NUMBER OF INSTANCES OF THIS EVENT
	-- HOWEVER THIS NUMBER MAY BE HIGHER THAN THE THRESHOLD VALUE
	-- XEvents.

	-- IF WE HAVE RECEIVED FEWER THAN XEvents INSTANCES OF THE EVENT
	if (NumXinY < XEvents) then

		-- THEN USE THE VALUE STORED IN NumXinY TO GET THE NUMBER OF
		-- ENTRIES IN XinY
		set MyNumValues = NumXinY;

	else

		-- ELSE SIMPLY USE THE MAXIMUM VALUE XEvents SINCE WE
		-- WE DON'T STORE MORE THAN XEvents NUMBER OF VALUES.
		set MyNumValues = XEvents;
	end if;

	-- MyIndex: THIS VARIABLE REPRESENTS THE STARTING POINT FOR
	-- THE NVP SHUFFLING EXERCISE.  IF THERE ARE FEWER THAN
	-- XEvents NUMBER OF NVPs IN XinY, THEN THE STARTING POINT
	-- WILL SIMPLY BE THE NUMBER OF VALUES NumXinY.  IF THERE ARE
	-- XEvents NUMBER OF NVPs IN XinY, THEN THE STARTING POINT
	-- WILL BE THE SECOND TO LAST POSITION.
	-- THE REASON IT IS THE SECOND TO LAST POSITION IS BECAUSE THE
	-- LAST POSITION WILL ALWAYS BE DROPPED (ie. OVERWRITTEN) WHEN
	-- THE NEW ENTRY IS ADDED.

	if (NumXinY < XEvents) then

		set MyIndex = NumXinY;
	else

		set MyIndex = XEvents - 1;
	end if;

	-- MyPosition: THIS VARIABLE INDICATES THE POSITION
	-- IN THE XinY VIRTUAL ARRAY OF THE SHUFFLING CURSOR.
	-- IT SHOULD INITIALLY BE SET TO BE THE STARTING POSITION
	-- OF THE SHUFFLING EXERCISE - WHICH IS MyIndex.

	set MyPosition = MyIndex;

	-- OKtoAdd: THIS VARIABLE IS A FLAG TO INDICATE IF THE
	-- INCOMING VALUE SHOULD BE ADDED TO XinY.  IN THE CASE
	-- WHERE THE ARRAY IS FULL, CHECKS ARE DONE TO ENSURE
	-- THAT THE VALUE TO ADD IS NOT OLDER THAN THE OLDEST
	-- VALUE PRESENT IN XinY.

	set OKtoAdd = 0;

	-----------------------------------------------
	-- THE NVPs ARE STORED IN THE ARRAY XinY IN ASCENDING ORDER.
	-- THE FIRST STEP IS TO SHUFFLE ALL VALUES ALONG TO THE RIGHT
	-- ONE SLOT UNTIL THE CORRECT SLOT TO PUT THE VALUE TO INSERT
	-- (ValueToAdd) IS GREATER THAN THE TIMESTAMP STORED IN THE
	-- CURRENT LOCATION.

	-- NOTE THAT WE ONLY KEEP AT MOST XEvents NUMBER OF ENTRIES
	-- IN XinY AND SO IF THERE IS XEvents NUMBER OF ENTRIES
	-- ALREADY IN XinY, THE LAST VALUE WILL BE INTENTIONALLY
	-- OVERWRITTEN AT THE END.

	-- IF THERE ARE MORE THAN ZERO VALUES IN XinY
	if (MyIndex <> 0) then

		-- ITERATE OVER THE ARRAY MyIndex TIMES
		for MyCounter = 1 to MyIndex do
		begin

			-- FETCH CURRENT POSITION TIMESTAMP
			set ThisTimestamp = to_int(nvp_get(XinY, 't' + to_char(MyPosition)));

			-- AS LONG AS THE TIMESTAMP TO ADD IS GREATER
			-- THAT THE CURRENT POSITION, KEEP SHUFFLING
			-- TIMESTAMPS ALONG.
			if (ThisTimestamp < MyValueToAdd) then

				-- MOVE CURRENT TIMESTAMP VALUE TO NEXT SLOT
				set XinY = nvp_set(XinY, 't' + to_char(MyPosition + 1), ThisTimestamp);

				-- MOVE MyPosition MARKER BACK ONE SLOT
				set MyPosition = MyPosition - 1;

			-- ELSE TIMESTAMP TO ADD SHOULD BE ADDED
			-- TO THE SLOT TO THE RIGHT (+1) OF THE
			-- CURRENT POSITION.  WE CAN STOP ITERATION
			-- OVER THE ARRAY NOW SINCE WE'VE FOUND
			-- THE POINT OF INSERTION FOR THIS VALUE.
			else

				-- BREAK OUT OF THE FOR-LOOP
				break;
			end if;
		end;
	end if;

	-- INCREMENT MyPosition TO MARK THE SLOT THAT
	-- THE TIMESTAMP TO ADD IS TO BE INSERTED.
	set MyPosition = MyPosition + 1;
	
	-- IF XinY IS FULL, CHECK THAT MyValueToAdd IS
	-- NEWER THAN THE VALUE BEING OVERWRITTEN
	if (MyNumValues = XEvents) then

		-- FETCH VALUE STORED AT MyPosition
		set ThisTimestamp = to_int(nvp_get(XinY, 't' + to_char(MyPosition)));
		
		-- CHECK IF MyValueToAdd IS NEWER THAN CURRENT VALUE
		if (MyValueToAdd > ThisTimestamp) then

			set OKtoAdd = 1;
		end if;

	-- ELSE XinY IS NOT FULL - SO ADD VALUE ANYWAY
	else

		set OKtoAdd = 1;
	end if;

	-- IF WE CAN ADD THE NEW VALUE TO THE ARRAY, GO AHEAD
	if (OKtoAdd = 1) then

		-- INSERT A NEW ENTRY INTO THE SLOT MyPosition
		set XinY = nvp_set(XinY, 't' + to_char(MyPosition), MyValueToAdd);

		-- INCREMENT NumXinY
		set NumXinY = NumXinY + 1;
	end if;
end;
go

------------------------------------------------------------------------------
-- STEP 3 OF 4:
--
-- CREATE XinY INSERT TRIGGER

CREATE OR REPLACE TRIGGER xiny_on_insert
GROUP default_triggers
PRIORITY 3
COMMENT '
X IN Y - INSERT CHECK
---------------------
This trigger causes timestamps to be collected every time an occurrence of an
event is received where all of the following are true:

 - the field XEvents contains a valid non-zero value
 - the field YSeconds contains a valid non-zero value
 - the incoming event is not clear (Severity = 0)

The timestamps are passed up to the Aggregation layer where X in Y thresholding
calculations are done.'
BEFORE INSERT ON alerts.status
FOR EACH ROW
WHEN new.XEvents <> 0 and new.YSeconds <> 0 and new.Severity <> 0
begin

	-- ADD AN ENTRY TO THE XinY ARRAY
	execute xiny_add_timestamp (
		new.XinY,
		new.NumXinY,
		new.XEvents,
		new.YSeconds,
		0);

end;
go

------------------------------------------------------------------------------
-- STEP 4 OF 4:
--
-- CREATE XinY REINSERT TRIGGER

CREATE OR REPLACE TRIGGER xiny_on_reinsert
GROUP default_triggers
PRIORITY 3
COMMENT '
X IN Y - REINSERT CHECK
-----------------------
This trigger causes timestamps to be collected every time an occurrence of an
event is received where all of the following are true:

 - the field XEvents contains a valid value
 - the field YSeconds contains a valid value
 - the incoming event is not clear (Severity = 0)

The timestamps are passed up to the Aggregation layer where X in Y thresholding
calculations are done.'
BEFORE REINSERT ON alerts.status
FOR EACH ROW
WHEN new.XEvents <> 0 and new.YSeconds <> 0 and new.Severity <> 0
begin

	-- ADD AN ENTRY TO THE XinY ARRAY
	execute xiny_add_timestamp (
		old.XinY,
		old.NumXinY,
		new.XEvents,
		new.YSeconds,
		0);

end;
go

