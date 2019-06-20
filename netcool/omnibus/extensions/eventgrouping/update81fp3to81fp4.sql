------------------------------------------------------------------------------
--
-- UPDATE SCRIPT
--
-- THIS SQL SCRIPT UPDATES SCOPE-BASED EVENT GROUPING RELEASED IN 8.1 FP3 TO FP4
--
-- NOTE: THIS SHOULD ONLY BE APPLIED TO AN AGGREGATION OBJECTSERVER
--
------------------------------------------------------------------------------

ALTER TABLE alerts.status ADD COLUMN QuietPeriod INTEGER;
go

insert into master.properties (Name, IntValue) values ('PropagateTTNumber', 1);
go

insert into master.properties (Name, IntValue) values ('PropagateAcknowledged', 1);
go

ALTER TABLE master.correlation_scopeid ADD COLUMN ExpireTime TIME;
go

ALTER TABLE master.correlation_scopealias ADD COLUMN ExpireTime TIME;
go

CREATE INDEX SiteNameIdx ON alerts.status USING HASH (SiteName);
go

------------------------------------------------------------------------------
-- CREATE INSERT TRIGGER ON alerts.status TO CREATE PARENT EVENTS AND LINK CHILDREN
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER correlation_new_row
GROUP correlation_triggers
PRIORITY 20
COMMENT 'Checks for the existence of parent events, updates or creates if necessary'
BEFORE INSERT ON alerts.status
FOR EACH ROW
WHEN get_prop_value('ActingPrimary') %= 'TRUE' and
	new.ScopeID != '' and
	new.AlertGroup not in ('SiteNameParent', 'ScopeIDParent', 'ScopeAliasParent')
declare

	quietperiod		INTEGER;
	now			TIME;
	expiretime		TIME;

	scopealiasmember	INTEGER;
	scopealias		CHAR(255);
	scopealiasparentfound	INTEGER;
	newscopealiasparentneeded INTEGER;
	scopealiasidentifier	CHAR(255);

	scopeparentfound	INTEGER;
	newscopeparentneeded	INTEGER;
	scopeidentifier		CHAR(255);

	siteparentfound		INTEGER;
	scopeparentmoved	INTEGER;
	siteidentifier		CHAR(255);

begin

-- STEP 1: INITIALISE VARIABLES

	set quietperiod = 15 * 60;
	set now = getdate();

	set scopealiasmember = 0;
	set scopealias = '';
	set scopealiasparentfound = 0;
	set newscopealiasparentneeded = 0;
	set scopealiasidentifier = '';

	set scopeparentfound = 0;
	set newscopeparentneeded = 0;
	set scopeidentifier = '';

	set siteparentfound = 0;
	set scopeparentmoved = 0;
	set siteidentifier = '';

	-- USE QUIET PERIOD IF DEFINED IN THE INCOMING EVENT - ELSE USE GLOBAL DEFAULT
	if (new.QuietPeriod != 0) then

		set quietperiod = new.QuietPeriod;
	else

		-- RETRIEVE QUIET PERIOD PROPERTY VALUE AFTER WHICH A NEW INCIDENT SHOULD BE CREATED
		for each row property in master.properties where property.Name = 'QuietPeriod'
		begin

			set quietperiod = property.IntValue;
		end;
	end if;

	-- USE VALUE STORED IN LastOccurrence IF SET, ELSE USE CURRENT TIME
	if (new.LastOccurrence = 0) then

		set now = getdate();
	else 

		set now = new.LastOccurrence;
	end if;

	-- SET DEFAULT VALUE OF ExpireTime BASED ON LastOccurrence
	set expiretime = now + quietperiod;

