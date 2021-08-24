-- -------------------------------------------------------
/* Load and clean raw hh survey data -- a.k.a. "Rulesy" */
-- -------------------------------------------------------

/* STEP 0. 	Settings and steps independent of data tables.  */

USE hhts_cleaning
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	--Create mode uber-categories for access/egress characterization, etc.
		DROP TABLE IF EXISTS HHSurvey.transitmodes, HHSurvey.automodes, HHSurvey.pedmodes, HHSurvey.walkmodes, HHSurvey.bikemodes, 
			HHSurvey.nontransitmodes, HHSurvey.trip_ingredients_done, HHSurvey.error_types, HHSurvey.NullFlags;
		CREATE TABLE HHSurvey.TransitModes 	  (mode_id int PRIMARY KEY NOT NULL);
		CREATE TABLE HHSurvey.AutoModes 	  (mode_id int PRIMARY KEY NOT NULL);
		CREATE TABLE HHSurvey.PedModes 		  (mode_id int PRIMARY KEY NOT NULL);
		CREATE TABLE HHSurvey.WalkModes 	  (mode_id int PRIMARY KEY NOT NULL);
		CREATE TABLE HHSurvey.BikeModes 	  (mode_id int PRIMARY KEY NOT NULL);		
		CREATE TABLE HHSurvey.NonTransitModes (mode_id int PRIMARY KEY NOT NULL);
		CREATE TABLE HHSurvey.error_types	  (error_flag nvarchar(100) NULL, vital int NULL);
		CREATE TABLE HHSurvey.NullFlags (flag_value int not null, label int null); 
		GO
	-- I haven't yet found a way to build the CLR regex pattern string from a variable expression, so if the sets in these tables change, the groupings in STEP 5 will likely need to be updated as well.
	-- mode groupings
		INSERT INTO HHSurvey.transitmodes(mode_id) VALUES (23),(24),(26),(27),(28),(31),(32),(41),(42),(52);
		INSERT INTO HHSurvey.automodes(mode_id)    VALUES (3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(16),(17),(18),(21),(22),(33),(34),(36),(37),(47),(70),(71);
		INSERT INTO HHSurvey.PedModes(mode_id) 	   VALUES (1),(2),(72),(73),(74),(75);
		INSERT INTO HHSurvey.walkmodes(mode_id)    VALUES (1);
		INSERT INTO HHSurvey.bikemodes(mode_id)    VALUES (2),(72),(73),(74),(75);				
		INSERT INTO HHSurvey.nontransitmodes(mode_id) SELECT mode_id FROM HHSurvey.pedmodes UNION SELECT mode_id FROM HHSurvey.automodes;
		INSERT INTO HHSurvey.error_types (error_flag, vital) VALUES
			('unlicensed driver',0),
			('underage driver',0),
			('non-student + school trip',0),
			('non-worker + work trip',0),
			('no activity time after',0),			
			('no activity time before',0),
			('missing next trip link',0),
			('missing prior trip link',1),
			('same dest as next',0),
			('same dest as prior',1),
			('same transit line listed 2x+',0),
			('starts, not from home',0),
			('ends day, not home',0),
			('too long at dest',1),
			('excessive speed',1),
			('too slow',1),
			('purpose at odds w/ dest',1),
			('PUDO, no +/- travelers',0),
			('time overlap',1);	
		INSERT INTO HHSurvey.NullFlags (flag_value, label)
		VALUES		(-9999, NULL), 
					(-9998, NULL),
					(-9997, NULL),  
					(995, NULL);

/* STEP 1. 	Load data and create geography fields and indexes  */
	--	Due to field import difficulties, the trip table is imported in two steps--a loosely typed table, then queried using CAST into a tightly typed table.
	-- 	Bulk insert isn't working right now because locations and permissions won't allow it.  For now, manually import household, persons tables via microsoft.import extension (wizard)

/*		DROP TABLE IF EXISTS HHSurvey.Trip;
		GO
		CREATE TABLE HHSurvey.Trip (
			[recid] [int] IDENTITY NOT NULL,
			[hhid] decimal(19,0) NOT NULL,
			[personid] decimal(19,0) NOT NULL,
			[pernum] [int] NULL,
			[tripid] decimal(19,0) NULL,
			[tripnum] [int] NOT NULL DEFAULT 0,
			[traveldate] datetime2 NULL,
			[daynum] [int] NULL,
			[dayofweek] [int] NULL, 
			[data_source] int null,
			[hhgroup] [int] NULL,
			[copied_trip] [int] NULL,
			[completed_at] datetime2 NULL,
			[revised_at] datetime2 NULL,
			[revised_count] int NULL,
			[svy_complete] [int] NULL,
			[depart_time_mam] [int] NULL,
			[depart_time_hhmm] [nvarchar](20) NULL,
			[depart_time_timestamp] datetime2 NULL,
			[arrival_time_mam] [int] NULL,
			[arrival_time_hhmm] [nvarchar](20) NULL,
			[arrival_time_timestamp] datetime2 NULL,
			[origin_name] [nvarchar](255) NULL,
		--	[origin_address] [nvarchar](255) NULL,
			[origin_lat] [float] NULL,
			[origin_lng] [float] NULL,
			[dest_name] [nvarchar](255) NULL,
		--	[dest_address] [nvarchar](255) NULL,
			[dest_lat] [float] NULL,
			[dest_lng] [float] NULL,
			[trip_path_distance] [float] NULL,
			[google_duration] [float] NULL,
			[reported_duration] [float] NULL,
			travel_time float null, -- google_duration for rMove , reported_duration for rSurvey
			[hhmember1] decimal(19,0) NULL,
			[hhmember2] decimal(19,0) NULL,
			[hhmember3] decimal(19,0) NULL,
			[hhmember4] decimal(19,0) NULL,
			[hhmember5] decimal(19,0) NULL,
			[hhmember6] decimal(19,0) NULL,
			[hhmember7] decimal(19,0) NULL,
			[hhmember8] decimal(19,0) NULL,
			[hhmember9] decimal(19,0) NULL,
			[travelers_hh] [int] NOT NULL,
			[travelers_nonhh] [int] NOT NULL,
			[travelers_total] [int] NOT NULL,
			[origin_purpose] [int] NULL,
		--	[origin_purpose_other] [nvarchar](255) NULL,
			[origin_purpose_cat] int null,
			[dest_purpose] [int] NULL,
		--	[d_purpose_other] nvarchar(255) null,
			[dest_purpose_cat] int null,
			[mode_1] smallint NOT NULL,
			[mode_2] smallint NULL,
			[mode_3] smallint NULL,
			[mode_4] smallint NULL,
			mode_type int null,
			[driver] smallint NULL,
			[pool_start] smallint NULL,
			[change_vehicles] smallint NULL,
			[park_ride_area_start] smallint NULL,
			[park_ride_area_end] smallint NULL,
			[park_ride_lot_start] smallint NULL,
			[park_ride_lot_end] smallint NULL,
			[toll] smallint NULL,
			[toll_pay] decimal(8,2) NULL,
			[taxi_type] smallint NULL,
			[taxi_pay] decimal(8,2) NULL,
			[bus_type] smallint NULL,
			[bus_pay] decimal(8,2) NULL,
			[bus_cost_dk] smallint NULL,
			[ferry_type] smallint NULL,
			[ferry_pay] decimal(8,2) NULL,
			[ferry_cost_dk] smallint NULL,
			[air_type] smallint NULL,
			[air_pay] decimal(8,2) NULL,
			[airfare_cost_dk] smallint NULL,
			[mode_acc] smallint NULL,
			[mode_egr] smallint NULL,
			[park] smallint NULL,
			[park_type] smallint NULL,
			[park_pay] decimal(8,2) NULL,
			[transit_system_1] smallint NULL,
			[transit_system_2] smallint NULL,
			[transit_system_3] smallint NULL,
			[transit_system_4] smallint NULL,
			[transit_system_5] smallint NULL,
			[transit_system_6] smallint NULL,
			[transit_line_1] smallint NULL,
			[transit_line_2] smallint NULL,
			[transit_line_3] smallint NULL,
			[transit_line_4] smallint NULL,
			[transit_line_5] smallint NULL,
			[transit_line_6] smallint NULL,
			[speed_mph] [float] NULL,
			[user_added] smallint null,
			[user_merged] smallint NULL,
			[user_split] smallint NULL,
			[analyst_merged] smallint NULL,
			[analyst_split] smallint NULL,
			analyst_split_loop smallint null,
			quality_flag nvarchar(20) null,
			[nonproxy_derived_trip] smallint NULL,
			[psrc_comment] NVARCHAR(255) NULL,
			[psrc_resolved] smallint NULL,
			CONSTRAINT PK_HHSurvey_Trip_Recid PRIMARY KEY CLUSTERED (recid)
		)
		GO

		INSERT INTO HHSurvey.Trip(
			[hhid]
			,[personid]
			,[pernum]
			,[tripid]
			,[tripnum]
			,[traveldate]
			,[daynum]
			,[dayofweek]
			,[data_source]
			,[hhgroup]
			,[copied_trip]
			,[completed_at]
			,[revised_at]
			,[revised_count]
			,[svy_complete]
			,[depart_time_mam]
			,[depart_time_hhmm]
			,[depart_time_timestamp]
			,[arrival_time_mam]
			,[arrival_time_hhmm]
			,[arrival_time_timestamp]
			,[origin_lat]
			,[origin_lng]
			,[origin_name]
			,[dest_name]
			,[dest_lat]
			,[dest_lng]
			,[trip_path_distance]
			,[google_duration]
			,[reported_duration]
			,[travel_time]
			,[hhmember1]
			,[hhmember2]
			,[hhmember3]
			,[hhmember4]
			,[hhmember5]
			,[hhmember6]
			,[hhmember7]
			,[hhmember8]
			,[hhmember9]
			,[travelers_hh]
			,[travelers_nonhh]
			,[travelers_total]
			,[origin_purpose]
		--	,[origin_purpose_other]
			,[dest_purpose]
		--	,[dest_purpose_other]
			,[mode_1]
			,[mode_2]
			,[mode_3]
			,[mode_4]
			,[driver]
			,[pool_start]
			,[change_vehicles]
			,[park_ride_area_start]
			,[park_ride_area_end]
			,[park_ride_lot_start]
			,[park_ride_lot_end]
			,[toll]
			,[toll_pay]
			,[taxi_type]
			,[taxi_pay]
			,[bus_type]
			,[bus_pay]
			,[bus_cost_dk]
			,[ferry_type]
			,[ferry_pay]
			,[ferry_cost_dk]
			,[air_type]
			,[air_pay]
			,[airfare_cost_dk]
			,[mode_acc]
			,[mode_egr]
			,[park]
			,[park_type]
			,[park_pay]
			,[transit_system_1]
			,[transit_system_2]
			,[transit_system_3]
			,[transit_system_4]
			,[transit_system_5]
			,[transit_system_6]
			,[transit_line_1]
			,[transit_line_2]
			,[transit_line_3]
			,[transit_line_4]
			,[transit_line_5]
			,[transit_line_6]			
			,[speed_mph]
			,[nonproxy_derived_trip]
			,[quality_flag]
			,analyst_split_loop
			,dest_purpose_cat
			,mode_type
			,o_purp_cat
			,user_added
			,[user_merged]
			,[user_split]
			,[analyst_merged]
			,[analyst_split]
			)
		SELECT 
			[hhid]
			,[personid]
			,[pernum]
			,t.[tripid]
			,[tripnum]
			,convert(date, [traveldate], 121)
			,[daynum]
			,[dayofweek]
			,[data_source]
			,[hhgroup]
			,[copied_trip]
			,convert(datetime2, [completed_at], 121)
			,convert(datetime2, [revised_at], 121)
			,cast([revised_count] AS int)
			,[svy_complete]
			,[depart_time_mam]
			,[depart_time_hhmm]
			,convert(datetime2, depart_time_timestamp, 121)
			,[arrival_time_mam]
			,[arrival_time_hhmm]
			,convert(datetime2, arrival_time_timestamp, 121)
			,[origin_lat]
			,[origin_lng]
			,l.[origin_name]
			,l.[dest_name]
			,[dest_lat]
			,[dest_lng]
			,[trip_path_distance]
			,[google_duration]
			,[reported_duration]
			,case hhgroup
				when 1 then [google_duration] -- rMove
				when 2 then cast([reported_duration] as float) -- rSurvey
			end
			,[hhmember1] 
			,[hhmember2]
			,[hhmember3]
			,[hhmember4]
			,[hhmember5]
			,[hhmember6]
			,[hhmember7]
			,[hhmember8]
			,NULL
			,[travelers_hh]
			,[travelers_nonhh]
			,[travelers_total]
			,[origin_purpose]
			,[o_purpose_other]
			,[dest_purpose]
		--	,[d_purpose_other]
			,cast([mode_1] as smallint)
			,cast([mode_2] as smallint)
			,cast([mode_3] as smallint)
			,cast([mode_4] as smallint)
			,cast([driver] as smallint)
			,cast([pool_start] as smallint)
			,cast([change_vehicles] as smallint)
			,cast([park_ride_area_start] as smallint)
			,cast([park_ride_area_end] as smallint)
			,cast([park_ride_lot_start] as smallint)
			,cast([park_ride_lot_end] as smallint)
			,cast([toll] as smallint)
			,cast([toll_pay] as decimal(8,2))
			,cast([taxi_type] as smallint)
			,cast([taxi_pay] as decimal(8,2))
			,cast([bus_type] as smallint)
			,cast([bus_pay] as decimal(8,2))
			,cast([bus_cost_dk] as smallint)
			,cast([ferry_type] as smallint)
			,cast([ferry_pay] as decimal(8,2))
			,cast([ferry_cost_dk] as smallint)
			,cast([air_type] as smallint)
			,cast([air_pay] as decimal(8,2))
			,cast([airfare_cost_dk] as smallint)
			,cast([mode_acc] as smallint)
			,cast([mode_egr] as smallint)
			,cast([park] as smallint)
			,cast([park_type] as smallint)
			,cast([park_pay] as decimal(8,2))
			,cast([transit_system_1] as smallint)
			,cast([transit_system_2] as smallint)
			,cast([transit_system_3] as smallint)
			,cast([transit_system_4] as smallint)
			,cast([transit_system_5] as smallint)
			,cast([transit_system_6] as smallint)			
			,cast([transit_line_1] as smallint)
			,cast([transit_line_2] as smallint)
			,cast([transit_line_3] as smallint)
			,cast([transit_line_4] as smallint)
			,cast([transit_line_5] as smallint)
			,cast([transit_line_6] as smallint)
			,[speed_mph]
			,cast([nonproxy_derived_trip] as bit)
			,[Quality_flag]
			,analyst_split_loop
			,dest_purpose_cat
			,mode_type
			,o_purp_cat
			,user_added
			,[user_merged]
			,[user_split]
			,[analyst_merged]
			,[analyst_split]
			FROM dbo.[4_trip] as t
				LEFT JOIN dbo.location_names_082119 as l ON t.tripid = l.tripid
			ORDER BY tripid;
		GO */

		ALTER TABLE HHSurvey.Trip --additional destination address fields
			ADD origin_geog 	GEOGRAPHY NULL,
				dest_geog 		GEOGRAPHY NULL,
				dest_county		varchar(3) NULL,
				dest_city		varchar(25) NULL,
				dest_zip		varchar(5) NULL,
				dest_is_home	bit NULL, 
				dest_is_work 	bit NULL,
				modes 			nvarchar(255),
				transit_systems nvarchar(255),
				transit_lines 	nvarchar(255),
				psrc_inserted 	bit NULL,
				revision_code 	nvarchar(255) NULL,
				psrc_resolved   smallint NULL,
				psrc_comment 	nvarchar(255) NULL;

		ALTER TABLE HHSurvey.household 	ADD home_geog 	GEOGRAPHY 	NULL,
											home_lat 	FLOAT 		NULL,
											home_lng	FLOAT 		NULL,
											sample_geog GEOGRAPHY 	NULL;
		ALTER TABLE HHSurvey.person 	ADD work_geog 	GEOGRAPHY	NULL,
											school_geog GEOGRAPHY 	NULL;
		GO
						
		UPDATE HHSurvey.Trip	SET 	dest_geog 	= geography::STGeomFromText('POINT(' + CAST(dest_lng 	  AS VARCHAR(20)) + ' ' + CAST(dest_lat 	AS VARCHAR(20)) + ')', 4326),
							  		  origin_geog   = geography::STGeomFromText('POINT(' + CAST(origin_lng    AS VARCHAR(20)) + ' ' + CAST(origin_lat 	AS VARCHAR(20)) + ')', 4326);
		UPDATE HHSurvey.household 	SET home_geog 	= geography::STGeomFromText('POINT(' + CAST(reported_lng  AS VARCHAR(20)) + ' ' + CAST(reported_lat AS VARCHAR(20)) + ')', 4326),
									  sample_geog   = geography::STGeomFromText('POINT(' + CAST(sample_lng    AS VARCHAR(20)) + ' ' + CAST(sample_lat 	AS VARCHAR(20)) + ')', 4326);
		UPDATE HHSurvey.person 		SET work_geog	= geography::STGeomFromText('POINT(' + CAST(work_lng 	  AS VARCHAR(20)) + ' ' + CAST(work_lat 	AS VARCHAR(20)) + ')', 4326),
								      school_geog	= geography::STGeomFromText('POINT(' + CAST(school_loc_lng  AS VARCHAR(20)) + ' ' + CAST(school_loc_lat  AS VARCHAR(20)) + ')', 4326);

		--ALTER TABLE HHSurvey.Trip ADD CONSTRAINT PK_recid PRIMARY KEY CLUSTERED (recid) WITH FILLFACTOR=80;
		CREATE INDEX person_idx ON HHSurvey.Trip (personid ASC);
		CREATE INDEX tripnum_idx ON HHSurvey.Trip (tripnum ASC);
		CREATE INDEX dest_purpose_idx ON HHSurvey.Trip (dest_purpose);
		CREATE INDEX travelers_total_idx ON HHSurvey.Trip(travelers_total);
		GO 

		CREATE SPATIAL INDEX dest_geog_idx   ON HHSurvey.Trip(dest_geog) 		USING GEOGRAPHY_AUTO_GRID;
		CREATE SPATIAL INDEX origin_geog_idx ON HHSurvey.Trip(origin_geog) 		USING GEOGRAPHY_AUTO_GRID;
		CREATE SPATIAL INDEX home_geog_idx 	 ON HHSurvey.household(home_geog) 	USING GEOGRAPHY_GRID;
		CREATE SPATIAL INDEX sample_geog_idx ON HHSurvey.household(sample_geog) USING GEOGRAPHY_AUTO_GRID;
		CREATE SPATIAL INDEX work_geog_idx 	 ON HHSurvey.person(work_geog) 		USING GEOGRAPHY_AUTO_GRID;		

	/* Determine legitimate home location: */ 
	
		DROP TABLE IF EXISTS #central_home_tripend;
		GO
		
		--determine central home-purpose trip end, i.e. the home-purpose destination w/ shortest cumulative distance to all other household home-purpose destinations.
		WITH cte AS 		
		(SELECT t1.hhid,
				t1.recid, 
				ROW_NUMBER() OVER (PARTITION BY t1.hhid ORDER BY sum(t1.dest_geog.STDistance(t2.dest_geog)) ASC) AS ranker
		 FROM HHSurvey.Trip AS t1 JOIN HHSurvey.Trip AS t2 ON t1.hhid = t2.hhid AND t1.dest_purpose = 1 AND t2.dest_purpose = 1 
		 WHERE  EXISTS (SELECT 1 FROM HHSurvey.Household AS h WHERE h.hhid = t1.hhid AND h.home_geog IS NULL)
		 	AND EXISTS (SELECT 1 FROM HHSurvey.Household AS h WHERE h.hhid = t2.hhid AND h.home_geog IS NULL)
		 GROUP BY t1.hhid, t1.recid
		)
		SELECT cte.hhid, cte.recid INTO #central_home_tripend
			FROM cte 			
			WHERE cte.ranker = 1;
		
		UPDATE h					-- Default is reported home location; invalidate when not within 300m of most central home-purpose trip
			SET h.home_geog = NULL
			FROM HHSurvey.Household AS h JOIN #central_home_tripend AS te ON h.hhid = te.hhid JOIN HHSurvey.Trip AS t ON te.recid = t.recid
			WHERE t.dest_geog.STDistance(h.home_geog) > 300;	

		UPDATE h					-- When Reported home location is invalidated, fill with sample home location when within 300m of of most central home-purpose trip
			SET h.home_geog = h.sample_geog
			FROM HHSurvey.Household AS h JOIN #central_home_tripend AS te ON h.hhid = te.hhid JOIN HHSurvey.Trip AS t ON te.recid = t.recid
			WHERE h.home_geog IS NULL 
				AND t.dest_geog.STDistance(h.sample_geog) < 300;				

		UPDATE h					-- When neither Reported or Sampled home location is valid, take the most central home-purpose trip destination
			SET h.home_geog = t.dest_geog
			FROM HHSurvey.Household AS h JOIN #central_home_tripend AS te ON h.hhid = te.hhid JOIN HHSurvey.Trip AS t ON t.recid = te.recid
			WHERE h.home_geog IS NULL;

		UPDATE 	h	-- Gives back latitude and longitude of the determined home location point
			SET h.home_lat = h.home_geog.Lat,
				h.home_lng = h.home_geog.Long 
			FROM HHSurvey.Household AS h;

		DROP TABLE #central_home_tripend;

		--similarly determine central primary work-purpose trip end, on a person- rather than household-basis
		WITH cte AS 		
		(SELECT t1.personid,
				t1.recid, 
				ROW_NUMBER() OVER (PARTITION BY t1.personid ORDER BY sum(t1.dest_geog.STDistance(t2.dest_geog)) ASC) AS ranker
		 FROM HHSurvey.Trip AS t1 JOIN HHSurvey.Trip AS t2 ON t1.personid = t2.personid AND t1.dest_purpose = 10 AND t2.dest_purpose = 10 
		 WHERE  EXISTS (SELECT 1 FROM HHSurvey.Person AS p WHERE p.personid = t1.personid AND p.work_geog IS NULL)
		 	AND EXISTS (SELECT 1 FROM HHSurvey.Person AS p WHERE p.personid = t2.personid AND p.work_geog IS NULL)
		 GROUP BY t1.personid, t1.recid
		)
		SELECT cte.personid, cte.recid INTO #central_work_tripend
			FROM cte 			
			WHERE cte.ranker = 1;

		UPDATE p					-- When neither Reported or Sampled work location is valid, take the most central work-purpose trip destination
			SET p.work_geog = t.dest_geog
			FROM HHSurvey.Person AS p JOIN #central_work_tripend AS te ON p.personid = te.personid JOIN HHSurvey.Trip AS t ON t.recid = te.recid JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code 
			WHERE p.work_geog IS NULL AND (p.employment < 7 OR vl.label LIKE 'Missing%');

		UPDATE p	-- Gives back latitude and longitude of the determined work location point
			SET p.work_lat = p.work_geog.Lat,
				p.work_lng = p.work_geog.Long 
			FROM HHSurvey.Person AS p;
		
		DROP TABLE #central_work_tripend;

		--similarly determine central school-purpose trip end, on a person- rather than household-basis
		WITH cte AS 		
		(SELECT t1.personid,
				t1.recid, 
				ROW_NUMBER() OVER (PARTITION BY t1.personid ORDER BY sum(t1.dest_geog.STDistance(t2.dest_geog)) ASC) AS ranker
		 FROM HHSurvey.Trip AS t1 JOIN HHSurvey.Trip AS t2 ON t1.personid = t2.personid AND t1.dest_purpose = 6 AND t2.dest_purpose = 6
		 WHERE  EXISTS (SELECT 1 FROM HHSurvey.Person AS p WHERE p.personid = t1.personid AND p.school_geog IS NULL)
		 	AND EXISTS (SELECT 1 FROM HHSurvey.Person AS p WHERE p.personid = t2.personid AND p.school_geog IS NULL)
		 GROUP BY t1.personid, t1.recid
		)
		SELECT cte.personid, cte.recid INTO #central_school_tripend
			FROM cte 			
			WHERE cte.ranker = 1;	

		UPDATE p					-- When reported school location is not valid, take the most central school-purpose trip destination
			SET p.school_geog = t.dest_geog
			FROM HHSurvey.Person AS p JOIN #central_school_tripend AS te ON p.personid = te.personid JOIN HHSurvey.Trip AS t ON t.recid = te.recid JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code 
			WHERE p.school_geog IS NULL AND (p.student IN(2,3) OR (vl.label LIKE 'Missing%'));
	
		UPDATE 	p	-- Gives back latitude and longitude of the determined school location point
			SET p.school_loc_lat = p.school_geog.Lat,
				p.school_loc_lng = p.school_geog.Long 
			FROM HHSurvey.Person AS p;

		DROP TABLE #central_school_tripend;

	-- Convert rMoves trip distances to miles; rSurvey records are already reported in miles
	/* Not necessary for 2019, as rMove is reported in miles rather than meters
		UPDATE HHSurvey.Trip SET trip.trip_path_distance = trip.trip_path_distance / 1609.344 WHERE trip.hhgroup = 1
	*/

/* STEP 2.  Set up auto-logging and recalculate  */

	--Remove any audit trail records that may already exist from previous runs of Rulesy.
	DROP TABLE IF EXISTS HHSurvey.tblTripAudit;
	GO
	CREATE TABLE [HHSurvey].[tblTripAudit](
	[Type] [char](1) NULL,
	[recid] [bigint] NOT NULL,
	[FieldName] [varchar](128) NULL,
	[OldValue] [nvarchar](max) NULL,
	[NewValue] [nvarchar](max) NULL,
	[UpdateDate] [datetime] NULL,
	[UserName] [varchar](128) NULL
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
	GO

	-- create an auto-logging trigger for updates to the trip table
		DROP TRIGGER IF EXISTS HHSurvey.tr_trip;
		GO
		create  trigger tr_trip on HHSurvey.[trip] for insert, update, delete
		as

		declare @bit int ,
		    @field int ,
		    @maxfield int ,
		    @char int ,
		    @fieldname varchar(128) ,
		    @TableName varchar(128) ,
			@SchemaName varchar(128),
		    @PKCols varchar(1000) ,
		    @sql varchar(2000), 
		    @UpdateDate varchar(21) ,
		    @UserName varchar(128) ,
		    @Type char(1) ,
		    @PKSelect varchar(1000)
		    
		    select @TableName = 'trip'
			select @SchemaName = 'HHSurvey'

		    -- date and user
		    select  @UserName = system_user ,
		        @UpdateDate = convert(varchar(8), getdate(), 112) + ' ' + convert(varchar(12), getdate(), 114)

		    -- Action
		    if exists (select * from inserted)
		        if exists (select * from deleted)
		            select @Type = 'U'
		        else
		            select @Type = 'I'
		    else
		        select @Type = 'D'
		    
		    -- get list of columns
		    select * into #ins from inserted
		    select * into #del from deleted
		    
		    -- Get primary key columns for full outer join
		    select  @PKCols = coalesce(@PKCols + ' and', ' on') + ' i.[' + c.COLUMN_NAME + '] = d.[' + c.COLUMN_NAME + ']'
		    from    INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
		        INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
		    where   pk.TABLE_NAME = @TableName
		    and CONSTRAINT_TYPE = 'PRIMARY KEY'
		    and c.TABLE_NAME = pk.TABLE_NAME
		    and c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
		    
		    -- Get primary key select for insert.  @PKSelect will contain the recid info defining the precise line
		    -- in trips that is edited.  This variable is formatted to be used as part of the SELECT clause in the query 
		    -- (below) that inserts the data into.
		    select  @PKSelect = coalesce(@PKSelect+',','') + 'convert(varchar(100),coalesce(i.[' + COLUMN_NAME +'],d.[' + COLUMN_NAME + ']))' 
		        from    INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
		            INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
		        where   pk.TABLE_NAME = @TableName
				and pk.TABLE_SCHEMA = @SchemaName
				AND c.TABLE_SCHEMA = @SchemaName
		        and CONSTRAINT_TYPE = 'PRIMARY KEY'
		        and c.TABLE_NAME = pk.TABLE_NAME
		        and c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME
		        ORDER BY c.ORDINAL_POSITION

		    if @PKCols is null
		    begin
		        raiserror('no PK on table %s', 16, -1, @TableName)
		        return
		    end

		    select @field = 0, @maxfield = max(ORDINAL_POSITION) 
			from INFORMATION_SCHEMA.COLUMNS 
			where TABLE_NAME = @TableName 
				and TABLE_SCHEMA = @SchemaName

		    while @field < @maxfield
		    begin
		        select @field = min(ORDINAL_POSITION) 
				from INFORMATION_SCHEMA.COLUMNS 
				where TABLE_NAME = @TableName 
					and ORDINAL_POSITION > @field 
					and TABLE_SCHEMA = @SchemaName
					and data_type <> 'geography'

		        select @bit = (@field - 1 )% 8 + 1

		        select @bit = power(2,@bit - 1)

		        select @char = ((@field - 1) / 8) + 1

		        if ( substring(COLUMNS_UPDATED(),@char, 1) & @bit > 0 or @Type in ('I','D') )
		        begin
		            select @fieldname = COLUMN_NAME 
					from INFORMATION_SCHEMA.COLUMNS 
					where TABLE_NAME = @TableName 
						and ORDINAL_POSITION = @field 
						and TABLE_SCHEMA = @SchemaName

		            begin
		                select @sql =       'insert into HHSurvey.tblTripAudit (Type, recid, FieldName, OldValue, NewValue, UpdateDate, UserName)'
		                select @sql = @sql +    ' select ''' + @Type + ''''
		                select @sql = @sql +    ',' + @PKSelect
		                select @sql = @sql +    ',''' + @fieldname + ''''
		                select @sql = @sql +    ',convert(varchar(max),d.[' + @fieldname + '])'
		                select @sql = @sql +    ',convert(varchar(max),i.[' + @fieldname + '])'
		                select @sql = @sql +    ',''' + @UpdateDate + ''''
		                select @sql = @sql +    ',''' + @UserName + ''''
		                select @sql = @sql +    ' from #ins i full outer join #del d'
		                select @sql = @sql +    @PKCols
		                select @sql = @sql +    ' where i.[' + @fieldname + '] <> d.[' + @fieldname + ']'
		                select @sql = @sql +    ' or (i.[' + @fieldname + '] is null and  d.[' + @fieldname + '] is not null)' 
		                select @sql = @sql +    ' or (i.[' + @fieldname + '] is not null and  d.[' + @fieldname + '] is null)' 
		                exec (@sql)
		            end
		        end
		    end
		GO
		ALTER TABLE HHSurvey.Trip DISABLE TRIGGER tr_trip
	-- end of trigger creation
		
	-- Enable the audit trail/logger
		ALTER TABLE HHSurvey.Trip ENABLE TRIGGER [tr_trip]

	-- Tripnum must be sequential or later steps will fail. Create procedure and employ where required.
		DROP PROCEDURE IF EXISTS HHSurvey.tripnum_update;
		GO
		CREATE PROCEDURE HHSurvey.tripnum_update 
			@target_personid decimal = NULL --optional parameter
		AS
		BEGIN
		WITH tripnum_rev(recid, personid, tripnum) AS
			(SELECT t0.recid, t0.personid, ROW_NUMBER() OVER(PARTITION BY t0.personid ORDER BY t0.depart_time_timestamp ASC) AS tripnum 
			 	FROM HHSurvey.Trip AS t0 
				WHERE t0.personid = CASE WHEN @target_personid IS NULL THEN t0.personid ELSE @target_personid END)
		UPDATE t
			SET t.tripnum = tripnum_rev.tripnum
			FROM HHSurvey.Trip AS t JOIN tripnum_rev ON t.recid=tripnum_rev.recid AND t.personid = tripnum_rev.personid
			WHERE t.tripnum <> tripnum_rev.tripnum;
		END
		GO
		EXECUTE HHSurvey.tripnum_update;

	-- Recalculation of derived fields

		DROP PROCEDURE IF EXISTS HHSurvey.recalculate_after_edit;
		GO
		CREATE PROCEDURE HHSurvey.recalculate_after_edit
			@target_personid decimal = NULL --optional to limit to the record just edited 
		AS BEGIN
		SET NOCOUNT ON

		EXECUTE HHSurvey.tripnum_update @target_personid;

		WITH cte AS
		(SELECT t0.personid, t0.depart_time_timestamp AS start_stamp
				FROM HHSurvey.Trip AS t0 
				WHERE t0.tripnum = 1 AND t0.depart_time_timestamp IS NOT NULL)
		UPDATE t SET
			t.depart_time_hhmm  = FORMAT(t.depart_time_timestamp,N'hh\:mm tt','en-US'),
			t.arrival_time_hhmm = FORMAT(t.arrival_time_timestamp,N'hh\:mm tt','en-US'), 
			t.depart_time_mam   = DATEDIFF(minute, DATETIME2FROMPARTS(DATEPART(year,t.depart_time_timestamp),DATEPART(month,t.depart_time_timestamp),DATEPART(day,t.depart_time_timestamp),0,0,0,0,0),t.depart_time_timestamp),
			t.arrival_time_mam  = DATEDIFF(minute, DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp), DATEPART(month,t.arrival_time_timestamp), DATEPART(day,t.arrival_time_timestamp),0,0,0,0,0),t.arrival_time_timestamp),
			t.daynum = 1 + DATEDIFF(day, cte.start_stamp, (CASE WHEN DATEPART(Hour, t.depart_time_timestamp) < 3 
																THEN CAST(DATEADD(Hour, -3, t.depart_time_timestamp) AS DATE)
																ELSE CAST(t.depart_time_timestamp AS DATE) END)),
			t.speed_mph			= CASE WHEN (t.trip_path_distance > 0 AND (CAST(DATEDIFF_BIG (second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/3600) > 0) 
										THEN  t.trip_path_distance / (CAST(DATEDIFF_BIG (second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/3600) 
										ELSE 0 END,
			t.reported_duration	= CAST(DATEDIFF(second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/60,
			--t.travel_time 	= CAST(DATEDIFF(second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/60,  -- for edited records, this should be the accepted travel duration			   	
			t.dayofweek 		= DATEPART(dw, DATEADD(hour, 3, t.depart_time_timestamp)),
			t.dest_geog = geography::STGeomFromText('POINT(' + CAST(t.dest_lng AS VARCHAR(20)) + ' ' + CAST(t.dest_lat AS VARCHAR(20)) + ')', 4326), 
			t.origin_geog  = geography::STGeomFromText('POINT(' + CAST(t.origin_lng AS VARCHAR(20)) + ' ' + CAST(t.origin_lat AS VARCHAR(20)) + ')', 4326) 
		FROM HHSurvey.Trip AS t JOIN cte ON t.personid = cte.personid
		WHERE t.personid = (CASE WHEN @target_personid IS NULL THEN t.personid ELSE @target_personid END);

		UPDATE next_t SET
			next_t.origin_purpose = t.dest_purpose
			FROM HHSurvey.Trip AS t JOIN HHSurvey.Trip AS next_t ON t.personid = next_t.personid AND t.tripnum + 1 = next_t.tripnum
			WHERE t.personid = (CASE WHEN @target_personid IS NULL THEN t.personid ELSE @target_personid END);

		END
		GO	

/* STEP 3.  Rule-based individual field revisions */

	--A. Revise travelers count to reflect passengers (lazy response?)
		WITH membercounts (tripid, membercount)
		AS (
			select tripid, count(member) 
			from (		  SELECT tripid, hhmember1 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember2 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember3 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember4 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember5 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember6 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember7 AS member FROM HHSurvey.Trip 
				union all SELECT tripid, hhmember8 AS member FROM HHSurvey.Trip 
			) AS members
			where member not in (select flag_value from HHSurvey.NullFlags)
			group by tripid
		)
		update t
		set t.travelers_hh = membercounts.membercount
		from membercounts
			join HHSurvey.Trip AS t ON t.tripid = membercounts.tripid
		where t.travelers_hh <> membercounts.membercount 
			or t.travelers_hh is null
			or t.travelers_hh in (select flag_value from HHSurvey.NullFlags);
		
		UPDATE t
			SET t.travelers_total = t.travelers_hh
			FROM HHSurvey.Trip AS t
			WHERE t.travelers_total < t.travelers_hh	
				or t.travelers_total in (select flag_value from HHSurvey.NullFlags);
	
	--B. Origin purpose assignment	

		 -- to 'home' (should be largest share of cases)
		UPDATE t
		SET 	t.origin_purpose   = 1,
				t.origin_geog = h.home_geog,
				t.origin_lat  = h.home_lat,
				t.origin_lng  = h.home_lng,
				t.origin_name = 'HOME'
		FROM HHSurvey.Trip AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.origin_purpose = vl.code
			WHERE t.tripnum = 1 
				AND (vl.label = 'Other purpose' OR vl.label like 'Missing%')
				AND t.origin_geog.STDistance(h.home_geog) < 300;

		 -- to 'work'
		UPDATE t
		SET 	t.origin_purpose   = 10,
				t.origin_geog = p.work_geog,
				t.origin_lat  = p.work_lat,
				t.origin_lng  = p.work_lng,
				t.origin_name = 'WORK'
		FROM HHSurvey.Trip AS t JOIN HHSurvey.Person AS p ON t.personid = p.personid
			JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.origin_purpose = vl.code
			WHERE t.tripnum = 1 
				AND (vl.label = 'Other purpose' OR vl.label like 'Missing%')
				AND t.origin_geog.STDistance(p.work_geog) < 300;

	--C. Destination purpose		

			-- parameterized procedure to reduce duplication
			DROP PROCEDURE IF EXISTS HHSurvey.destname_purpose_revision;
			GO

			CREATE PROCEDURE HHSurvey.destname_purpose_revision (@purpose int = NULL, @pattern nvarchar(50) = NULL)
			AS UPDATE t 
			SET t.dest_purpose = @purpose, t.revision_code = CONCAT(t.revision_code,'5,') 
				FROM HHSurvey.Trip AS t 
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE vl.label = 'Other purpose'
					AND Elmer.dbo.rgx_find(t.dest_name,@pattern,1) = 1;
			GO

		DROP PROCEDURE IF EXISTS HHSurvey.dest_purpose_updates;
		GO
		CREATE PROCEDURE HHSurvey.dest_purpose_updates AS 
		BEGIN
			
			UPDATE t--Classify home destinations; criteria plus 300m proximity to household home location
				SET t.dest_is_home = 1
				FROM HHSurvey.Trip AS t JOIN HHSurvey.household AS h ON t.hhid = h.hhid
				WHERE t.dest_is_home IS NULL AND
					(t.dest_name = 'HOME' 
					OR(
						(Elmer.dbo.rgx_find(t.dest_name,' home',1) = 1 
						OR Elmer.dbo.rgx_find(t.dest_name,'^h[om]?$',1) = 1) 
						and Elmer.dbo.rgx_find(t.dest_name,'(their|her|s|from|near|nursing|friend) home',1) = 0
					)
					OR(t.dest_purpose = 1))
					AND t.dest_geog.STDistance(h.home_geog) < 300;

			UPDATE t --Classify home destinations where destination code is absent; 50m proximity to home location on file
				SET t.dest_is_home = 1, t.dest_purpose = 1
				FROM HHSurvey.Trip AS t JOIN HHSurvey.household AS h ON t.hhid = h.hhid
						  LEFT JOIN HHSurvey.Trip AS prior_t ON t.personid = prior_t.personid AND t.tripnum - 1 = prior_t.tripnum
						  JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE t.dest_is_home IS NULL 
					AND ((vl.label like 'Missing%' OR t.dest_purpose = prior_t.dest_purpose) OR t.dest_purpose = 97) AND t.dest_geog.STDistance(h.home_geog) < 50;

			UPDATE t --Classify primary work destinations
				SET t.dest_is_work = 1
				FROM HHSurvey.Trip AS t JOIN HHSurvey.person AS p ON t.personid = p.personid AND p.worker > 1
				WHERE t.dest_is_work IS NULL AND
					(t.dest_name = 'WORK' 
					OR((Elmer.dbo.rgx_find(t.dest_name,' work',1) = 1 
						OR Elmer.dbo.rgx_find(t.dest_name,'^w[or ]?$',1) = 1))
					OR(t.dest_purpose = 10 AND t.dest_name IS NULL))
					AND t.dest_geog.STDistance(p.work_geog) < 300;

			UPDATE t --Classify work destinations where destination code is absent; 50m proximity to work location on file
				SET t.dest_is_work = 1, t.dest_purpose = 10
				FROM HHSurvey.Trip AS t JOIN HHSurvey.person AS p ON t.personid  = p.personid AND p.worker > 1
					JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
					 LEFT JOIN HHSurvey.Trip AS prior_t ON t.personid = prior_t.personid AND t.tripnum - 1 = prior_t.tripnum
				WHERE t.dest_is_work IS NULL 
					AND ((vl.label like 'Missing%' OR t.dest_purpose = prior_t.dest_purpose) OR t.dest_purpose = 97) 
					AND t.dest_geog.STDistance(p.work_geog) < 50;		
					
			UPDATE t --revises purpose field for return portion of a single stop loop trip 
				SET t.dest_purpose = (CASE WHEN t.dest_is_home = 1 THEN 1 WHEN t.dest_is_work = 1 THEN 10 ELSE t.dest_purpose END), t.revision_code = CONCAT(t.revision_code,'1,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.Trip AS prev_t on t.personid=prev_t.personid AND t.tripnum - 1 = prev_t.tripnum
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE ((vl.label <> 'Went home' and t.dest_is_home = 1) 
					OR (vl.label <> 'Went to primary workplace' and t.dest_is_work = 1))
					AND t.dest_purpose=prev_t.dest_purpose

			UPDATE t --revises purpose field for home return portion of a single stop loop trip 
				SET t.dest_purpose = 1, t.revision_code = CONCAT(t.revision_code,'1,') 
				FROM HHSurvey.Trip AS t
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE vl.label <> 'Went home'
					AND t.dest_is_home = 1 
					AND t.origin_name <> 'HOME';					

			UPDATE t --Change code to pickup/dropoff when passenger number changes and duration is under 30 minutes
					SET t.dest_purpose = 9, t.revision_code = CONCAT(t.revision_code,'2,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.person AS p ON t.personid=p.personid 
					JOIN HHSurvey.Trip AS next_t ON t.personid=next_t.personid	AND t.tripnum + 1 = next_t.tripnum						
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE p.age > 4 
					AND (p.student = 1 OR p.student IS NULL or p.student in (select distinct [flag_value] from HHSurvey.NullFlags)) 
					and (vl.label like 'Went to school/daycare%'
						or vl.label = 'Other purpose'
						or vl.label like 'Missing%'
						)
					AND t.travelers_total <> next_t.travelers_total
					AND DATEDIFF(minute, t.arrival_time_timestamp, next_t.depart_time_timestamp) < 30;

			UPDATE t --Change code to pickup/dropoff when passenger number changes and duration is under 30 minutes
				SET t.dest_purpose = 9, t.revision_code = CONCAT(t.revision_code,'2,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.person AS p ON t.personid=p.personid 
					JOIN HHSurvey.Trip AS next_t ON t.personid=next_t.personid	AND t.tripnum + 1 = next_t.tripnum						
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE (p.age < 4 OR p.worker = 0) 
					and vl.label in ('Went to primary workplace', 
									'Went to work-related place (e.g., meeting, second job, delivery)',
									'Went to other work-related activity'
					)
					AND t.travelers_total <> next_t.travelers_total
					AND DATEDIFF(minute, t.arrival_time_timestamp, next_t.depart_time_timestamp) < 30;					

			UPDATE t --Change code to pickup/dropoff when pickup/dropoff mentioned
				SET t.dest_purpose = 9, t.revision_code = CONCAT(t.revision_code,'2,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.person AS p ON t.personid=p.personid 				
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE p.age > 4 
					AND (p.student = 1 OR p.student IS NULL or p.student in (select distinct [flag_value] from HHSurvey.NullFlags))
					AND t.dest_purpose IN(-9998,6,97)
					and (vl.label like 'Went to school/daycare%'
						or vl.label = 'Other purpose'
						or vl.label like 'Missing%'
					)
					AND Elmer.dbo.rgx_find(t.dest_name,'(pick|drop)',1) = 1;
			
			UPDATE t --changes code to 'family activity' when adult is present, multiple people involved and duration is from 30mins to 4hrs
				SET t.dest_purpose = 56, t.revision_code = CONCAT(t.revision_code,'3,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.person AS p ON t.personid=p.personid 
					LEFT JOIN HHSurvey.Trip as next_t ON t.personid=next_t.personid AND t.tripnum + 1 = next_t.tripnum
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE p.age > 4 
					AND (p.student = 1 OR p.student IS NULL or p.student in (select distinct [flag_value] from HHSurvey.NullFlags))
					AND (t.travelers_total > 1 OR next_t.travelers_total > 1)
					AND ( vl.label like 'Went to school/daycare%'
						OR Elmer.dbo.rgx_find(t.dest_name,'(school|care)',1) = 1
					)
					AND DATEDIFF(Minute, t.arrival_time_timestamp, next_t.depart_time_timestamp) Between 30 and 240;

			UPDATE t --updates empty purpose code to 'school' when single student traveler with school destination and duration > 30 minutes.
				SET t.dest_purpose = 6, t.revision_code = CONCAT(t.revision_code,'4,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.Trip as next_t ON t.hhid=next_t.hhid AND t.personid=next_t.personid AND t.tripnum + 1 = next_t.tripnum
					JOIN HHSurvey.person AS p ON t.personid = p.personid
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
					join HHSurvey.fnVariableLookup('student') as vls ON p.student = vls.code
				WHERE vl.label = 'Other purpose'
					AND t.dest_name = 'school'
					AND t.travelers_total = 1
					--AND p.student IN(2,3,4) -- There is no student=4 in the 2019 codebook.
					and vls.label in ('Part-time student', 'full-time student')
					AND DATEDIFF(Minute, t.arrival_time_timestamp, next_t.depart_time_timestamp) > 30;

			UPDATE t --Change purpose from 'school' to 'personal business' for non-students taking a course for interest
				SET t.dest_purpose = 33, t.revision_code = CONCAT(t.revision_code,'4,')
				FROM HHSurvey.Trip AS t
					JOIN HHSurvey.person AS p ON t.personid=p.personid 				
					join HHSurvey.fnVariableLookup('student') as vls ON p.student = vls.code
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE p.age > 4 
					AND (vls.label like '% not a student' OR p.student IS NULL or p.student in (select distinct [flag_value] from HHSurvey.NullFlags))
					and (vl.label like 'Went to school/daycare%'
						or vl.label = 'Other purpose'
						or vl.label like 'Missing%'
					)
					AND t.travelers_hh = 1
					AND Elmer.dbo.rgx_find(t.dest_name,'(pick|drop|kid|child)',1) = 0 
					AND Elmer.dbo.rgx_find(t.dest_name,'(class|lesson)',1) = 1;							

		--Change 'Other' trip purpose when purpose is given in destination
			UPDATE t  
				SET t.dest_purpose = 1,  t.revision_code = CONCAT(t.revision_code,'5,') 
				FROM HHSurvey.Trip AS t 
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE ( vl.label like 'Missing%'
						or vl.label = 'Other purpose'
						)
					AND t.dest_is_home = 1;

			UPDATE t  
				SET t.dest_purpose = 10, t.revision_code = CONCAT(t.revision_code,'5,') 
				FROM HHSurvey.Trip AS t 
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE ( vl.label like 'Missing%'
						or vl.label = 'Other purpose'
						)
					AND t.dest_is_work = 1;

			UPDATE t  
				SET t.dest_purpose = 11, t.revision_code = CONCAT(t.revision_code,'5,') 
				FROM HHSurvey.Trip AS t 
					join HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE vl.label = 'Other purpose'
					AND t.dest_is_work IS NULL
					AND t.dest_name = 'WORK';

			EXECUTE HHSurvey.destname_purpose_revision @purpose = 30, @pattern = '(grocery|costco|safeway|trader ?joe)';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 32, @pattern = '\b(store)\b';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 33, @pattern = '\b(bank|gas|post ?office|library|barber|hair)\b';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 34, @pattern = '(doctor|dentist|hospital|medical|health)';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 50, @pattern = '(coffee|cafe|starbucks|lunch)';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 51, @pattern = 'dog.*(walk|park)';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 51, @pattern = '(walk|park).*dog';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 51, @pattern = '\bwalk$';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 51, @pattern = '\bgym$';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 53, @pattern = 'casino';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 54, @pattern = '(church|volunteer)';
			EXECUTE HHSurvey.destname_purpose_revision @purpose = 60, @pattern = '\b(bus|transit|ferry|airport|station)\b';

			UPDATE t
			SET t.origin_purpose = t_prev.dest_purpose
			FROM HHSurvey.Trip AS t 
				JOIN HHSurvey.Trip AS t_prev ON t.personid = t_prev.personid AND t.tripnum -1 = t_prev.tripnum 
			WHERE t.origin_purpose <> t_prev.dest_purpose 
				AND t.tripnum > 1
				AND t_prev.dest_purpose > 0;

		--if traveling with another hhmember, take missing purpose from the most adult member with whom they traveled
		WITH cte AS
			(SELECT myself.recid AS self_recid, family.personid AS referent, family.recid AS referent_recid
			 FROM HHSurvey.Trip AS myself 
				 JOIN HHSurvey.Trip AS family ON myself.hhid=family.hhid AND myself.pernum <> family.pernum 
			 WHERE EXISTS (
					SELECT 1 
					FROM (VALUES (family.hhmember1),(family.hhmember2),(family.hhmember3),
							(family.hhmember4),(family.hhmember5),(family.hhmember6),
							(family.hhmember7),(family.hhmember8),(family.hhmember9),(family.hhmember10),(family.hhmember11)
						) AS hhmem(member) 
					WHERE myself.personid IN (member)
				)
		    AND (myself.depart_time_timestamp BETWEEN DATEADD(Minute, -5, family.depart_time_timestamp) AND DATEADD(Minute, 5, family.arrival_time_timestamp))
		    AND (myself.arrival_time_timestamp BETWEEN DATEADD(Minute, -5, family.depart_time_timestamp) AND DATEADD(Minute, 5, family.arrival_time_timestamp))
			AND myself.dest_purpose = -9998 
			AND myself.mode_1 = -9998 
			AND family.dest_purpose <> -9998 
			AND family.mode_1 <> -9998
			)
		UPDATE t
			SET t.dest_purpose = ref_t.dest_purpose, 
				t.mode_1 	   = ref_t.mode_1,
				t.revision_code = CONCAT(t.revision_code,'6,')		
			FROM HHSurvey.Trip AS t 
				JOIN cte ON t.recid = cte.self_recid 
				JOIN HHSurvey.Trip AS ref_t ON cte.referent_recid = ref_t.recid AND cte.referent = ref_t.personid
			WHERE t.dest_purpose = -9998 AND t.mode_1 = -9998;

		--if the same person has been to the purpose-missing location at other times and provided a consistent purpose for those trips, use it again
		WITH cte AS (SELECT t1.personid, t1.recid, t2.dest_purpose 
						FROM HHSurvey.Trip AS t1 JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t1.dest_purpose = vl.code AND (vl.label LIKE 'Missing%' OR vl.label='Other purpose')
						JOIN HHSurvey.Trip AS t2 ON t1.personid = t2.personid JOIN HHSurvey.fnVariableLookup('dest_purpose') as v2 ON t2.dest_purpose = v2.code AND v2.label NOT LIKE 'Missing%' AND vl.label<>'Other purpose'
						WHERE t1.dest_geog.STDistance(t2.dest_geog) < 50
						GROUP BY t1.personid, t1.recid, t2.dest_purpose),
			cte_filter AS (SELECT cte.personid, cte.recid, count(*) AS instances FROM cte GROUP BY cte.personid, cte.recid HAVING count(*) = 1)
		UPDATE t 
			SET t.dest_purpose = cte.dest_purpose,
				t.revision_code = CONCAT(t.revision_code,'5b,') 
			FROM HHSurvey.Trip AS t JOIN cte ON t.recid = cte.recid JOIN cte_filter ON t.recid = cte_filter.recid;

		--if anyone has been to the purpose-missing location at other times and all visitors provided a consistent purpose for those trips, use it again
		WITH cte AS (SELECT t1.recid, t2.dest_purpose 
						FROM HHSurvey.Trip AS t1 JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t1.dest_purpose = vl.code AND (vl.label LIKE 'Missing%' OR vl.label='Other purpose')
						JOIN HHSurvey.Trip AS t2 ON t1.dest_geog.STDistance(t2.dest_geog) < 50 JOIN HHSurvey.fnVariableLookup('dest_purpose') as v2 ON t2.dest_purpose = v2.code AND v2.label NOT LIKE 'Missing%' AND vl.label<>'Other purpose'
						WHERE t2.dest_purpose NOT IN (1,10) 
						GROUP BY t1.recid, t2.dest_purpose),
			cte_filter AS (SELECT cte.recid, count(*) AS instances FROM cte GROUP BY cte.recid HAVING count(*) = 1)
		UPDATE t 
			SET t.dest_purpose = cte.dest_purpose,
				t.revision_code = CONCAT(t.revision_code,'5c,') 
			FROM HHSurvey.Trip AS t JOIN cte ON t.recid = cte.recid JOIN cte_filter ON t.recid = cte_filter.recid
			WHERE cte.dest_purpose IN(30,32,33,34,50,51,52,53,54,61,62);

		END
		GO
		EXECUTE HHSurvey.dest_purpose_updates;

	/* Placeholder for imputing missing purpose via the Elmer.dbo.loc_recognize function; relevant primarily for rMove */

	--D. impute mode (if not specified) for cases on the spectrum ends of speed + distance: 
		-- slow, short trips are walk; long, fast trips are airplane.  Other modes can't be easily assumed.
		UPDATE t 
		SET t.mode_1 = 31, t.revision_code = CONCAT(t.revision_code,'7,')	
		FROM HHSurvey.Trip AS t 
		WHERE (t.mode_1 IS NULL or t.mode_1 in (select flag_value from HHSurvey.NullFlags)) 
			AND t.trip_path_distance > 200 
			AND t.speed_mph between 200 and 600;

		UPDATE t 
		SET t.mode_1 = 1,  t.revision_code = CONCAT(t.revision_code,'7,') 	
		FROM HHSurvey.Trip AS t 
		WHERE (t.mode_1 IS NULL or t.mode_1 in (select flag_value from HHSurvey.NullFlags)) 
			AND t.trip_path_distance < 0.6 
			AND t.speed_mph < 5;
		
/* STEP 4.	Trip linking */

	-- Populate consolidated modes, transit_sytems, and transit_lines fields, used later

		/*	These are MSSQL17 commands for the UPDATE query below--faster and clearer, once we upgrade.
		UPDATE trip
			SET modes 			= CONCAT_WS(',',ti_wndw.mode_acc, ti_wndw.mode_1, ti_wndw.mode_2, ti_wndw.mode_3, ti_wndw.mode_4, ti_wndw.mode_5, ti_wndw.mode_egr),
				transit_systems = CONCAT_WS(',',ti_wndw.transit_system_1, ti_wndw.transit_system_2, ti_wndw.transit_system_3, ti_wndw.transit_system_4, ti_wndw.transit_system_5, ti_wndw.transit_system_6),
				transit_lines 	= CONCAT_WS(',',ti_wndw.transit_line_1, ti_wndw.transit_line_2, ti_wndw.transit_line_3, ti_wndw.transit_line_4, ti_wndw.transit_line_5, ti_wndw.transit_line_6)
		*/
		UPDATE HHSurvey.Trip
				SET modes = STUFF(	COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.mode_acc) 		  THEN trip.mode_acc 		 ELSE NULL END AS nvarchar), '') +
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.mode_1)		 	  THEN trip.mode_1 			 ELSE NULL END AS nvarchar), '') + 
				/*					COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.mode_2)			  THEN trip.mode_2 			 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.mode_3) 		  THEN trip.mode_3 			 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.mode_4) 		  THEN trip.mode_4 			 ELSE NULL END AS nvarchar), '') + 
				*/					COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.mode_egr) 		  THEN trip.mode_egr		 ELSE NULL END AS nvarchar), ''), 1, 1, '')/*,
		  transit_systems = STUFF(	COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_system_1) THEN trip.transit_system_1 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_system_2) THEN trip.transit_system_2 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_system_3) THEN trip.transit_system_3 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_system_4) THEN trip.transit_system_4 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_system_5) THEN trip.transit_system_5 ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_system_6) THEN trip.transit_system_6 ELSE NULL END AS nvarchar), ''), 1, 1, ''),
			transit_lines = STUFF(	COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_line_1)	  THEN trip.transit_line_1   ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_line_2)   THEN trip.transit_line_2   ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_line_3)   THEN trip.transit_line_3   ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_line_4)   THEN trip.transit_line_4   ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_line_5)   THEN trip.transit_line_5   ELSE NULL END AS nvarchar), '') + 
									COALESCE(',' + CAST(CASE WHEN NOT EXISTS (SELECT 1 FROM HHSurvey.NullFlags AS nf WHERE nf.flag_value = trip.transit_line_6)   THEN trip.transit_line_6   ELSE NULL END AS nvarchar), ''), 1, 1, '')*/;							
		
		-- remove component records into separate table, starting w/ 2nd component (i.e., first is left in trip table).  The criteria here determine which get considered components.
		DROP TABLE IF EXISTS HHSurvey.trip_ingredients_done;
		GO
		SELECT TOP 0 HHSurvey.Trip.*, CAST(0 AS int) AS trip_link 
			INTO HHSurvey.trip_ingredients_done 
			FROM HHSurvey.Trip
		union all -- This union is done simply for the side effect of preventing the recid in the new table to be defined as an IDENTITY column.
		SELECT TOP 0 HHSurvey.Trip.*, CAST(0 AS int) AS trip_link 
			FROM HHSurvey.Trip
		GO

		--select the trip ingredients that will be linked; this selects all but the first component 
		DROP TABLE IF EXISTS #trip_ingredient;
		GO
		SELECT next_trip.*, CAST(0 AS int) AS trip_link INTO #trip_ingredient
		FROM HHSurvey.Trip as trip 
			JOIN HHSurvey.fnVariableLookup('dest_purpose') as tvl ON trip.dest_purpose = tvl.code
			JOIN HHSurvey.Trip AS next_trip ON trip.personid=next_trip.personid AND trip.tripnum + 1 = next_trip.tripnum
			JOIN HHSurvey.fnVariableLookup('dest_purpose') as ntvl ON next_trip.dest_purpose = ntvl.code
		WHERE 	trip.dest_is_home IS NULL 																			-- destination of preceding leg isn't home
			AND trip.dest_is_work IS NULL																			-- destination of preceding leg isn't work
			AND trip.travelers_total = next_trip.travelers_total	 												-- traveler # the same								
			AND (trip.mode_1<>next_trip.mode_1 
				OR (trip.mode_1 = next_trip.mode_1 AND EXISTS (SELECT trip.mode_1 FROM HHSurvey.transitmodes)))		--either change modes or switch transit lines
			AND ((tvl.label LIKE 'Transferred to another mode of transporation%' AND DATEDIFF(Minute, trip.arrival_time_timestamp, next_trip.depart_time_timestamp) < 30) -- change modes under 30min dwell
				  OR (trip.dest_purpose = next_trip.dest_purpose AND ntvl.label NOT LIKE 'Dropped off/picked up someone%' AND DATEDIFF(Minute, trip.arrival_time_timestamp, next_trip.depart_time_timestamp) < 15)  -- other non-PUDO purposes if identical, under 15min dwell
				);

		/* Less restricted linkages for 'mode change' only 
		SELECT next_trip.*, CAST(0 AS int) AS trip_link INTO #trip_ingredient  
			FROM HHSurvey.Trip as trip  
			JOIN HHSurvey.Trip AS next_trip ON trip.personid=next_trip.personid AND trip.tripnum + 1 = next_trip.tripnum  
		WHERE trip.dest_is_home IS NULL 
			AND trip.dest_is_work IS NULL 
			AND trip.dest_purpose = 60
			AND DATEDIFF(Minute, trip.arrival_time_timestamp, next_trip.depart_time_timestamp) < 30;*/

		-- set the trip_link value of the 2nd component to the tripnum of the 1st component.
		UPDATE ti  
			SET ti.trip_link = (ti.tripnum - 1)
			FROM #trip_ingredient AS ti 
				LEFT JOIN #trip_ingredient AS previous_et ON ti.personid = previous_et.personid AND (ti.tripnum - 1) = previous_et.tripnum
			WHERE (CONCAT(ti.personid, (ti.tripnum - 1)) <> CONCAT(previous_et.personid, previous_et.tripnum));
		
		-- assign trip_link value to remaining records in the trip.
		WITH cte (recid, ref_link) AS 
		(SELECT ti1.recid, MAX(ti1.trip_link) OVER(PARTITION BY ti1.personid ORDER BY ti1.tripnum ROWS UNBOUNDED PRECEDING) AS ref_link
			FROM #trip_ingredient AS ti1)
		UPDATE ti
			SET ti.trip_link = cte.ref_link
			FROM #trip_ingredient AS ti JOIN cte ON ti.recid = cte.recid
			WHERE ti.trip_link = 0;	

		-- add the 1st component without deleting it from the trip table.
		INSERT INTO #trip_ingredient
			SELECT t.*, t.tripnum AS trip_link 
			FROM HHSurvey.Trip AS t 
				JOIN #trip_ingredient AS ti ON t.personid = ti.personid AND t.tripnum = ti.trip_link AND t.tripnum = ti.tripnum - 1;

	/*	-- remove parking flag in cases where it is carried over among trip components, with no dwell time or mode change
		UPDATE ti 
		SET ti.park = -9997, ti.park_type = -9997
		FROM #trip_ingredient AS ti JOIN #trip_ingredient AS ti_prior ON ti.personid = ti_prior.personid AND ti.tripnum - 1 = ti_prior.tripnum AND ti.trip_link = ti_prior.trip_link
		WHERE ti.park BETWEEN 1 AND 6															
			AND DATEDIFF(SECOND, ti_prior.arrival_time_timestamp, ti.depart_time_timestamp) < 60	
			AND ti.modes = ti_prior.modes;
	*/
		-- denote trips with too many components or other attributes suggesting multiple trips, for later examination.  
		WITH /*cte_a AS										--non-adjacent repeated transit line, i.e. suggests a loop trip
			(SELECT DISTINCT ti_wndw1.personid, ti_wndw1.trip_link, Elmer.dbo.TRIM(Elmer.dbo.rgx_replace(
				STUFF((SELECT ',' + ti1.transit_lines
					FROM #trip_ingredient AS ti1 
					WHERE ti1.personid = ti_wndw1.personid AND ti1.trip_link = ti_wndw1.trip_link
					GROUP BY ti1.transit_lines
					ORDER BY ti_wndw1.personid DESC, ti_wndw1.tripnum DESC
					FOR XML PATH('')), 1, 1, NULL),'(\b\d+\b),(?=\1)','',1)) AS transit_lines	
				FROM #trip_ingredient as ti_wndw1 WHERE ti_wndw1.transit_lines IS NOT NULL),*/
		cte_b AS 
			(SELECT DISTINCT ti_wndw2.personid, ti_wndw2.trip_link, Elmer.dbo.TRIM(Elmer.dbo.rgx_replace(
				STUFF((SELECT ',' + ti2.modes				--non-adjacent repeated modes, i.e. suggests a loop trip
					FROM #trip_ingredient AS ti2
					WHERE ti2.personid = ti_wndw2.personid AND ti2.trip_link = ti_wndw2.trip_link
					GROUP BY ti2.modes
					ORDER BY ti_wndw2.personid DESC, ti_wndw2.tripnum DESC
					FOR XML PATH('')), 1, 1, NULL),'(\b\d+\b),(?=\1)','',1)) AS modes	
				FROM #trip_ingredient as ti_wndw2),
		cte2 AS 
			(SELECT ti3.personid, ti3.trip_link 			--sets with more than 4 trip components
				FROM #trip_ingredient as ti3 GROUP BY ti3.personid, ti3.trip_link
				HAVING count(*) > 4
	/*		UNION ALL SELECT ti4.personid, ti4.trip_link --sets with two items that each denote a separate trip
				FROM #trip_ingredient as ti4 GROUP BY ti4.personid, ti4.trip_link
				HAVING sum(CASE WHEN ti4.pool_start 		  = 1 				THEN 1 ELSE 0 END) > 1
					OR sum(CASE WHEN ti4.change_vehicles 	  = 1 				THEN 1 ELSE 0 END) > 1
					OR sum(CASE WHEN ti4.park_ride_area_start BETWEEN 1 AND 899 THEN 1 ELSE 0 END) > 1
					OR sum(CASE WHEN ti4.park_ride_area_end   BETWEEN 1 AND 899 THEN 1 ELSE 0 END) > 1
					OR sum(CASE WHEN ti4.park_ride_lot_start  BETWEEN 1 AND 899 THEN 1 ELSE 0 END) > 1
					OR sum(CASE WHEN ti4.park_ride_lot_end 	  BETWEEN 1 AND 899 THEN 1 ELSE 0 END) > 1
					OR sum(CASE WHEN ti4.park	 			  BETWEEN 1 AND 6 	THEN 1 ELSE 0 END) > 1
			UNION ALL SELECT cte_a.personid, cte_a.trip_link 	--sets with nonadjacent repeating transit lines (i.e., return trip)
				FROM cte_a
				WHERE Elmer.dbo.rgx_find(cte_a.transit_lines,'(\b\d+\b),.+(?=\1)',1)=1	
	*/		UNION ALL SELECT cte_b.personid, cte_b.trip_link 	--sets with a pair of modes repeating in reverse (i.e., return trip)
				FROM cte_b
				WHERE Elmer.dbo.rgx_find(cte_b.modes,'\b(\d+),(\d+)\b,.+(?=\2,\1)',1)=1)
		UPDATE ti
			SET ti.trip_link = -1 * ti.trip_link
			FROM #trip_ingredient AS ti JOIN cte2 ON cte2.personid = ti.personid AND cte2.trip_link = ti.trip_link;

		--SELECT CASE WHEN trip_link > 1 THEN 'queued' ELSE 'removed' END, count(*) FROM #trip_ingredient GROUP BY CASE WHEN trip_link > 1 THEN 'queued' ELSE 'removed' END


		DROP PROCEDURE IF EXISTS HHSurvey.link_trips;
		GO
		CREATE PROCEDURE HHSurvey.link_trips AS
		BEGIN

		-- meld the trip ingredients to create the fields that will populate the linked trip, and saves those as a separate table, 'linked_trip'.

		WITH cte_agg AS
		(SELECT ti_agg.personid,
				ti_agg.trip_link,
				CAST(MAX(ti_agg.arrival_time_timestamp) AS [datetime2]) AS arrival_time_timestamp,	
				SUM((CASE WHEN ti_agg.google_duration 		IN (-9998,-9999,995) THEN 0 ELSE 1 END) * ti_agg.google_duration 		 ) AS google_duration, 
				SUM((CASE WHEN ti_agg.trip_path_distance 	IN (-9998,-9999,995) THEN 0 ELSE 1 END) * ti_agg.trip_path_distance 	 ) AS trip_path_distance, 	
				MAX((CASE WHEN ti_agg.hhmember1 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember1 			 ) AS hhmember1, 		
				MAX((CASE WHEN ti_agg.hhmember2 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember2 			 ) AS hhmember2,
				MAX((CASE WHEN ti_agg.hhmember3 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember3 			 ) AS hhmember3, 
				MAX((CASE WHEN ti_agg.hhmember4 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember4 			 ) AS hhmember4, 
				MAX((CASE WHEN ti_agg.hhmember5 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember5 			 ) AS hhmember5, 
				MAX((CASE WHEN ti_agg.hhmember6 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember6 			 ) AS hhmember6,
				MAX((CASE WHEN ti_agg.hhmember7 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember7 			 ) AS hhmember7, 
				MAX((CASE WHEN ti_agg.hhmember8 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember8 			 ) AS hhmember8, 
				MAX((CASE WHEN ti_agg.hhmember9 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember9 			 ) AS hhmember9, 
				MAX((CASE WHEN ti_agg.hhmember10 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember10 			 ) AS hhmember10, 
				MAX((CASE WHEN ti_agg.hhmember11 			IN (995) THEN -1 ELSE 1 END) * ti_agg.hhmember11 			 ) AS hhmember11, 
				MAX((CASE WHEN ti_agg.travelers_hh 			IN (995) THEN -1 ELSE 1 END) * ti_agg.travelers_hh 			 ) AS travelers_hh, 				
				MAX((CASE WHEN ti_agg.travelers_nonhh 		IN (995) THEN -1 ELSE 1 END) * ti_agg.travelers_nonhh 		 ) AS travelers_nonhh,				
				MAX((CASE WHEN ti_agg.travelers_total 		IN (995) THEN -1 ELSE 1 END) * ti_agg.travelers_total 		 ) AS travelers_total,				
				MAX((CASE WHEN ti_agg.pool_start 			IN (995) THEN -1 ELSE 1 END) * ti_agg.pool_start 			 ) AS pool_start,					
				MAX((CASE WHEN ti_agg.change_vehicles 		IN (995) THEN -1 ELSE 1 END) * ti_agg.change_vehicles 		 ) AS change_vehicles,	
				MAX((CASE WHEN ti_agg.toll 					IN (995) THEN -1 ELSE 1 END) * ti_agg.toll 					 ) AS toll, 							
		/*		MAX((CASE WHEN ti_agg.park 					IN (995) THEN -1 ELSE 1 END) * ti_agg.park 			 		 ) AS park,
				MAX((CASE WHEN ti_agg.park_type 			IN (995) THEN -1 ELSE 1 END) * ti_agg.park_type  			 ) AS park_type,
				MAX((CASE WHEN ti_agg.taxi_type 			IN (995) THEN -1 ELSE 1 END) * ti_agg.taxi_type 			 ) AS taxi_type, 				
				MAX((CASE WHEN ti_agg.bus_type 				IN (995) THEN -1 ELSE 1 END) * ti_agg.bus_type 				 ) AS bus_type, 
				MAX((CASE WHEN ti_agg.ferry_type 			IN (995) THEN -1 ELSE 1 END) * ti_agg.ferry_type 			 ) AS ferry_type,
				MAX((CASE WHEN ti_agg.park_ride_area_start 	IN (995) THEN -1 ELSE 1 END) * ti_agg.park_ride_area_start 	 ) AS park_ride_area_start, 		
				MAX((CASE WHEN ti_agg.park_ride_area_end 	IN (995) THEN -1 ELSE 1 END) * ti_agg.park_ride_area_end 	 ) AS park_ride_area_end, 			
				MAX((CASE WHEN ti_agg.park_ride_lot_start 	IN (995) THEN -1 ELSE 1 END) * ti_agg.park_ride_lot_start 	 ) AS park_ride_lot_start, 		
				MAX((CASE WHEN ti_agg.park_ride_lot_end 	IN (995) THEN -1 ELSE 1 END) * ti_agg.park_ride_lot_end 	 ) AS park_ride_lot_end, 			
				MAX((CASE WHEN ti_agg.bus_cost_dk 			IN (995) THEN -1 ELSE 1 END) * ti_agg.bus_cost_dk 			 ) AS bus_cost_dk, 				
 				MAX((CASE WHEN ti_agg.ferry_cost_dk 		IN (995) THEN -1 ELSE 1 END) * ti_agg.ferry_cost_dk 		 ) AS ferry_cost_dk,				
				MAX((CASE WHEN ti_agg.air_type 				IN (995) THEN -1 ELSE 1 END) * ti_agg.air_type 				 ) AS air_type,	
				MAX((CASE WHEN ti_agg.airfare_cost_dk 		IN (995) THEN -1 ELSE 1 END) * ti_agg.airfare_cost_dk 		 ) AS airfare_cost_dk
				MAX((CASE WHEN ti_agg.bus_pay				IN (995) THEN -1 ELSE 1 END) * ti_agg.bus_pay		 		 ) AS bus_pay,
				MAX((CASE WHEN ti_agg.ferry_pay				IN (995) THEN -1 ELSE 1 END) * ti_agg.ferry_pay				 ) AS ferry_pay, 
				MAX((CASE WHEN ti_agg.air_pay				IN (995) THEN -1 ELSE 1 END) * ti_agg.air_pay				 ) AS air_pay, 
				MAX((CASE WHEN ti_agg.park_pay 				IN (995) THEN -1 ELSE 1 END) * ti_agg.park_pay 				 ) AS park_pay,
			*/	MAX((CASE WHEN ti_agg.toll_pay 		IN (995) THEN -1 ELSE 1 END) * ti_agg.toll_pay 		 				 ) AS toll_pay,
			    MAX((CASE WHEN ti_agg.taxi_pay		IN (995) THEN -1 ELSE 1 END) * ti_agg.taxi_pay		 				 ) AS taxi_pay
			FROM #trip_ingredient as ti_agg WHERE ti_agg.trip_link > 0 GROUP BY ti_agg.personid, ti_agg.trip_link),
		cte_wndw AS	
		(SELECT 
				ti_wndw.personid AS personid2,
				ti_wndw.trip_link AS trip_link2,
				FIRST_VALUE(ti_wndw.dest_name) 		OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS dest_name,
				FIRST_VALUE(ti_wndw.dest_purpose) 	OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS dest_purpose,
				FIRST_VALUE(ti_wndw.origin_purpose) OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum ASC) AS origin_purpose,
				FIRST_VALUE(ti_wndw.dest_is_home) 	OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS dest_is_home,
				FIRST_VALUE(ti_wndw.dest_is_work) 	OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS dest_is_work,
				FIRST_VALUE(ti_wndw.dest_lat) 		OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS dest_lat,
				FIRST_VALUE(ti_wndw.dest_lng) 		OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS dest_lng,
				FIRST_VALUE(ti_wndw.mode_acc) 		OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum ASC)  AS mode_acc,
				FIRST_VALUE(ti_wndw.mode_egr) 		OVER (PARTITION BY CONCAT(ti_wndw.personid,ti_wndw.trip_link) ORDER BY ti_wndw.tripnum DESC) AS mode_egr,
				--STRING_AGG(ti_wnd.modes,',') 		OVER (PARTITION BY ti_wnd.trip_link ORDER BY ti_wndw.tripnum ASC) AS modes, -- This can be used once we upgrade from MSSQL16
				STUFF(
					(SELECT ',' + ti1.modes
					FROM #trip_ingredient AS ti1 
					WHERE ti1.personid = ti_wndw.personid AND ti1.trip_link = ti_wndw.trip_link
					GROUP BY ti1.modes
					ORDER BY ti_wndw.personid DESC, ti_wndw.tripnum DESC
					FOR XML PATH('')), 1, 1, NULL) AS modes/*,	
				--STRING_AGG(ti2.transit_systems,',') OVER (PARTITION BY ti_wnd.trip_link ORDER BY ti_wndw.tripnum ASC) AS transit_systems, -- This can be used once we upgrade from MSSQL16
				STUFF(
					(SELECT ',' + ti2.transit_systems
					FROM #trip_ingredient AS ti2
					WHERE ti2.personid = ti_wndw.personid AND ti2.trip_link = ti_wndw.trip_link
					GROUP BY ti2.transit_systems
					ORDER BY ti_wndw.personid DESC, ti_wndw.tripnum DESC
					FOR XML PATH('')), 1, 1, NULL) AS transit_systems,				
				--STRING_AGG(ti_wnd.transit_lines,',') OVER (PARTITION BY trip_link ORDER BY ti_wndw.tripnum ASC) AS transit_lines	-- This can be used once we upgrade from MSSQL16
				STUFF(
					(SELECT ',' + ti3.transit_lines
					FROM #trip_ingredient AS ti3 JOIN HHSurvey.Trip AS t ON ti3.personid = t.personid AND ti3.trip_link = t.tripnum
					WHERE ti3.personid = ti_wndw.personid AND ti3.trip_link = ti_wndw.trip_link
					GROUP BY ti3.transit_lines
					ORDER BY ti_wndw.personid DESC, ti_wndw.tripnum DESC
					FOR XML PATH('')), 1, 1, NULL) AS transit_lines	*/
			FROM #trip_ingredient as ti_wndw WHERE ti_wndw.trip_link > 0 )
		SELECT cte_wndw.*, cte_agg.* INTO #linked_trips
			FROM cte_wndw JOIN cte_agg ON cte_wndw.personid2 = cte_agg.personid AND cte_wndw.trip_link2 = cte_agg.trip_link;

		-- discard potential linked trips that are actually loops, returning to the same location
	
		DELETE lt FROM #linked_trips AS lt JOIN HHSurvey.Trip AS t on t.personid = lt.personid AND t.tripnum = lt.trip_link
			WHERE t.origin_geog.STDistance(geography::STGeomFromText('POINT(' + CAST(lt.dest_lng AS VARCHAR(20)) + ' ' + CAST(lt.dest_lat AS VARCHAR(20)) + ')', 4326)) < 50;

		-- delete the components that will get replaced with linked trips
		DELETE t
		FROM HHSurvey.Trip AS t JOIN #trip_ingredient AS ti ON t.recid=ti.recid
		WHERE t.tripnum <> ti.trip_link AND EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE ti.personid = lt.personid AND ti.trip_link = lt.trip_link);	

		-- this update achieves trip linking via revising elements of the 1st component (purposely left in the trip table).		
		UPDATE 	t
			SET t.dest_purpose 		= lt.dest_purpose * (CASE WHEN lt.dest_purpose IN(-97,-60) THEN -1 ELSE 1 END),	
				t.dest_name 		= lt.dest_name,		
			--	t.transit_systems	= lt.transit_systems,
			--	t.transit_lines		= lt.transit_lines,
				t.modes				= lt.modes,
				t.dest_is_home		= lt.dest_is_home,					
				t.dest_is_work		= lt.dest_is_work,
				t.dest_lat			= lt.dest_lat,
				t.dest_lng			= lt.dest_lng,					
			
				t.arrival_time_hhmm = FORMAT(t.arrival_time_timestamp,N'hh\:mm tt','en-US'), 
				t.arrival_time_mam  = DATEDIFF(minute, DATETIME2FROMPARTS(DATEPART(year, lt.arrival_time_timestamp),
																		  DATEPART(month,lt.arrival_time_timestamp), 
																		  DATEPART(day,lt.arrival_time_timestamp),0,0,0,0,0),
												lt.arrival_time_timestamp),
				t.speed_mph			= CASE WHEN (lt.trip_path_distance > 0 AND (CAST(DATEDIFF_BIG (second, t.depart_time_timestamp, lt.arrival_time_timestamp) AS numeric) > 0)) 
									   THEN  lt.trip_path_distance / (CAST(DATEDIFF_BIG (second, t.depart_time_timestamp, lt.arrival_time_timestamp) AS numeric)/3600) 
									   ELSE 0 END,
				t.reported_duration	= CAST(DATEDIFF(second, t.depart_time_timestamp, lt.arrival_time_timestamp) AS numeric)/60,					   	

				t.arrival_time_timestamp = lt.arrival_time_timestamp,	t.hhmember1 	= lt.hhmember1, 
				t.trip_path_distance 	= lt.trip_path_distance, 		t.hhmember2 	= lt.hhmember2, 
				t.google_duration 		= lt.google_duration, 			t.hhmember3 	= lt.hhmember3, 
																		t.hhmember4 	= lt.hhmember4, 
				t.travelers_hh 			= lt.travelers_hh, 				t.hhmember5 	= lt.hhmember5, 
				t.travelers_nonhh 		= lt.travelers_nonhh, 			t.hhmember6 	= lt.hhmember6,
				t.travelers_total 		= lt.travelers_total,			t.hhmember7 	= lt.hhmember7, 
																		t.hhmember8 	= lt.hhmember8, 
				t.pool_start			= lt.pool_start, 				t.hhmember9 	= lt.hhmember9,
																		t.hhmember10 	= lt.hhmember10, 
																		t.hhmember11 	= lt.hhmember11, 				 
				t.change_vehicles		= lt.change_vehicles, /*		t.park 			= lt.park, 
				t.park_ride_area_start	= lt.park_ride_area_start, */	t.toll			= lt.toll, /*
				t.park_ride_area_end	= lt.park_ride_area_end, 		t.park_type		= lt.park_type, 
				t.park_ride_lot_start	= lt.park_ride_lot_start, 		t.taxi_type		= lt.taxi_type, 
				t.park_ride_lot_end		= lt.park_ride_lot_end, 		t.bus_type		= lt.bus_type, 	
																		t.ferry_type	= lt.ferry_type, 
																		t.air_type		= lt.air_type,*/
				--t.psrc_comment = 'Re-standardize modes', 	
				t.revision_code = CONCAT(t.revision_code, '8,')
			FROM HHSurvey.Trip AS t JOIN #linked_trips AS lt ON t.personid = lt.personid AND t.tripnum = lt.trip_link;

		--move the ingredients to another named table so this procedure can be re-run as sproc during manual cleaning

		DELETE FROM #trip_ingredient
		OUTPUT deleted.* INTO HHSurvey.trip_ingredients_done
		WHERE #trip_ingredient.trip_link > 0;

/* STEP 5.	Mode number standardization, including access and egress characterization */

		--eliminate repeated values for modes, transit_systems, and transit_lines
		UPDATE t 
			SET t.modes				= Elmer.dbo.TRIM(Elmer.dbo.rgx_replace(t.modes,'(-?\b\d+\b),(?=\b\1\b)','',1))/*,
				t.transit_systems 	= Elmer.dbo.TRIM(Elmer.dbo.rgx_replace(t.transit_systems,'(\b\d+\b),(?=\b\1\b)','',1)), 
				t.transit_lines 	= Elmer.dbo.TRIM(Elmer.dbo.rgx_replace(t.transit_lines,'(\b\d+\b),(?=\b\1\b)','',1))*/
			FROM HHSurvey.Trip AS t WHERE EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =t.personid AND lt.trip_link = t.tripnum);

		EXECUTE HHSurvey.tripnum_update; 
				
		UPDATE HHSurvey.Trip SET mode_acc = NULL, mode_egr = NULL   -- Clears what was stored as access or egress; those values are still part of the chain captured in the concatenated 'modes' field.
			WHERE EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =trip.personid AND lt.trip_link = trip.tripnum);

		-- Characterize access and egress trips, separately for 1) transit trips and 2) auto trips.  (Bike/Ped trips have no access/egress)
		-- [Unions must be used here; otherwise the VALUE set from the dbo.Rgx table object gets reused across cte fields.]
		WITH cte_acc_egr1  AS 
		(	SELECT t1.personid, t1.tripnum, 'A' AS label, 'transit' AS trip_type,
				(SELECT MAX(CAST(VALUE AS int)) FROM STRING_SPLIT(Elmer.dbo.rgx_extract(t1.modes,'^((?:1|2|3|4|5|6|7|8|9|10|11|12|16|17|18|21|22|33|34|36|37|47|70|71|72|73|74|75),)+',1),',')) AS link_value
			FROM HHSurvey.Trip AS t1 WHERE EXISTS (SELECT 1 FROM STRING_SPLIT(t1.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.transitmodes)) 
								AND Elmer.dbo.rgx_extract(t1.modes,'^(\b(?:1|2|3|4|5|6|7|8|9|10|11|12|16|17|18|21|22|33|34|36|37|47|70|71|72|73|74|75)\b,?)+',1) IS NOT NULL
			UNION ALL 
			SELECT t2.personid, t2.tripnum, 'E' AS label, 'transit' AS trip_type,	
				(SELECT MAX(CAST(VALUE AS int)) FROM STRING_SPLIT(Elmer.dbo.rgx_extract(t2.modes,'(,(?:1|2|3|4|5|6|7|8|9|10|11|12|16|17|18|21|22|33|34|36|37|47|70|71|72|73|74|75))+$',1),',')) AS link_value 
			FROM HHSurvey.Trip AS t2 WHERE EXISTS (SELECT 1 FROM STRING_SPLIT(t2.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.transitmodes))
								AND Elmer.dbo.rgx_extract(t2.modes,'^(\b(?:1|2|3|4|5|6|7|8|9|10|11|12|16|17|18|21|22|33|34|36|37|47|70|71|72|73|74|75)\b,?)+',1) IS NOT NULL			
			UNION ALL 
			SELECT t3.personid, t3.tripnum, 'A' AS label, 'auto' AS trip_type,
				(SELECT MAX(CAST(VALUE AS int)) FROM STRING_SPLIT(Elmer.dbo.rgx_extract(t3.modes,'^((?:1|2|72|73|74|75)\b,?)+',1),',')) AS link_value
			FROM HHSurvey.Trip AS t3 WHERE EXISTS (SELECT 1 FROM STRING_SPLIT(t3.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes)) 
								  AND NOT EXISTS (SELECT 1 FROM STRING_SPLIT(t3.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.transitmodes))
								  AND Elmer.dbo.rgx_replace(t3.modes,'^(\b(?:1|2|72|73|74|75)\b,?)+','',1) IS NOT NULL
			UNION ALL 
			SELECT t4.personid, t4.tripnum, 'E' AS label, 'auto' AS trip_type,
				(SELECT MAX(CAST(VALUE AS int)) FROM STRING_SPLIT(Elmer.dbo.rgx_extract(t4.modes,'(,(?:1|2|72|73|74|75))+$',1),',')) AS link_value
			FROM HHSurvey.Trip AS t4 WHERE EXISTS (SELECT 1 FROM STRING_SPLIT(t4.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes)) 
								  AND NOT EXISTS (SELECT 1 FROM STRING_SPLIT(t4.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.transitmodes))
								  AND Elmer.dbo.rgx_replace(t4.modes,'^(\b(?:1|2|72|73|74|75)\b,?)+','',1) IS NOT NULL),
		cte_acc_egr2 AS (SELECT cte.personid, cte.tripnum, cte.trip_type,
								MAX(CASE WHEN cte.label = 'A' THEN cte.link_value ELSE NULL END) AS mode_acc,
								MAX(CASE WHEN cte.label = 'E' THEN cte.link_value ELSE NULL END) AS mode_egr
			FROM cte_acc_egr1 AS cte GROUP BY cte.personid, cte.tripnum, cte.trip_type)
		UPDATE t 
			SET t.mode_acc = cte_acc_egr2.mode_acc,
				t.mode_egr = cte_acc_egr2.mode_egr
			FROM HHSurvey.Trip AS t JOIN cte_acc_egr2 ON t.personid = cte_acc_egr2.personid AND t.tripnum = cte_acc_egr2.tripnum WHERE EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =t.personid AND lt.trip_link = t.tripnum);

		--handle the 'other' category left out of the operation above (it is the largest integer but secondary to listed modes)
		UPDATE HHSurvey.Trip SET trip.mode_acc = 97 WHERE trip.mode_acc IS NULL AND Elmer.dbo.rgx_find(trip.modes,'^97,\d+',1) = 1
			AND EXISTS (SELECT 1 FROM STRING_SPLIT(trip.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes UNION select mode_id FROM HHSurvey.transitmodes)) AND EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =trip.personid AND lt.trip_link = trip.tripnum);
		UPDATE HHSurvey.Trip SET trip.mode_egr = 97 WHERE trip.mode_egr IS NULL AND Elmer.dbo.rgx_find(trip.modes,'\d+,97$',1) = 1
			AND EXISTS (SELECT 1 FROM STRING_SPLIT(trip.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes UNION select mode_id FROM HHSurvey.transitmodes)) AND EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =trip.personid AND lt.trip_link = trip.tripnum);	

		-- Populate separate mode fields, removing access/egress from the beginning and end of 1) transit and 2) auto trip strings
			WITH cte AS 
		(SELECT t1.recid, Elmer.dbo.rgx_replace(Elmer.dbo.rgx_replace(Elmer.dbo.rgx_replace(t1.modes,'\b(1|2|72|73|74|75|97)\b','',1),'(,(?:3|4|5|6|7|8|9|10|11|12|16|17|18|21|22|33|34|36|37|47|70|71))+$','',1),'^((?:3|4|5|6|7|8|9|10|11|12|16|17|18|21|22|33|34|36|37|47|70|71),)+','',1) AS mode_reduced
			FROM HHSurvey.Trip AS t1
			WHERE EXISTS (SELECT 1 FROM STRING_SPLIT(t1.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.transitmodes))
		UNION ALL 	
		SELECT t2.recid, Elmer.dbo.rgx_replace(t2.modes,'\b(1|2|72|73|74|75|97)\b','',1) AS mode_reduced
			FROM HHSurvey.Trip AS t2
			WHERE EXISTS (SELECT 1 FROM STRING_SPLIT(t2.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes))
			AND NOT EXISTS (SELECT 1 FROM STRING_SPLIT(t2.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.transitmodes)))
		UPDATE t
			SET mode_1 = (SELECT match FROM Elmer.dbo.rgx_matches(cte.mode_reduced,'\b\d+\b',1) ORDER BY match_index OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY)/*,
				mode_2 = (SELECT match FROM Elmer.dbo.rgx_matches(cte.mode_reduced,'\b\d+\b',1) ORDER BY match_index OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
				mode_3 = (SELECT match FROM Elmer.dbo.rgx_matches(cte.mode_reduced,'\b\d+\b',1) ORDER BY match_index OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
				mode_4 = (SELECT match FROM Elmer.dbo.rgx_matches(cte.mode_reduced,'\b\d+\b',1) ORDER BY match_index OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY)*/
		FROM HHSurvey.Trip AS t JOIN cte ON t.recid = cte.recid AND EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =t.personid AND lt.trip_link = t.tripnum);

/*		-- Populate transit_system and transit_line fields with the revised concatenated data 		
        UPDATE t
        	SET t.transit_system_1	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_systems,	'\b\d+\b',1) ORDER BY match_index OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_system_2	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_systems,	'\b\d+\b',1) ORDER BY match_index OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_system_3	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_systems,	'\b\d+\b',1) ORDER BY match_index OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_system_4	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_systems,	'\b\d+\b',1) ORDER BY match_index OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_system_5	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_systems,	'\b\d+\b',1) ORDER BY match_index OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_system_6	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_systems,	'\b\d+\b',1) ORDER BY match_index OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_line_1	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_lines,	'\b\d+\b',1) ORDER BY match_index OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_line_2	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_lines,	'\b\d+\b',1) ORDER BY match_index OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_line_3	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_lines,	'\b\d+\b',1) ORDER BY match_index OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_line_4	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_lines,	'\b\d+\b',1) ORDER BY match_index OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_line_5	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_lines,	'\b\d+\b',1) ORDER BY match_index OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY),
				t.transit_line_6	= (SELECT match FROM Elmer.dbo.rgx_matches(t.transit_lines,	'\b\d+\b',1) ORDER BY match_index OFFSET 5 ROWS FETCH NEXT 1 ROWS ONLY)
			FROM HHSurvey.Trip AS t WHERE EXISTS (SELECT 1 FROM #linked_trips AS lt WHERE lt.personid =t.personid AND lt.trip_link = t.tripnum);*/

		UPDATE HHSurvey.Trip SET mode_acc = 995 WHERE mode_acc IS NULL;
		UPDATE HHSurvey.Trip SET mode_1   = 995 WHERE mode_1   IS NULL;
	/*	UPDATE HHSurvey.Trip SET mode_2   = 995 WHERE mode_2   IS NULL;
		UPDATE HHSurvey.Trip SET mode_3   = 995 WHERE mode_3   IS NULL;
		UPDATE HHSurvey.Trip SET mode_4   = 995 WHERE mode_4   IS NULL; */
		UPDATE HHSurvey.Trip SET mode_egr = 995 WHERE mode_egr IS NULL;
	/*	UPDATE HHSurvey.Trip SET transit_system_1 = 995 WHERE transit_system_1 IS NULL;
		UPDATE HHSurvey.Trip SET transit_system_2 = 995 WHERE transit_system_2 IS NULL;
		UPDATE HHSurvey.Trip SET transit_system_3 = 995 WHERE transit_system_3 IS NULL;
		UPDATE HHSurvey.Trip SET transit_system_4 = 995 WHERE transit_system_4 IS NULL;
		UPDATE HHSurvey.Trip SET transit_system_5 = 995 WHERE transit_system_5 IS NULL;
		UPDATE HHSurvey.Trip SET transit_system_6 = 995 WHERE transit_system_6 IS NULL;
		UPDATE HHSurvey.Trip SET transit_line_1 = 995 WHERE transit_line_1 IS NULL;
		UPDATE HHSurvey.Trip SET transit_line_2 = 995 WHERE transit_line_2 IS NULL;
		UPDATE HHSurvey.Trip SET transit_line_3 = 995 WHERE transit_line_3 IS NULL;
		UPDATE HHSurvey.Trip SET transit_line_4 = 995 WHERE transit_line_4 IS NULL;
		UPDATE HHSurvey.Trip SET transit_line_5 = 995 WHERE transit_line_5 IS NULL;
		UPDATE HHSurvey.Trip SET transit_line_6 = 995 WHERE transit_line_5 IS NULL;*/

		--temp tables should disappear when the spoc ends, but to be tidy we explicitly delete them.
		DROP TABLE IF EXISTS #trip_ingredient
		DROP TABLE IF EXISTS #linked_trips

		END

		EXECUTE HHSurvey.link_trips;
			 
/* STEP 6. Harmonize trips where possible: add trips for non-reporting cotravelers, missing trips between destinations, and remove duplicates  */

	--Insert trips for those who were reported as a passenger by another traveler but did not report the trip themselves (may deserve scrutiny--tight criteria result in few records being generated)

   DROP TABLE IF EXISTS HHSurvey.silent_passenger_trip;
   GO
   WITH cte AS --create CTE set of passenger trips
        (         SELECT recid, pernum AS respondent, hhmember1 as passengerid FROM HHSurvey.Trip WHERE hhmember1 IS NOT NULL AND hhmember1 not in (select flag_value from HHSurvey.NullFlags) AND hhmember1 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember2 as passengerid FROM HHSurvey.Trip WHERE hhmember2 IS NOT NULL AND hhmember2 not in (select flag_value from HHSurvey.NullFlags) AND hhmember2 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember3 as passengerid FROM HHSurvey.Trip WHERE hhmember3 IS NOT NULL AND hhmember3 not in (select flag_value from HHSurvey.NullFlags) AND hhmember3 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember4 as passengerid FROM HHSurvey.Trip WHERE hhmember4 IS NOT NULL AND hhmember4 not in (select flag_value from HHSurvey.NullFlags) AND hhmember4 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember5 as passengerid FROM HHSurvey.Trip WHERE hhmember5 IS NOT NULL AND hhmember5 not in (select flag_value from HHSurvey.NullFlags) AND hhmember5 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember6 as passengerid FROM HHSurvey.Trip WHERE hhmember6 IS NOT NULL AND hhmember6 not in (select flag_value from HHSurvey.NullFlags) AND hhmember6 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember7 as passengerid FROM HHSurvey.Trip WHERE hhmember7 IS NOT NULL AND hhmember7 not in (select flag_value from HHSurvey.NullFlags) AND hhmember7 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember8 as passengerid FROM HHSurvey.Trip WHERE hhmember8 IS NOT NULL AND hhmember8 not in (select flag_value from HHSurvey.NullFlags) AND hhmember8 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember9 as passengerid FROM HHSurvey.Trip WHERE hhmember8 IS NOT NULL AND hhmember9 not in (select flag_value from HHSurvey.NullFlags) AND hhmember9 <> personid
        UNION ALL SELECT recid, pernum AS respondent, hhmember10 as passengerid FROM HHSurvey.Trip WHERE hhmember8 IS NOT NULL AND hhmember10 not in (select flag_value from HHSurvey.NullFlags) AND hhmember10 <> personid
		UNION ALL SELECT recid, pernum AS respondent, hhmember11 as passengerid FROM HHSurvey.Trip WHERE hhmember8 IS NOT NULL AND hhmember11 not in (select flag_value from HHSurvey.NullFlags) AND hhmember11 <> personid)
	SELECT recid, respondent, passengerid INTO HHSurvey.silent_passenger_trip FROM cte GROUP BY recid, respondent, passengerid;

	DROP PROCEDURE IF EXISTS HHSurvey.silent_passenger_trips_inserted;
	GO
	CREATE PROCEDURE HHSurvey.silent_passenger_trips_inserted 
	AS BEGIN
	DECLARE @respondent int 
	SET @respondent = 1;
    INSERT INTO HHSurvey.Trip
		(hhid, personid, pernum, hhgroup,
		depart_time_timestamp, arrival_time_timestamp,
		dest_name, dest_lat, dest_lng,
		trip_path_distance, google_duration, reported_duration,
		hhmember1, hhmember2, hhmember3, hhmember4, hhmember5, hhmember6, hhmember7, hhmember8, hhmember9, hhmember10, hhmember11, travelers_hh, travelers_nonhh, travelers_total,
		mode_acc, mode_egr, mode_1, toll, toll_pay, taxi_pay, 
	/*	mode_2, mode_3, mode_4, change_vehicles, transit_system_1, transit_system_2, transit_system_3,
		park_ride_area_start, park_ride_area_end, park_ride_lot_start, park_ride_lot_end, park, park_type, park_pay,
		taxi_type, bus_type, bus_pay, bus_cost_dk, ferry_type, ferry_pay, ferry_cost_dk, air_type, air_pay, airfare_cost_dk, */
		origin_geog, origin_lat, origin_lng, dest_geog, dest_county, dest_city, dest_zip, dest_is_home, dest_is_work, psrc_inserted, revision_code)
	SELECT -- select fields necessary for new trip records	
		t.hhid, spt.passengerid AS personid, CAST(RIGHT(spt.passengerid,2) AS int) AS pernum, t.hhgroup,
		t.depart_time_timestamp, t.arrival_time_timestamp,
		t.dest_name, t.dest_lat, t.dest_lng,
		t.trip_path_distance, t.google_duration, t.reported_duration,
		t.hhmember1, t.hhmember2, t.hhmember3, t.hhmember4, t.hhmember5, t.hhmember6, t.hhmember7, t.hhmember8, t.hhmember9, t.hhmember10, t.hhmember11, t.travelers_hh, t.travelers_nonhh, t.travelers_total,
		t.mode_acc, t.mode_egr, t.mode_1, t.toll, t.toll_pay, t.taxi_pay, 
	/*	t.mode_2, t.mode_3, t.mode_4, t.change_vehicles, t.transit_system_1, t.transit_system_2, t.transit_system_3,
		t.park_ride_area_start, t.park_ride_area_end, t.park_ride_lot_start, t.park_ride_lot_end, t.park, t.park_type, t.park_pay,
		t.taxi_type, t.bus_type, t.bus_pay, t.bus_cost_dk, t.ferry_type, t.ferry_pay, t.ferry_cost_dk, t.air_type, t.air_pay, t.airfare_cost_dk, */
		t.origin_geog, t.origin_lat, t.origin_lng, t.dest_geog, t.dest_county, t.dest_city, t.dest_zip, t.dest_is_home, t.dest_is_work, 1 AS psrc_inserted, CONCAT(t.revision_code, '9,') AS revision_code
	FROM HHSurvey.silent_passenger_trip AS spt -- insert only when the CTE trip doesn't overlap any trip by the same person; doesn't matter if an intersecting trip reports the other hhmembers or not.
        JOIN HHSurvey.Trip as t ON spt.recid = t.recid
		LEFT JOIN HHSurvey.Trip as compare_t ON spt.passengerid = compare_t.personid
		WHERE spt.passengerid <> compare_t.personid
			AND spt.respondent = @respondent
			AND (t.depart_time_timestamp NOT BETWEEN compare_t.depart_time_timestamp AND compare_t.arrival_time_timestamp)
				AND (t.arrival_time_timestamp NOT BETWEEN compare_t.depart_time_timestamp AND compare_t.arrival_time_timestamp);
	SET @respondent = @respondent + 1	
	END
	GO

	/* 	Batching by respondent prevents duplication in the case silent passengers were reported by multiple household members on the same trip.
		While there were copied trips with silent passengers listed in both (as they should), the 2017 data had no silent passenger trips in which pernum 1 was not involved;
		that is not guaranteed, so I've left the 8 procedure calls in, although later ones can be expected not to have an effect
	*/ 
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	EXECUTE HHSurvey.silent_passenger_trips_inserted;
	DROP PROCEDURE HHSurvey.silent_passenger_trips_inserted;
	DROP TABLE HHSurvey.silent_passenger_trip;

	EXECUTE HHSurvey.tripnum_update; --after adding records, we need to renumber them consecutively
	EXECUTE HHSurvey.dest_purpose_updates;  --running these again to apply to linked trips, JIC

	--recode driver flag when mistakenly applied to passengers and a hh driver is present
	UPDATE t
		SET t.driver = 2, t.revision_code = CONCAT(t.revision_code, '10,')
		FROM HHSurvey.Trip AS t JOIN HHSurvey.person AS p ON t.personid = p.personid
		WHERE t.driver = 1 AND (p.age < 4 OR p.license = 3)
			AND EXISTS (SELECT 1 FROM (VALUES (t.hhmember1),(t.hhmember2),(t.hhmember3),(t.hhmember4),(t.hhmember5),(t.hhmember6),(t.hhmember7),(t.hhmember8),(t.hhmember9),(t.hhmember10),(t.hhmember11)) AS hhmem(member) JOIN HHSurvey.person as p2 ON hhmem.member = p2.personid WHERE p2.license in(1,2) AND p2.age > 3);

	--recode work purpose when mistakenly applied to passengers and a hh worker is present
	UPDATE t
		SET t.dest_purpose = 97, t.revision_code = CONCAT(t.revision_code, '11,')
		FROM HHSurvey.Trip AS t JOIN HHSurvey.person AS p ON t.personid = p.personid
		WHERE t.dest_purpose IN(10,11,14) AND (p.age < 4 OR p.worker = 0)
			AND EXISTS (SELECT 1 FROM (VALUES (t.hhmember1),(t.hhmember2),(t.hhmember3),(t.hhmember4),(t.hhmember5),(t.hhmember6),(t.hhmember7),(t.hhmember8),(t.hhmember9),(t.hhmember10),(t.hhmember11)) AS hhmem(member) JOIN HHSurvey.person as p2 ON hhmem.member = p2.personid WHERE p2.worker = 1 AND p2.age > 3);

	--Add trips in cases the origin of a trip is over 500m from the destination of the prior, with conditions

	EXECUTE HHSurvey.tripnum_update;
	GO

/*	WITH cte_ref AS (
		SELECT t.recid,
					Elmer.dbo.route_mi_min(t.origin_lng, t.origin_lat, t.dest_lng, t.dest_lat, 
										   CASE WHEN EXISTS (SELECT 1 FROM HHSurvey.AutoModes    AS am WHERE am.mode_id = t.mode_1) THEN 'driving' 
										   		WHEN EXISTS (SELECT 1 FROM HHSurvey.TransitModes AS tm WHERE tm.mode_id = t.mode_1) THEN 'transit'
												WHEN EXISTS (SELECT 1 FROM HHSurvey.PedModes     AS pm WHERE pm.mode_id = t.mode_1) THEN 'walking' ELSE 'driving' END,   
												@BingKey) AS mi_min_result,
					CASE WHEN t.mode_1 = nxt.mode_1 AND EXISTS (SELECT 1 FROM HHSurvey.AutoModes AS am WHERE am.mode_id = t.mode_1) THEN t.mode_1 ELSE 995 END AS mode,
					CASE WHEN DATEDIFF(Day, t.arrival_time_timestamp, nxt.depart_time_timestamp) = 0 THEN '16,' ELSE '17,' END AS revision_code,
					CASE WHEN DATEDIFF(Day, t.arrival_time_timestamp, nxt.depart_time_timestamp) = 0 THEN t.arrival_time_timestamp
							WHEN (t.dest_geog.STDistance(h.home_geog) < 300 OR t.dest_purpose IN(1,52,55,58,97)) THEN  DATETIME2FROMPARTS(DATEPART(year,nxt.depart_time_timestamp),DATEPART(month,nxt.depart_time_timestamp),DATEPART(day,nxt.depart_time_timestamp),3,0,0,0,0)
							ELSE t.arrival_time_timestamp END AS travelwindow_start,
					CASE WHEN DATEDIFF(Day, t.arrival_time_timestamp, nxt.depart_time_timestamp) = 0 THEN nxt.depart_time_timestamp
							WHEN (t.dest_geog.STDistance(h.home_geog) > 300 AND t.dest_purpose NOT IN(1,52,55,58,97)) THEN  DATETIME2FROMPARTS(DATEPART(year,nxt.depart_time_timestamp),DATEPART(month,nxt.depart_time_timestamp),DATEPART(day,nxt.depart_time_timestamp),0,0,0,0,0)
							ELSE nxt.depart_time_timestamp END AS travelwindow_end,
					CASE WHEN t.travelers_hh = nxt.travelers_hh THEN t.travelers_hh ELSE -9997 END AS travelers_hh, 
					CASE WHEN t.travelers_nonhh = nxt.travelers_nonhh THEN t.travelers_nonhh ELSE -9997 END AS travelers_nonhh,
					CASE WHEN t.travelers_total = nxt.travelers_total THEN t.travelers_total ELSE -9997 END AS travelers_total					 
			INTO HHSurvey.cte_ref
			FROM HHSurvey.Trip AS t 
			JOIN HHSurvey.Trip AS nxt ON nxt.personid = t.personid AND nxt.tripnum = t.tripnum + 1
			JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			WHERE ABS(t.dest_geog.STDistance(nxt.origin_geog)) > 500),
	aml AS (SELECT recid, 
				   CAST(LEFT(mi_min_result, CHARINDEX(mi_min_result,',')-1) AS float) AS distance, 
				   ROUND(CAST(RIGHT(mi_min_result,LEN(mi_min_result)-CHARINDEX(mi_min_result,',')) AS float),0) AS mode1_minutes
			FROM HHSurvey.cte_ref
			WHERE CHARINDEX(mi_min_result,',')>1),		
	cte AS (SELECT cte_ref.recid, cte_ref.travelers_hh, cte_ref.travelers_nonhh, cte_ref.travelers_total, cte_ref.revision_code,
			DATEADD(Minute, ((DATEDIFF(Second, cte_ref.travelwindow_start, cte_ref.travelwindow_end) / 60 - aml.mode1_minutes) / 2), cte_ref.travelwindow_start) AS depart_time_timestamp,
			aml.mode1_minutes AS travel_minutes, aml.distance
			FROM HHSurvey.cte_ref JOIN aml ON cte_ref.recid = aml.recid
			WHERE (DATEDIFF(Second, cte_ref.travelwindow_start, cte_ref.travelwindow_end) / 60) > aml.mode1_minutes
			AND aml.distance > 0.3)
	INSERT INTO HHSurvey.Trip (hhid, personid, pernum, hhgroup, tripnum, psrc_inserted, revision_code, dest_purpose,
							mode_1, modes, travelers_hh, travelers_nonhh, travelers_total,
							origin_lat, origin_lng, origin_geog, dest_lat, dest_lng, dest_geog, 
							trip_path_distance, depart_time_timestamp, arrival_time_timestamp, reported_duration)  --the last item was travel_time when combining rSurvey & rMove.
	SELECT t.hhid, t.personid, t.pernum, t.hhgroup, 99 AS tripnum, 1 AS psrc_inserted, cte.revision_code, -9998 AS dest_purpose,
			t.mode_1, CAST(t.mode_1 AS NVARCHAR) AS modes, cte.travelers_hh, cte.travelers_nonhh, cte.travelers_total,
			t.dest_lat AS origin_lat, t.dest_lng AS origin_lng, t.dest_geog AS origin_geog, nxt.origin_lat AS dest_lat, nxt.origin_lng AS dest_lng, nxt.origin_geog AS dest_geog,
			cte.distance AS trip_path_distance, cte.depart_time_timestamp, DATEADD(Minute, cte.travel_minutes, cte.depart_time_timestamp) AS arrival_time_timestamp, cte.travel_minutes
		FROM HHSurvey.Trip AS t JOIN HHSurvey.Trip AS nxt ON nxt.personid = t.personid AND nxt.tripnum = t.tripnum + 1 JOIN cte ON t.recid = cte.recid;
	GO
	EXECUTE HHSurvey.tripnum_update;
	GO
	EXECUTE HHSurvey.recalculate_after_edit;
	GO
*/

	--Remove duplicated home trips generated by the app
	DROP TABLE IF EXISTS HHSurvey.removed_trip;
	GO
	SELECT TOP 0 trip.* INTO HHSurvey.removed_trip
		FROM HHSurvey.Trip
	UNION ALL -- union for the side effect of preventing recid from being an IDENTITY column.
	SELECT top 0 Trip.* 
		FROM HHSurvey.Trip
	GO
	TRUNCATE TABLE HHSurvey.removed_trip;
	GO
	
	WITH cte AS 
	(SELECT t.recid 
		FROM HHSurvey.Trip AS t 
		JOIN 		HHSurvey.Trip AS prior_t ON t.personid = prior_t.personid AND t.tripnum - 1 = prior_t.tripnum AND t.daynum = prior_t.daynum
		LEFT JOIN 	HHSurvey.Trip AS next_t  ON t.personid = next_t.personid  AND t.tripnum + 1 = next_t.tripnum  AND t.daynum = next_t.daynum
		WHERE t.origin_purpose = 1 AND t.dest_purpose = 1 AND next_t.recid IS NULL AND ABS(t.dest_geog.STDistance(t.origin_geog)) < 100 ) -- points within 100m of one another
	DELETE FROM HHSurvey.Trip OUTPUT deleted.* INTO HHSurvey.removed_trip
		WHERE EXISTS (SELECT 1 FROM cte WHERE trip.recid = cte.recid);

/* STEP 7. Revise travel times (and where necessary, mode) */  
	
	/* Change departure or arrival times for records that would qualify for 'excessive speed' flag, using external Google Distance Matrix API */

		-- Revise departure, and if necessary, arrival times and mode
        -- Preference to reported mode if travel time matches the available window; if not, drive time is considered as an alternative for trips under 7hrs
		DROP TABLE IF EXISTS tmpApiMiMin;
		GO

		CREATE TABLE [dbo].[tmpApiMiMin](
			recid int NOT NULL,
			origin_geog geography NULL,
			dest_geog geography NULL,
			trip_path_distance float NULL,
			revision_code nvarchar(50) NOT NULL,
			prev_arrival datetime2(7) NULL,
			depart datetime2(7) NULL,
			arrival datetime2(7) NULL,
			next_depart datetime2(7) NULL,
			query_mode varchar(7) NOT NULL,
			api_result nvarchar(max) NULL,
			tmiles float NOT NULL,
			tminutes float NOT NULL,
			adj int NOT NULL
		)
		GO

		WITH cte AS (SELECT t.recid, t.origin_geog, t.dest_geog, t.trip_path_distance, CONCAT(t.revision_code, '12,') AS revision_code,
			prev_t.arrival_time_timestamp AS prev_arrival, t.depart_time_timestamp AS depart, t.arrival_time_timestamp AS arrival, next_t.depart_time_timestamp AS next_depart, 
			CASE WHEN EXISTS (SELECT 1 FROM HHSurvey.walkmodes WHERE walkmodes.mode_id = t.mode_1) THEN 'walking' 
				 --WHEN EXISTS (SELECT 1 FROM HHSurvey.transitmodes WHERE transitmodes.mode_id = t.mode_1) THEN 'transit' 
				 ELSE 'driving' END as query_mode
		FROM HHSurvey.Trip AS t
				LEFT JOIN HHSurvey.Trip AS prev_t ON t.personid = prev_t.personid AND t.tripnum -1 = prev_t.tripnum
				LEFT JOIN HHSurvey.Trip AS next_t ON t.personid = next_t.personid AND t.tripnum +1 = next_t.tripnum
			WHERE ((EXISTS (SELECT 1 FROM HHSurvey.walkmodes WHERE walkmodes.mode_id = t.mode_1) AND t.speed_mph > 20)
			    OR (EXISTS (SELECT 1 FROM HHSurvey.automodes WHERE automodes.mode_id = t.mode_1) AND t.speed_mph > 85)	
			   -- OR (EXISTS (SELECT 1 FROM HHSurvey.transitmodes WHERE transitmodes.mode_id = t.mode_1) AND t.mode_1 <> 31 AND t.speed_mph > 60)	
			    OR (t.speed_mph > 600 AND (t.origin_lng between 116.95 AND 140) AND (t.dest_lng between 116.95 AND 140))) )       -- qualifies for 'excessive speed' flag	 AND t.recid < 1000
		INSERT INTO tmpApiMiMin(recid, origin_geog, dest_geog, trip_path_distance, revision_code, prev_arrival, depart, arrival, next_depart, query_mode, api_result, tmiles, tminutes, adj)
		SELECT cte.*, Elmer.dbo.route_mi_min(cte.origin_geog.Long, cte.origin_geog.Lat, cte.dest_geog.Long, cte.dest_geog.Lat, cte.query_mode,'[INSERT BING KEY HERE]') AS api_result, 
				0.0000000 AS tmiles, 0.000 AS tminutes, 0 AS adj
		FROM cte
		WHERE cte.origin_geog.Long <1 AND cte.origin_geog.Lat >1 AND cte.dest_geog.Long <1 AND cte.dest_geog.Lat >1; 

		UPDATE tmpApiMiMin SET tmiles = CAST(Elmer.dbo.rgx_replace(api_result,'^(.*),.*','$1',1) AS float), 
		                     tminutes = CAST(Elmer.dbo.rgx_replace(api_result,'.*,(.*)$','$1',1) AS float);

		UPDATE tmpApiMiMin
			SET trip_path_distance = tmiles, adj = 1,
			depart  = DATEADD(Second, round(-60 * tminutes, 0), arrival)
			WHERE DATEDIFF(Second, prev_arrival, arrival)/60.0 -1 > tminutes AND adj = 0							--fits the window to adjust departure only	
			  AND (query_mode <> 'walking' 
			  OR DATEDIFF(Day, DATEADD(Hour, 3, DATEADD(Second, round(-60 * tminutes, 0), arrival)), arrival) = 0); 			 --walk doesn't cross 3am boundary		

		UPDATE tmpApiMiMin
			SET trip_path_distance = tmiles, adj = 2,
			depart  = DATEADD(Second, (DATEDIFF(Second, prev_arrival, next_depart)/2 - tminutes * 30), prev_arrival), 
			arrival =  DATEADD(Second, (DATEDIFF(Second, prev_arrival, next_depart)/2 + tminutes * 30), prev_arrival) 
			WHERE (DATEDIFF(Second, prev_arrival, next_depart)/60.0 -2) > tminutes AND adj = 0			                	  --fits the maximum travel window
			  AND (query_mode <> 'walking' 
			  OR DATEDIFF(Day, DATEADD(Hour, 3, 
			  	  DATEADD(Second, (DATEDIFF(Second, prev_arrival, next_depart)/2 - tminutes * 30), prev_arrival)), 
				   DATEADD(Second, (DATEDIFF(Second, prev_arrival, next_depart)/2 + tminutes * 30), prev_arrival)) = 0);     --walk doesn't cross 3am boundary	
		
		UPDATE tmpApiMiMin
			SET adj = -1, revision_code = CONCAT(revision_code, '13,'), 											          --where walk doesn't fit, try driving
			tminutes = CAST(Elmer.dbo.rgx_replace(Elmer.dbo.route_mi_min(origin_geog.Long, origin_geog.Lat, dest_geog.Long, dest_geog.Lat,'driving','AmXTWUc52YYqvdSlHNGUEAe3RH1TvtcECyH6RGZm7q2vhzv9JzOm1GaY9TKW47lF'),'.*,(.*)$','$1',1) AS float)
			WHERE query_mode = 'walking' AND adj = 0 AND DATEDIFF(Minute, depart, arrival)/60 < 7;

		UPDATE tmpApiMiMin
			SET adj = 3
			WHERE adj = -1 																		   	                	 	   --only potential mode recodes
			  AND ABS(DATEDIFF(Second, depart, arrival)/60 - tminutes) < 5;													   --drive matches reported time 

		UPDATE t																											   --carry out the update for relevant records
			SET t.trip_path_distance = amm.trip_path_distance, 
			    t.revision_code = amm.revision_code, 
				t.depart_time_timestamp = amm.depart, 
				t.arrival_time_timestamp = amm.arrival,
				t.mode_1 = CASE WHEN amm.adj = 3 THEN 16 ELSE t.mode_1 END
			FROM HHSurvey.Trip AS t JOIN tmpApiMiMin AS amm ON t.recid = amm.recid
			WHERE amm.adj > 0;
				
		/*DROP TABLE HHSurvey.tmpApiMiMin;*/																					  --clean up	
		GO

/* STEP 8. Flag inconsistencies */
/*	as additional error patterns behind these flags are identified, rules to address them can be added to Step 3 or elsewhere in Rulesy as makes sense.*/

		/*DROP TABLE IF EXISTS HHSurvey.hh_error_flags;
		CREATE TABLE HHSurvey.hh_error_flags (hhid decimal(19,0), error_flag NVARCHAR(100));
		INSERT INTO HHSurvey.hh_error_flags (hhid, error_flag)
		SELECT h.hhid, 'zero trips' FROM HHSurvey.household AS h LEFT JOIN HHSurvey.Trip AS t ON h.hhid = t.hhid
			WHERE t.hhid IS NULL
			GROUP BY h.hhid;*/

		DROP TABLE IF EXISTS HHSurvey.trip_error_flags;
		CREATE TABLE HHSurvey.trip_error_flags(
			recid decimal(19,0) not NULL,
			personid decimal(19,0) not NULL,
			tripnum int not null,
			error_flag varchar(100)
			PRIMARY KEY (personid, recid, error_flag)
			);

	DROP PROCEDURE IF EXISTS HHSurvey.generate_error_flags;
	GO
	CREATE PROCEDURE HHSurvey.generate_error_flags 
		@target_personid decimal = NULL --If missing, generated for all records
	AS BEGIN
	SET NOCOUNT ON

	EXECUTE HHSurvey.tripnum_update @target_personid;
	DELETE tef 
		FROM HHSurvey.trip_error_flags AS tef 
		WHERE tef.personid = (CASE WHEN @target_personid IS NULL THEN tef.personid ELSE @target_personid END);

		-- 																									  LOGICAL ERROR LABEL 		
		DROP TABLE IF EXISTS #dayends;
		SELECT t.personid, ROUND(t.dest_lat,2) AS loc_lat, ROUND(t.dest_lng,2) as loc_lng, count(*) AS n 
			INTO #dayends
			FROM HHSurvey.Trip AS t LEFT JOIN HHSurvey.Trip AS next_t ON t.personid = next_t.personid AND t.tripnum + 1 = next_t.tripnum
					WHERE (next_t.recid IS NULL											 -- either there is no 'next trip'
							OR (DATEDIFF(Day, t.arrival_time_timestamp, next_t.depart_time_timestamp) = 1 
								AND DATEPART(Hour, next_t.depart_time_timestamp) > 2 ))   -- or the next trip starts the next day after 3am)
					GROUP BY t.personid, ROUND(t.dest_lat,2), ROUND(t.dest_lng,2)
					HAVING count(*) > 1;

		ALTER TABLE #dayends ADD loc_geog GEOGRAPHY NULL;

		UPDATE #dayends 
			SET loc_geog = geography::STGeomFromText('POINT(' + CAST(loc_lng AS VARCHAR(20)) + ' ' + CAST(loc_lat AS VARCHAR(20)) + ')', 4326);
		
		WITH trip_ref AS (SELECT * FROM HHSurvey.Trip AS t0
						  WHERE (t0.dest_lat BETWEEN 46.725491 AND 48.392602) AND (t0.dest_lng BETWEEN -123.199429 AND -121.243746) 
						  	AND  t0.personid = (CASE WHEN @target_personid IS NULL THEN t0.personid ELSE @target_personid END)),
		/*	cte_dwell AS 
				(SELECT c.tripid, c.collected_at, cnxt.collected_at AS nxt_collected FROM HHSurvey.Trace AS c 
				JOIN HHSurvey.Trace AS cnxt ON c.traceid + 1 = cnxt.traceid AND c.tripid = cnxt.tripid
				WHERE DATEDIFF(Minute, c.collected_at, cnxt.collected_at) > 14),

			cte_tracecount AS (SELECT ctc.tripid, count(*) AS tracecount FROM HHSurvey.Trace AS ctc GROUP BY ctc.tripid HAVING count(*) > 2),
		*/
			error_flag_compilation(recid, personid, tripnum, error_flag) AS
			(SELECT t.recid, t.personid, t.tripnum,	           				   			                  'ends day, not home' AS error_flag
			FROM trip_ref AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE DATEDIFF(Day,(CASE WHEN DATEPART(Hour, t.arrival_time_timestamp) < 3 THEN DATEADD(Hour, -3, t.arrival_time_timestamp) ELSE t.arrival_time_timestamp END),
								   (CASE WHEN DATEPART(Hour, t_next.arrival_time_timestamp) < 3 THEN DATEADD(Hour, -3, t_next.depart_time_timestamp) WHEN t_next.arrival_time_timestamp IS NULL THEN DATEADD(Day, 1, t.arrival_time_timestamp) ELSE t_next.depart_time_timestamp END)) = 1  -- or the next trip starts the next day after 3am)
				AND t.dest_is_home IS NULL 
				AND t.dest_purpose NOT IN(1,34,52,55,62,97) 
				--AND Elmer.dbo.rgx_find(t.psrc_comment,'ADD RETURN HOME \d?\d:\d\d',1) = 0
				AND t.dest_geog.STDistance(h.home_geog) > 300
				AND NOT EXISTS (SELECT 1 FROM #dayends AS de WHERE t.personid = de.personid AND t.dest_geog.STDistance(de.loc_geog) < 300)
				AND Elmer.dbo.rgx_find(t.modes,'31',1) = 0		

			UNION ALL SELECT t_next.recid, t_next.personid, t_next.tripnum,	           		   		   'starts, not from home' AS error_flag
			FROM trip_ref AS t JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE DATEDIFF(Day, t.arrival_time_timestamp, t_next.depart_time_timestamp) = 1 -- t_next is first trip of the day
					AND t.dest_is_home IS NULL AND Elmer.dbo.TRIM(t_next.origin_name)<>'HOME'
					AND DATEPART(Hour, t_next.depart_time_timestamp) > 1  -- Night owls typically home before 2am

			 UNION ALL SELECT t.recid, t.personid, t.tripnum, 									       		 'purpose missing' AS error_flag
				FROM trip_ref AS t
					LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.dest_purpose = vl.code
				WHERE (vl.label LIKE 'Missing%' OR t.dest_purpose IS NULL)

			UNION ALL SELECT t.recid, t.personid, t.tripnum,  								   'initial trip purpose missing' AS error_flag
				FROM trip_ref AS t 
				JOIN HHSurvey.fnVariableLookup('dest_purpose') as vl ON t.origin_purpose = vl.code
				WHERE vl.label like 'Missing%' AND t.tripnum = 1

			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum, 											 'mode_1 missing' AS error_flag
				FROM trip_ref AS t
					LEFT JOIN trip_ref AS t_prev ON t.personid = t_prev.personid AND t.tripnum - 1 = t_prev.tripnum
					LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					JOIN HHSurvey.fnVariableLookup('mode_1') as vl ON t.mode_1 = vl.code
					LEFT JOIN HHSurvey.fnVariableLookup('mode_1') as v2 ON t_prev.mode_1 = v2.code
					LEFT JOIN HHSurvey.fnVariableLookup('mode_1') as v3 ON t_next.mode_1 = v3.code
				WHERE vl.label LIKE 'Missing%'
					AND v2.label NOT LIKE 'Missing%'  -- we don't want to focus on instances with large blocks of trips missing info
					AND v3.label NOT LIKE 'Missing%'

			UNION ALL SELECT t.recid, t.personid, t.tripnum, 					     'o purpose not equal to prior d purpose' AS error_flag
				FROM trip_ref AS t
					JOIN trip_ref AS t_prev ON t.personid = t_prev.personid AND t.tripnum - 1 = t_prev.tripnum
					WHERE t.origin_purpose <> t_prev.dest_purpose AND DATEDIFF(Day, t_prev.arrival_time_timestamp, t.depart_time_timestamp) =0

			UNION ALL SELECT max( t.recid),  t.personid, max( t.tripnum) AS tripnum, 							  'lone trip' AS error_flag
				FROM trip_ref AS t
				GROUP BY  t.personid 
				HAVING max( t.tripnum)=1

			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum,									        	'underage driver' AS error_flag
				FROM HHSurvey.person AS p
				JOIN trip_ref AS t ON p.personid = t.personid
				WHERE t.driver = 1 AND (p.age BETWEEN 1 AND 3)

			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum, 									      'unlicensed driver' AS error_flag
				FROM trip_ref as t JOIN HHSurvey.person AS p ON p.personid = t.personid
				WHERE p.license = 3 AND  t.driver = 1

			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum, 									  'driver, no-drive mode' AS error_flag
				FROM trip_ref as t
				WHERE t.mode_1 NOT IN (SELECT mode_id FROM automodes) AND  t.driver = 1

			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum, 							 		 'non-worker + work trip' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.person AS p ON p.personid= t.personid
				WHERE p.employment > 4 AND  t.dest_purpose in(10,11,14)

			UNION ALL SELECT t.recid, t.personid, t.tripnum, 												'excessive speed' AS error_flag
				FROM trip_ref AS t									
				WHERE 	((EXISTS (SELECT 1 FROM HHSurvey.walkmodes WHERE walkmodes.mode_id = t.mode_1) AND t.speed_mph > 20)
					OR 	(EXISTS (SELECT 1 FROM HHSurvey.bikemodes WHERE bikemodes.mode_id = t.mode_1) AND t.speed_mph > 40)
					OR	(EXISTS (SELECT 1 FROM HHSurvey.automodes WHERE automodes.mode_id = t.mode_1) AND t.speed_mph > 85)	
					OR	(EXISTS (SELECT 1 FROM HHSurvey.transitmodes WHERE transitmodes.mode_id = t.mode_1) AND t.mode_1 <> 31 AND t.speed_mph > 60)	
					OR 	(t.speed_mph > 600 AND (t.origin_lng between 116.95 AND 140) AND (t.dest_lng between 116.95 AND 140)))	-- approximates Pacific Time Zone until vendor delivers UST offset

			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum,					  					   				'too slow' AS error_flag
				FROM trip_ref AS t
				WHERE DATEDIFF(Minute,  t.depart_time_timestamp,  t.arrival_time_timestamp) > 180 AND  t.speed_mph < 20		

		/*	UNION ALL SELECT  t.recid,  t.personid,  t.tripnum,					  					   				'long dwell' AS error_flag
				FROM trip_ref AS t JOIN cte_tracecount ON t.tripid = cte_tracecount.tripid
				WHERE EXISTS (SELECT 1 FROM cte_dwell WHERE cte_dwell.tripid = t.tripid AND cte_dwell.collected_at > t.depart_time_timestamp AND cte_dwell.nxt_collected < t.arrival_time_timestamp)
					AND Elmer.dbo.rgx_find(t.revision_code,'8,',1) = 0
		*/
			UNION ALL SELECT  t.recid,  t.personid,  t.tripnum,				   					  		'no activity time after' AS error_flag
				FROM trip_ref as t JOIN HHSurvey.Trip AS t_next ON t.personid=t_next.personid AND t.tripnum + 1 = t_next.tripnum
				LEFT JOIN HHSurvey.fnVariableLookup('dest_purpose') as v ON  t.dest_purpose = v.code
				WHERE DATEDIFF(Second,  t.depart_time_timestamp, t_next.depart_time_timestamp) < 60 
					AND  t.dest_purpose NOT IN(1,9,33,51,60,61,62,97) AND v.label <> 'Other purpose' AND v.label NOT LIKE 'Missing%'

			/*UNION ALL SELECT t_next.recid, t_next.personid, t_next.tripnum,	   				           'no activity time before' AS error_flag
				FROM trip_ref as t JOIN HHSurvey.Trip AS  t_next ON  t.personid=t_next.personid AND  t.tripnum + 1 = t_next.tripnum
					LEFT JOIN HHSurvey.fnVariableLookup('dest_purpose') as v ON  t.dest_purpose = v.code
				WHERE DATEDIFF(Second,  t.depart_time_timestamp, t_next.depart_time_timestamp) < 60
					AND  t.dest_purpose NOT IN(1,9,33,51,60,61,62,97) AND v.label <> 'Other purpose' AND v.label NOT LIKE 'Missing%'		*/	

			UNION ALL SELECT t_next.recid, t_next.personid, t_next.tripnum,	       				            'same dest as prior' AS error_flag
				FROM trip_ref as t JOIN HHSurvey.Trip AS t_next ON  t.personid=t_next.personid AND t.tripnum + 1 =t_next.tripnum 
					AND t.dest_lat = t_next.dest_lat AND t.dest_lng = t_next.dest_lng

			UNION ALL (SELECT t.recid, t.personid, t.tripnum,					         				     	  'time overlap' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.Trip AS compare_t ON  t.personid=compare_t.personid AND  t.recid <> compare_t.recid
				WHERE 	(compare_t.depart_time_timestamp  BETWEEN DATEADD(Minute, 2, t.depart_time_timestamp) AND DATEADD(Minute, -2, t.arrival_time_timestamp))
					OR	(compare_t.arrival_time_timestamp BETWEEN DATEADD(Minute, 2,  t.depart_time_timestamp) AND DATEADD(Minute, -2,  t.arrival_time_timestamp))
					OR	(t.depart_time_timestamp  BETWEEN DATEADD(Minute, 2, compare_t.depart_time_timestamp) AND DATEADD(Minute, -2, compare_t.arrival_time_timestamp))
					OR	(t.arrival_time_timestamp BETWEEN DATEADD(Minute, 2, compare_t.depart_time_timestamp) AND DATEADD(Minute, -2, compare_t.arrival_time_timestamp)))

	/*		UNION ALL SELECT t.recid, t.personid, t.tripnum,								      'same transit line listed 2x+' AS error_flag
				FROM trip_ref AS t
    			WHERE EXISTS(SELECT count(*) 
								FROM (VALUES(t.transit_line_1),(t.transit_line_2),(t.transit_line_3),(t.transit_line_4),(t.transit_line_5)) AS transitline(member) 
								WHERE member IS NOT NULL and member not in (select flag_value from HHSurvey.NullFlags) AND member <> 0 GROUP BY member HAVING count(*) > 1)
	*/
			UNION ALL SELECT t.recid, t.personid, t.tripnum,	  		   			 		   	       'purpose at odds w/ dest' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid JOIN HHSurvey.Person AS p ON t.personid = p.personid
				WHERE (t.dest_purpose <> 1 and t.dest_is_home = 1) OR (t.dest_purpose NOT IN(9,10,11,14,60) and t.dest_is_work = 1)
					AND h.home_geog.STDistance(p.work_geog) > 500
 
			UNION ALL SELECT t.recid, t.personid, t.tripnum,					                        'missing next trip link' AS error_flag
			FROM trip_ref AS t JOIN HHSurvey.Trip AS t_next ON  t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE ABS(t.dest_geog.STDistance(t_next.origin_geog)) > 500  --500m difference or more

			UNION ALL SELECT t_next.recid, t_next.personid, t_next.tripnum,	              	           'missing prior trip link' AS error_flag
			FROM trip_ref AS t JOIN HHSurvey.Trip AS t_next ON t.personid = t_next.personid AND  t.tripnum + 1 = t_next.tripnum
				WHERE ABS(t.dest_geog.STDistance(t_next.origin_geog)) > 500	--500m difference or more			

			UNION ALL SELECT t.recid, t.personid, t.tripnum,	              	 			 			 '"change mode" purpose' AS error_flag	
				FROM trip_ref AS t JOIN HHSurvey.Trip AS t_next ON t.personid = t_next.personid AND  t.tripnum + 1 = t_next.tripnum
					WHERE t.dest_purpose = 60 AND Elmer.dbo.rgx_find(t_next.modes,'(31|32)',1) = 0 AND Elmer.dbo.rgx_find(t.modes,'(31|32)',1) = 0
					AND t.travelers_total = t_next.travelers_total

			UNION ALL SELECT t.recid, t.personid, t.tripnum,					          		  		'PUDO, no +/- travelers' AS error_flag
				FROM HHSurvey.Trip AS t LEFT JOIN HHSurvey.Trip AS t_next ON  t.personid = t_next.personid	AND  t.tripnum + 1 = t_next.tripnum						
				WHERE  t.dest_purpose = 9 AND ( t.travelers_total = t_next.travelers_total)
					AND NOT (CASE WHEN t.hhmember1 <> t_next.hhmember1 THEN 1 ELSE 0 END +
 		 				  	 CASE WHEN t.hhmember2 <> t_next.hhmember2 THEN 1 ELSE 0 END +
						  	 CASE WHEN t.hhmember3 <> t_next.hhmember3 THEN 1 ELSE 0 END +
						   	 CASE WHEN t.hhmember4 <> t_next.hhmember4 THEN 1 ELSE 0 END +
						   	 CASE WHEN t.hhmember5 <> t_next.hhmember5 THEN 1 ELSE 0 END +
						  	 CASE WHEN t.hhmember6 <> t_next.hhmember6 THEN 1 ELSE 0 END +
						  	 CASE WHEN t.hhmember7 <> t_next.hhmember7 THEN 1 ELSE 0 END +
						  	 CASE WHEN t.hhmember8 <> t_next.hhmember8 THEN 1 ELSE 0 END) > 1

			UNION ALL SELECT t.recid, t.personid, t.tripnum,					  				 	    	   'too long at dest' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.Trip AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					WHERE   (t.dest_purpose IN(6,10,11,14)    		
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
								CASE WHEN t_next.recid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 840)
    					OR  (t.dest_purpose IN(30)      			
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
								CASE WHEN t_next.recid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 240)
   						OR  (t.dest_purpose IN(32,33,50,51,53,54,56,60,61) 	
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
						   		CASE WHEN t_next.recid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 480)  

			UNION ALL SELECT t.recid, t.personid, t.tripnum, 		  				   		          'non-student + school trip' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.Trip as t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum JOIN HHSurvey.person ON t.personid=person.personid 					
				WHERE t.dest_purpose = 6		
					AND (person.student NOT IN(2,3,4) OR person.student IS NULL) AND person.age > 4)

		INSERT INTO HHSurvey.trip_error_flags (recid, personid, tripnum, error_flag)
			SELECT efc.recid, efc.personid, efc.tripnum, efc.error_flag 
			FROM error_flag_compilation AS efc
			WHERE NOT EXISTS (SELECT 1 FROM trip_ref AS t_active WHERE efc.recid = t_active.recid AND t_active.psrc_resolved = 1)
			AND efc.personid = (CASE WHEN @target_personid IS NULL THEN efc.personid ELSE @target_personid END)
			GROUP BY efc.recid, efc.personid, efc.tripnum, efc.error_flag;

		DROP TABLE IF EXISTS #dayends;
	END
	GO

	EXECUTE HHSurvey.generate_error_flags;

