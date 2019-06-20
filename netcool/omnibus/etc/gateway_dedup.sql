-------------------------------------------------------------------------
--
--	Licensed Materials - Property of IBM
--
--	5724O4800
--
--	(C) Copyright IBM Corp. 1994, 2007. All Rights Reserved
--
--	US Government Users Restricted Rights - Use, duplication
--	or disclosure restricted by GSA ADP Schedule Contract
--	with IBM Corp.
--
--	Ident: $Id: gateway_dedup.sql 1.3 2003/08/06 13:54:31 ianj Development $
--
------------------------------------------------------------------------

--
-- A deduplication trigger that emulates v3.6 ObjectServer
-- gateway deduplication.
-- The property 'GWDeduplication' controls the trigger's behaviour.
-- The semantics of the value of 'GWDeduplication' are shown below:
-- 0 - Default deduplication but 'Tally' is not incremented.
-- 1 - New row replaces the existing row.
-- 2 - Drop the re-insert
-- 3 - Equivalent to default deduplication
--
create or replace trigger deduplication
group default_triggers
priority 1
comment 'Deduplication processing for ALERTS.STATUS'
before reinsert on alerts.status
for each row
declare gw_dedup char( 255 );
	time_now utc;
begin
	-- Get the date once
	set time_now = getdate();

	if( %user.is_gateway = false ) then
		--
		-- Deduplication for non-gateway clients
		--
		set old.Tally = old.Tally + 1;
		set old.LastOccurrence = new.LastOccurrence;
		set old.StateChange = time_now;
		set old.InternalLast = time_now;
		set old.Summary = new.Summary;
		set old.AlertKey = new.AlertKey;
		if ( (old.Severity = 0) and (new.Severity > 0) )
		then
			set old.Severity = new.Severity;
		end if;
	else
		--
		-- Deduplication for gateway clients.
		-- This section of the trigger emulates
		-- the gateway deduplication in v3.6 ObjectServer.
		--
		set gw_dedup = get_prop_value( 'GWDeduplication' );

		case
			-- Do not increment Tally
			when( gw_dedup = '0' )
			then
		        	set old.LastOccurrence = new.LastOccurrence;
	        		set old.StateChange = time_now;
	        		set old.InternalLast = time_now;
		        	set old.Summary = new.Summary;
		        	set old.AlertKey = new.AlertKey;
		        	if ((old.Severity = 0) and (new.Severity > 0))
		        	then
		       		     set old.Severity = new.Severity;
		        	end if;

			-- Replace the 'old' row with the 'new' row
			when( gw_dedup = '1' )
			then
				set row old = new;

			-- Drop the reinsert
			when( gw_dedup = '2' )
			then
				cancel;

			-- Identical to non-gateway deduplication
			when( gw_dedup = '3' )
			then
				set old.Tally = old.Tally + 1;
		        	set old.LastOccurrence = new.LastOccurrence;
	        		set old.StateChange = time_now;
	        		set old.InternalLast = time_now;
		        	set old.Summary = new.Summary;
		        	set old.AlertKey = new.AlertKey;
		        	if ((old.Severity = 0) and (new.Severity > 0))
		        	then
		       		     set old.Severity = new.Severity;
		        	end if;

			-- Any other value is taken to be a drop
			else
				cancel;
		end case;
	end if;
end;
go