-- STEP 2: SET UP ScopeAliasParent EVENT, IF APPLICABLE

	-- CHECK FOR ScopeAlias MEMBERSHIP
	for each row scopealiasmemberrow in master.correlation_scopealias_members where
		scopealiasmemberrow.ScopeID = new.ScopeID
	begin

		set scopealiasmember = 1;
		set scopealias = scopealiasmemberrow.ScopeAlias;
	end;

	-- LINK TO ScopeAlias EVENT IF ScopeAlias MEMBER
	if (scopealiasmember = 1) then

		-- LOOK FOR CURRENT ScopeAliasParent
		for each row scopealiasparent in master.correlation_scopealias where 
			scopealiasparent.ScopeAlias = scopealias
		begin

			-- MARK ScopeAlias PARENT AS FOUND
			set scopealiasparentfound = 1;

			-- CHECK IF THE GROUP ExpireTime HAS PASSED
			if (scopealiasparent.ExpireTime < now) then

				-- IF SO, UPDATE PARENT ENTRY AND SET FLAG TO CREATE A NEW ScopeAliasParent
				set scopealiasparent.Identifier = 'ScopeAliasParent:' + scopealiasparent.ScopeAlias + ':' + to_char(now);
				set newscopealiasparentneeded = 1;
			end if;

			-- STORE EITHER EXISTING OR UPDATED ScopeAliasParent IDENTIFIER
			set scopealiasidentifier = scopealiasparent.Identifier;

			-- UPDATE LastOccurrence IN PARENT ENTRY IF INCOMING VALUE IS GREATER
			if (scopealiasparent.LastOccurrence < now) then

				set scopealiasparent.LastOccurrence = now;
			end if;

			-- UPDATE GROUP ExpireTime IF INCOMING ROW EXTENDS IT
			if (scopealiasparent.ExpireTime < expiretime) then

				set scopealiasparent.ExpireTime = expiretime;
			end if;

			-- SAVE ExpireTime IN A VARIABLE FOR LATER USE
			set expiretime = scopealiasparent.ExpireTime;
		end;

		-- ONLY CREATE SYNTHETIC EVENT IF ScopeAlias ENTRY FOUND
		if (scopealiasparentfound = 1) then

			-- INSERT NEW ScopeAliasParent EVENT IF NEEDED
			if (newscopealiasparentneeded = 1) then

				-- INSERT SYNTHETIC ScopeAliasParent EVENT
				insert into alerts.status (
					Identifier,
					Node,
					Class,
					Summary,
					AlertGroup,
					Severity,
					ScopeID,
					FirstOccurrence,
					LastOccurrence,
					QuietPeriod)
				values (
					scopealiasidentifier,
					scopealias,
					99990,
					'SCOPEALIAS: ' + scopealias + ': calculating number of affected scopes...',
					'ScopeAliasParent',
					1,
					scopealias,
					now,
					now,
					expiretime - now);

			-- ELSE UPDATE EXISTING ScopeAliasParent EVENT
			else

				update alerts.status set
					LastOccurrence = now,
					QuietPeriod = expiretime - now
				where Identifier = scopealiasidentifier;

			end if;
		end if;
	end if;

-- STEP 3: SET UP ScopeIDParent EVENT

	-- LOOK FOR CURRENT ScopeIDParent
	for each row parent in master.correlation_scopeid where
		parent.ScopeID = new.ScopeID
	begin

		-- MARK ScopeID PARENT AS FOUND
		set scopeparentfound = 1;

		-- CHECK IF THE GROUP ExpireTime HAS PASSED
		if (parent.ExpireTime < now) then

			-- IF SO, UPDATE PARENT ENTRY AND SET FLAG TO CREATE A NEW ScopeIDParent
			set parent.Identifier =	'ScopeIDParent:' + parent.ScopeID + ':' + to_char(now);
			set newscopeparentneeded = 1;
		end if;

		-- STORE EITHER EXISTING OR UPDATED ScopeIDParent IDENTIFIER
		set scopeidentifier = parent.Identifier;

		-- UPDATE LastOccurrence IN PARENT ENTRY IF INCOMING VALUE IS GREATER
		if (parent.LastOccurrence < now) then

			set parent.LastOccurrence = now;
		end if;

		-- UPDATE GROUP ExpireTime IF INCOMING ROW EXTENDS IT
		if (parent.ExpireTime < expiretime) then

			set parent.ExpireTime = expiretime;
		end if;

		-- SAVE ExpireTime IN A VARIABLE FOR LATER USE
		set expiretime = parent.ExpireTime;
	end;

	-- CREATE PARENT ENTRY IN master.correlation_scopeid IF NONE FOUND
	if (scopeparentfound = 0) then

		-- SET ScopeIDParent IDENTIFIER TO A NEW VALUE
		set scopeidentifier = 'ScopeIDParent:' + new.ScopeID + ':' + to_char(now);

		-- INSERT NEW ScopeIDParent
		insert into master.correlation_scopeid (
			ScopeID,
			LastOccurrence,
			Identifier,
			ExpireTime)
		values (
			new.ScopeID,
			now,
			scopeidentifier,
			expiretime);
	end if;

	-- INSERT ScopeIDParent EVENT INTO alerts.status IF NOT PRESENT OR NEW ONE NEEDED
	if (scopeparentfound = 0 or newscopeparentneeded = 1) then

		-- INSERT SYNTHETIC ScopeIDParent EVENT
		insert into alerts.status (
			Identifier,
			Node,
			Class,
			Summary,
			AlertGroup,
			Severity,
			ScopeID,
			FirstOccurrence,
			LastOccurrence,
			ParentIdentifier,
			QuietPeriod)
		values (
			scopeidentifier,
			new.ScopeID,
			99990,
			'INCIDENT: ' + new.ScopeID + ': calculating number of affected sites...',
			'ScopeIDParent',
			1,
			new.ScopeID,
			now,
			now,
			scopealiasidentifier,
			expiretime - now);

	-- ELSE UPDATE EXISTING ScopeIDParent EVENT
	else

		update alerts.status set
			LastOccurrence = now,
			QuietPeriod = expiretime - now
		where Identifier = scopeidentifier;

	end if;

-- STEP 4: SET UP SiteNameParent EVENT

	-- IF EVENT HAS NO SiteName THEN SET IT TO A DEFAULT
	if (new.SiteName = '') then

		set new.SiteName = new.ScopeID + ' - NO SITE';
	end if;

	-- LOOK FOR CURRENT SiteNameParent
	for each row parent in master.correlation_sitename where
		parent.SiteName = new.SiteName and
		parent.ScopeID = new.ScopeID
	begin

		-- MARK SiteName PARENT AS FOUND
		set siteparentfound = 1;

		-- CHECK IF ScopeIDParent HAS MOVED
		for each row sp in alerts.status where sp.Identifier = parent.Identifier
		begin

			if (sp.ParentIdentifier != scopeidentifier) then

				set scopeparentmoved = 1;
			end if;
		end;

		-- UPDATE THE ENTRY IF WE ARE CREATING A NEW ScopeIDParent
		if (newscopeparentneeded = 1 or scopeparentmoved = 1) then

			set parent.Identifier = 'SiteNameParent:' +
				new.ScopeID + ':' + new.SiteName + ':' + to_char(now);
		end if;

		-- STORE CURRENT SiteName PARENT IDENTIFIER
		set siteidentifier = parent.Identifier;
	end;

	-- CREATE PARENT ENTRY IN master.correlation_sitename IF NONE FOUND
	if (siteparentfound = 0) then

		-- STORE NEW SiteName PARENT IDENTIFIER
		set siteidentifier = 'SiteNameParent:' +
			new.ScopeID + ':' + new.SiteName + ':' + to_char(now);

		-- CREATE THE NEW SiteParent EVENT
		insert into master.correlation_sitename (
			SiteName,
			ScopeID,
			Identifier)
		values (
			new.SiteName,
			new.ScopeID,
			siteidentifier);
	end if;

	-- LINK CURRENT EVENT TO SiteName PARENT
	set new.ParentIdentifier = siteidentifier;

	-- INSERT NEW SiteParent EVENT INTO alerts.status IF NEW OR UPDATED ScopeIDParent
	if (siteparentfound = 0 or newscopeparentneeded = 1 or scopeparentmoved = 1) then

		-- INSERT SYNTHETIC SiteParent EVENT
		insert into alerts.status (
			Identifier,
			Node,
			Class,
			Summary,
			AlertGroup,
			Severity,
			ScopeID,
			SiteName,
			FirstOccurrence,
			LastOccurrence,
			ParentIdentifier,
			QuietPeriod)
		values (
			siteidentifier,
			new.SiteName,
			99990,
			new.SiteName + ': calculating cause and impact...',
			'SiteNameParent',
			1,
			new.ScopeID,
			new.SiteName,
			now,
			now,
			scopeidentifier,
			expiretime - now);

	-- ELSE UPDATE EXISTING SiteParent EVENT
	else

		update alerts.status set
			LastOccurrence = now,
			QuietPeriod = expiretime - now
		where Identifier = siteidentifier;

	end if;
end;
go

------------------------------------------------------------------------------
-- DROP REINSERT TRIGGER
------------------------------------------------------------------------------

DROP TRIGGER correlation_deduplication;
go

------------------------------------------------------------------------------
-- CREATE UPDATE TRIGGER ON alerts.status TO CREATE PARENT EVENTS AND LINK CHILDREN
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER correlation_update
GROUP correlation_triggers
PRIORITY 20
COMMENT 'Checks for the existence of parent events, updates or creates if necessary'
BEFORE UPDATE ON alerts.status
FOR EACH ROW
WHEN get_prop_value('ActingPrimary') %= 'TRUE' and
	((old.ScopeID = '' and new.ScopeID != '') or (old.SiteName = '' and new.SiteName != '')) and
	new.AlertGroup not in ('SiteNameParent', 'ScopeIDParent', 'ScopeAliasParent')
declare

	quietperiod		INTEGER;
	now			TIME;
	expiretime		TIME;

	scopealiasmember	INTEGER;
	scopealias		CHAR(255);
	scopealiasparentfound	INTEGER;
	newscopealiasparentneeded INTEGER;
	scopealiasidentifier	CHAR(255);

	scopeparentfound	INTEGER;
	newscopeparentneeded	INTEGER;
	scopeidentifier		CHAR(255);

	siteparentfound		INTEGER;
	scopeparentmoved	INTEGER;
	siteidentifier		CHAR(255);

begin

-- STEP 1: INITIALISE VARIABLES

	set quietperiod = 15 * 60;
	set now = getdate();

	set scopealiasmember = 0;
	set scopealias = '';
	set scopealiasparentfound = 0;
	set newscopealiasparentneeded = 0;
	set scopealiasidentifier = '';

	set scopeparentfound = 0;
	set newscopeparentneeded = 0;
	set scopeidentifier = '';

	set siteparentfound = 0;
	set scopeparentmoved = 0;
	set siteidentifier = '';

	-- USE QUIET PERIOD IF DEFINED IN THE INCOMING EVENT - ELSE USE GLOBAL DEFAULT
	if (new.QuietPeriod != 0) then

		set quietperiod = new.QuietPeriod;

	else
		-- RETRIEVE QUIET PERIOD PROPERTY VALUE AFTER WHICH A NEW INCIDENT SHOULD BE CREATED
		for each row property in master.properties where property.Name = 'QuietPeriod'
		begin

			set quietperiod = property.IntValue;
		end;
	end if;

	-- USE VALUE STORED IN LastOccurrence IF SET, ELSE USE CURRENT TIME
	if (new.LastOccurrence = 0) then

		set now = getdate();
	else 

		set now = new.LastOccurrence;
	end if;

	-- SET DEFAULT VALUE OF ExpireTime BASED ON LastOccurrence
	set expiretime = now + quietperiod;

-- STEP 2: SET UP ScopeAliasParent EVENT, IF APPLICABLE

	-- CHECK FOR ScopeAlias MEMBERSHIP
	for each row scopealiasmemberrow in master.correlation_scopealias_members where
		scopealiasmemberrow.ScopeID = new.ScopeID
	begin

		set scopealiasmember = 1;
		set scopealias = scopealiasmemberrow.ScopeAlias;
	end;

	-- LINK TO ScopeAlias EVENT IF ScopeAlias MEMBER
	if (scopealiasmember = 1) then

		-- LOOK FOR CURRENT ScopeAliasParent
		for each row scopealiasparent in master.correlation_scopealias where 
			scopealiasparent.ScopeAlias = scopealias
		begin

			-- MARK ScopeAlias PARENT AS FOUND
			set scopealiasparentfound = 1;

			-- CHECK IF THE GROUP ExpireTime HAS PASSED
			if (scopealiasparent.ExpireTime < now) then

				-- IF SO, UPDATE PARENT ENTRY AND SET FLAG TO CREATE A NEW ScopeAliasParent
				set scopealiasparent.Identifier = 'ScopeAliasParent:' + scopealiasparent.ScopeAlias + ':' + to_char(now);
				set newscopealiasparentneeded = 1;
			end if;

			-- STORE EITHER EXISTING OR UPDATED ScopeAliasParent IDENTIFIER
			set scopealiasidentifier = scopealiasparent.Identifier;

			-- UPDATE LastOccurrence IN PARENT ENTRY IF INCOMING VALUE IS GREATER
			if (scopealiasparent.LastOccurrence < now) then

				set scopealiasparent.LastOccurrence = now;
			end if;

			-- UPDATE GROUP ExpireTime IF INCOMING ROW EXTENDS IT
			if (scopealiasparent.ExpireTime < expiretime) then

				set scopealiasparent.ExpireTime = expiretime;
			end if;

			-- SAVE ExpireTime IN A VARIABLE FOR LATER USE
			set expiretime = scopealiasparent.ExpireTime;
		end;

		-- ONLY CREATE SYNTHETIC EVENT IF ScopeAlias ENTRY FOUND
		if (scopealiasparentfound = 1) then

			-- INSERT NEW ScopeAliasParent EVENT IF NEEDED
			if (newscopealiasparentneeded = 1) then

				-- INSERT SYNTHETIC ScopeAliasParent EVENT
				insert into alerts.status (
					Identifier,
					Node,
					Class,
					Summary,
					AlertGroup,
					Severity,
					ScopeID,
					FirstOccurrence,
					LastOccurrence,
					QuietPeriod)
				values (
					scopealiasidentifier,
					scopealias,
					99990,
					'SCOPEALIAS: ' + scopealias + ': calculating number of affected scopes...',
					'ScopeAliasParent',
					1,
					scopealias,
					now,
					now,
					expiretime - now);

			-- ELSE UPDATE EXISTING ScopeAliasParent EVENT
			else

				update alerts.status set
					LastOccurrence = now,
					QuietPeriod = expiretime - now
				where Identifier = scopealiasidentifier;

			end if;
		end if;
	end if;

-- STEP 3: SET UP ScopeIDParent EVENT

	-- LOOK FOR CURRENT ScopeIDParent
	for each row parent in master.correlation_scopeid where
		parent.ScopeID = new.ScopeID
	begin

		-- MARK ScopeID PARENT AS FOUND
		set scopeparentfound = 1;

		-- CHECK IF THE GROUP ExpireTime HAS PASSED
		if (parent.ExpireTime < now) then

			-- IF SO, UPDATE PARENT ENTRY AND SET FLAG TO CREATE A NEW ScopeIDParent
			set parent.Identifier =	'ScopeIDParent:' + parent.ScopeID + ':' + to_char(now);
			set newscopeparentneeded = 1;
		end if;

		-- STORE EITHER EXISTING OR UPDATED ScopeIDParent IDENTIFIER
		set scopeidentifier = parent.Identifier;

		-- UPDATE LastOccurrence IN PARENT ENTRY IF INCOMING VALUE IS GREATER
		if (parent.LastOccurrence < now) then

			set parent.LastOccurrence = now;
		end if;

		-- UPDATE GROUP ExpireTime IF INCOMING ROW EXTENDS IT
		if (parent.ExpireTime < expiretime) then

			set parent.ExpireTime = expiretime;
		end if;

		-- SAVE ExpireTime IN A VARIABLE FOR LATER USE
		set expiretime = parent.ExpireTime;
	end;

	-- CREATE PARENT ENTRY IN master.correlation_scopeid IF NONE FOUND
	if (scopeparentfound = 0) then

		-- SET ScopeIDParent IDENTIFIER TO A NEW VALUE
		set scopeidentifier = 'ScopeIDParent:' + new.ScopeID + ':' + to_char(now);

		-- INSERT NEW ScopeIDParent
		insert into master.correlation_scopeid (
			ScopeID,
			LastOccurrence,
			Identifier,
			ExpireTime)
		values (
			new.ScopeID,
			now,
			scopeidentifier,
			expiretime);
	end if;

	-- INSERT ScopeIDParent EVENT INTO alerts.status IF NOT PRESENT OR NEW ONE NEEDED
	if (scopeparentfound = 0 or newscopeparentneeded = 1) then

		-- INSERT SYNTHETIC ScopeIDParent EVENT
		insert into alerts.status (
			Identifier,
			Node,
			Class,
			Summary,
			AlertGroup,
			Severity,
			ScopeID,
			FirstOccurrence,
			LastOccurrence,
			ParentIdentifier,
			QuietPeriod)
		values (
			scopeidentifier,
			new.ScopeID,
			99990,
			'INCIDENT: ' + new.ScopeID + ': calculating number of affected sites...',
			'ScopeIDParent',
			1,
			new.ScopeID,
			now,
			now,
			scopealiasidentifier,
			expiretime - now);

	-- ELSE UPDATE EXISTING ScopeIDParent EVENT
	else

		update alerts.status set
			LastOccurrence = now,
			QuietPeriod = expiretime - now
		where Identifier = scopeidentifier;

	end if;

-- STEP 4: SET UP SiteNameParent EVENT

	-- IF EVENT HAS NO SiteName THEN SET IT TO A DEFAULT
	if (new.SiteName = '') then

		set new.SiteName = new.ScopeID + ' - NO SITE';
	end if;

	-- LOOK FOR CURRENT SiteNameParent
	for each row parent in master.correlation_sitename where
		parent.SiteName = new.SiteName and
		parent.ScopeID = new.ScopeID
	begin

		-- MARK SiteName PARENT AS FOUND
		set siteparentfound = 1;

		-- CHECK IF ScopeIDParent HAS MOVED
		for each row sp in alerts.status where sp.Identifier = parent.Identifier
		begin

			if (sp.ParentIdentifier != scopeidentifier) then

				set scopeparentmoved = 1;
			end if;
		end;

		-- UPDATE THE ENTRY IF WE ARE CREATING A NEW ScopeIDParent
		if (newscopeparentneeded = 1 or scopeparentmoved = 1) then

			set parent.Identifier = 'SiteNameParent:' +
				new.ScopeID + ':' + new.SiteName + ':' + to_char(now);
		end if;

		-- STORE CURRENT SiteName PARENT IDENTIFIER
		set siteidentifier = parent.Identifier;
	end;

	-- CREATE PARENT ENTRY IN master.correlation_sitename IF NONE FOUND
	if (siteparentfound = 0) then

		-- STORE NEW SiteName PARENT IDENTIFIER
		set siteidentifier = 'SiteNameParent:' +
			new.ScopeID + ':' + new.SiteName + ':' + to_char(now);

		-- CREATE THE NEW SiteParent EVENT
		insert into master.correlation_sitename (
			SiteName,
			ScopeID,
			Identifier)
		values (
			new.SiteName,
			new.ScopeID,
			siteidentifier);
	end if;

	-- LINK CURRENT EVENT TO SiteName PARENT
	set new.ParentIdentifier = siteidentifier;

	-- INSERT NEW SiteParent EVENT INTO alerts.status IF NEW OR UPDATED ScopeIDParent
	if (siteparentfound = 0 or newscopeparentneeded = 1 or scopeparentmoved = 1) then

		-- INSERT SYNTHETIC SiteParent EVENT
		insert into alerts.status (
			Identifier,
			Node,
			Class,
			Summary,
			AlertGroup,
			Severity,
			ScopeID,
			SiteName,
			FirstOccurrence,
			LastOccurrence,
			ParentIdentifier,
			QuietPeriod)
		values (
			siteidentifier,
			new.SiteName,
			99990,
			new.SiteName + ': calculating cause and impact...',
			'SiteNameParent',
			1,
			new.ScopeID,
			new.SiteName,
			now,
			now,
			scopeidentifier,
			expiretime - now);

	-- ELSE UPDATE EXISTING SiteParent EVENT
	else

		update alerts.status set
			LastOccurrence = now,
			QuietPeriod = expiretime - now
		where Identifier = siteidentifier;

	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE DELETE TRIGGER ON alerts.status TO REMOVE PARENT ENTRIES
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER correlation_delete_row
GROUP correlation_triggers
PRIORITY 20
COMMENT 'Deletes from the master.correlation_sitename or master.correlation_scopeid tables where needed'
AFTER DELETE ON alerts.status
FOR EACH ROW
WHEN get_prop_value('ActingPrimary') %= 'TRUE'
begin

	if (old.AlertGroup = 'SiteNameParent') then

		delete from master.correlation_sitename where Identifier = old.Identifier;

	elseif (old.AlertGroup = 'ScopeIDParent') then

		delete from master.correlation_scopeid where Identifier = old.Identifier;

	elseif (old.AlertGroup = 'ScopeAliasParent') then

		update master.correlation_scopealias set
			LastOccurrence = 0,
			Identifier = '',
			Label = '',
			ExpireTime = 0
		 where Identifier = old.Identifier;

	end if;
end;
go

------------------------------------------------------------------------------
-- CREATE A TRIGGER TO UPDATE EXISTING SYNTHETIC PARENT EVENTS
------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER correlation_process_existing_parents
GROUP correlation_triggers
PRIORITY 20
COMMENT 'Update any existing synthetic parent events that are present'
EVERY 17 SECONDS
EVALUATE select SiteName, max(Severity) as MaxSeverity from alerts.status where AlertGroup = 'SiteNameParent' and SiteName != '' and SiteName not like 'NO SITE' and ParentIdentifier in (select Identifier from alerts.status where AlertGroup = 'ScopeIDParent' and FirstOccurrence > (getdate() - QuietPeriod)) group by SiteName BIND AS sitenames
WHEN get_prop_value('ActingPrimary') %= 'TRUE'
declare

	quietperiod INTEGER;
	highcauseweight INTEGER;
	highcausetext CHAR(255);
	highimpactweight INTEGER;
	highimpacttext CHAR(255);
	highseverity INTEGER;
	highlastoccurrence TIME;
	alarmcounter INTEGER;
	alarmcounter2 INTEGER;
	summary CHAR(255);
	propagatettnumber INTEGER;
	propagateacknowledged INTEGER;

begin

	set quietperiod = 15 * 60;
	set propagatettnumber = 1;
	set propagateacknowledged = 1;

	for each row property in master.properties
	begin
		if (property.Name = 'QuietPeriod') then

			set quietperiod = property.IntValue;

		elseif (property.Name = 'PropagateTTNumber') then

			set propagatettnumber = property.IntValue;

		elseif (property.Name = 'PropagateAcknowledged') then

			set propagateacknowledged = property.IntValue;
		end if;
	end;

	for each row parent in alerts.status where
		parent.Severity != 0 and
		parent.AlertGroup in ('SiteNameParent', 'ScopeIDParent', 'ScopeAliasParent') and
		parent.Identifier not in (select ParentIdentifier from alerts.status)
	begin
		if (parent.QuietPeriod = 0 and
			parent.FirstOccurrence < (getdate() - quietperiod)) then

			set parent.Severity = 0;

		elseif (parent.QuietPeriod != 0 and
			parent.FirstOccurrence < (getdate() - parent.QuietPeriod)) then

			set parent.Severity = 0;
		end if;
	end;

	for each row site in alerts.status where site.AlertGroup = 'SiteNameParent'
	begin

		set highcauseweight = 0;
		set highcausetext = 'UNKNOWN';
		set highimpactweight = 0;
		set highimpacttext  = 'UNKNOWN';
		set highseverity = 0;
		set highlastoccurrence = 0;
		set alarmcounter  = 0;
		set summary = '';

		for each row child in alerts.status where
			child.ParentIdentifier = site.Identifier
		begin

			if (child.Severity > 0) then

				set alarmcounter = alarmcounter + 1;

				if (highseverity < child.Severity) then

					set highseverity = child.Severity;
				end if;

				if (child.CauseWeight > highcauseweight) then
	
					set highcauseweight = child.CauseWeight;
					set highcausetext = child.NormalisedAlarmName;
				end if;

				if (child.ImpactWeight > highimpactweight) then
	
					set highimpactweight = child.ImpactWeight;
					set highimpacttext = child.NormalisedAlarmName;
				end if;

				if (highlastoccurrence < child.LastOccurrence) then
	
					set highlastoccurrence = child.LastOccurrence;
				end if;

				if (site.TTNumber != '' and child.TTNumber = '' and
					child.SuppressEscl != 4 and propagatettnumber = 1) then
	
					set child.TTNumber = site.TTNumber;
				end if;

				if (site.Acknowledged = 1 and child.Acknowledged != 1 and
					propagateacknowledged = 1) then

					set child.Acknowledged = site.Acknowledged;
				end if;
			end if;
		end;

		if (site.SiteName != '') then

			for each row sn in sitenames
			begin

				if (sn.SiteName = site.SiteName) then

					if (highseverity < sn.MaxSeverity) then

						set highseverity = sn.MaxSeverity;
					end if;
				end if;
			end;
		end if;

		if (alarmcounter != 0) then

			set site.Grade = alarmcounter;

		elseif (site.Grade != 0) then

			set site.Grade = 0;
		end if;

		set summary = site.SiteName + ': ';

		if (highcausetext = 'UNKNOWN' and highimpacttext = 'UNKNOWN') then

			set summary = summary + 'CAUSE AND IMPACT: UNKNOWN';

		elseif (highcausetext = 'UNKNOWN' and highimpacttext != 'UNKNOWN') then

			set summary = summary + highimpacttext + ' UNKNOWN CAUSE';

		elseif (highcausetext != 'UNKNOWN' and highimpacttext = 'UNKNOWN') then

			set summary = summary + highcausetext + ' UNKNOWN IMPACT';

		elseif (highcausetext != 'UNKNOWN' and highimpacttext = highcausetext) then

			set summary = summary + 'CAUSE AND IMPACT: ' + highcausetext;

		else

			set summary = summary + highimpacttext + ' caused by ' + highcausetext;

		end if;

		if (alarmcounter = 1) then

			set summary = summary + ' (' + to_char(alarmcounter) + ' active alarm)';

		else

			set summary = summary + ' (' + to_char(alarmcounter) + ' active alarms)';

		end if;

		if (site.Severity != 0 or alarmcounter != 0) then

			set site.Summary = summary;

			if (highseverity = 0) then

				set site.Severity = 1;
			else

				set site.Severity = highseverity;
			end if;

			if (highlastoccurrence != 0) then

				set site.LastOccurrence = highlastoccurrence;
			end if;
		end if;
	end;

	for each row scopeid in alerts.status where scopeid.AlertGroup = 'ScopeIDParent'
	begin

		set highseverity = 0;
		set highlastoccurrence = 0;
		set alarmcounter  = 0;
		set alarmcounter2  = 0;
		set summary = '';

		for each row child in alerts.status where
			child.ParentIdentifier = scopeid.Identifier
		begin

			if (child.AlertGroup = 'SiteNameParent') then

				if (child.SiteName like 'NO SITE') then

					set alarmcounter2 = alarmcounter2 + 1;

				else

					set alarmcounter = alarmcounter + 1;
				end if;
			end if;

			if (highlastoccurrence < child.LastOccurrence) then

				set highlastoccurrence = child.LastOccurrence;
			end if;

			if (highseverity < child.Severity) then

				set highseverity = child.Severity;
			end if;

			if (scopeid.TTNumber != '' and child.TTNumber = '' and
				child.SuppressEscl != 4 and propagatettnumber = 1) then

				set child.TTNumber = scopeid.TTNumber;
			end if;

			if (scopeid.Acknowledged = 1 and child.Acknowledged != 1
				and propagateacknowledged = 1) then

				set child.Acknowledged = scopeid.Acknowledged;
			end if;
		end;

		if (alarmcounter != 0) then

			set scopeid.Grade = alarmcounter;

		elseif (alarmcounter2 != 0) then

			set scopeid.Grade = alarmcounter2;

		elseif (scopeid.Grade != 0) then

			set scopeid.Grade = 0;
		end if;

		set summary = 'INCIDENT: ' + scopeid.ScopeID + ': ' + to_char(alarmcounter) + ' site';

		if (alarmcounter = 1) then

			set summary = summary + ' affected';
		else

			set summary = summary + 's affected';
		end if;

		if (alarmcounter2 > 0) then

			set summary = summary + ' - siteless alarms present';
		end if;

		if (scopeid.Severity != 0 or alarmcounter != 0 or alarmcounter2 != 0) then

			set scopeid.Summary = summary;

			if (highseverity = 0) then

				set scopeid.Severity = 1;
			else

				set scopeid.Severity = highseverity;
			end if;

			if (highlastoccurrence != 0) then

				set scopeid.LastOccurrence = highlastoccurrence;
			end if;
		end if;
	end;

	for each row scopealias in alerts.status where scopealias.AlertGroup = 'ScopeAliasParent'
	begin

		set highseverity = 0;
		set highlastoccurrence = 0;
		set alarmcounter  = 0;
		set summary = '';

		for each row child in alerts.status where
			child.ParentIdentifier = scopealias.Identifier
		begin

			set alarmcounter = alarmcounter + 1;

			if (highlastoccurrence < child.LastOccurrence) then

				set highlastoccurrence = child.LastOccurrence;
			end if;

			if (highseverity < child.Severity) then

				set highseverity = child.Severity;
			end if;

			if (scopealias.TTNumber != '' and child.TTNumber = '' and
				child.SuppressEscl != 4 and propagatettnumber = 1) then

				set child.TTNumber = scopealias.TTNumber;
			end if;

			if (scopealias.Acknowledged = 1 and child.Acknowledged != 1
				and propagateacknowledged = 1) then

				set child.Acknowledged = scopealias.Acknowledged;
			end if;
		end;

		if (alarmcounter != 0) then

			set scopealias.Grade = alarmcounter;

		elseif (scopealias.Grade != 0) then

			set scopealias.Grade = 0;
		end if;

		set summary = 'SCOPEALIAS: ' + scopealias.Node + ': ' + to_char(alarmcounter) + ' ScopeID';

		if (alarmcounter = 1) then

			set summary = summary + ' affected';
		else

			set summary = summary + 's affected';
		end if;

		if (scopealias.Severity != 0 or alarmcounter != 0) then

			set scopealias.Summary = summary;

			if (highseverity = 0) then

				set scopealias.Severity = 1;
			else

				set scopealias.Severity = highseverity;
			end if;

			if (highlastoccurrence != 0) then

				set scopealias.LastOccurrence = highlastoccurrence;
			end if;
		end if;
	end;
end;
go

