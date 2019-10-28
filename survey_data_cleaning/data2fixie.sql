USE HouseholdTravelSurvey2019
GO
DROP VIEW IF EXISTS HHSurvey.data2fixie;
GO
CREATE VIEW HHSurvey.data2fixie WITH SCHEMABINDING
AS
SELECT t1.recid, t1.personid, t1.hhid, t1.pernum, t1.hhgroup, CASE WHEN EXISTS (SELECT 1 FROM HHSurvey.Trip WHERE Trip.psrc_comment IS NOT NULL AND t1.personid = Trip.personid) THEN 1 ELSE 0 END AS Elevated, 0 AS Seattle,
		t1.tripnum, 
        STUFF(	COALESCE(',' + CAST(ma.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m1.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m2.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m3.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m4.mode_desc AS nvarchar), '') +
				COALESCE(',' + CAST(me.mode_desc AS nvarchar), ''), 1, 1, '') AS modes_desc,
		t1.daynum,	 
		FORMAT(t1.depart_time_timestamp,N'hh\:mm tt','en-US') AS depart_dhm,
		FORMAT(t1.arrival_time_timestamp,N'hh\:mm tt','en-US') AS arrive_dhm,
		ROUND(t1.trip_path_distance,1) AS miles,
		ROUND(t1.speed_mph,1) AS mph, 
		ROUND(t1.dest_geog.STDistance(t1.origin_geog) / 1609.344, 1) AS linear_miles,
		CASE WHEN DATEDIFF(minute, t1.depart_time_timestamp, t1.arrival_time_timestamp) > 0 
				THEN ROUND((t1.dest_geog.STDistance(t1.origin_geog) / 1609.344) / (CAST(DATEDIFF(second, t1.depart_time_timestamp, t1.arrival_time_timestamp) AS decimal) / 3600),1) 
				ELSE -9999 END AS linear_mph,
		STUFF(
				(SELECT ',' + tef.error_flag
					FROM HHSurvey.trip_error_flags AS tef
					WHERE tef.recid = t1.recid
					ORDER BY tef.error_flag DESC
					FOR XML PATH('')), 1, 1, NULL) AS Error,
		CASE WHEN t1.travelers_total = 1 THEN '' ELSE CONCAT(CAST(t1.travelers_total - 1 AS nvarchar),' - ', 
				STUFF(	
					COALESCE(',' + CASE WHEN t1.hhmember1 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember1) THEN RIGHT(CAST(t1.hhmember1 AS nvarchar),2) ELSE NULL END, '') +
					COALESCE(',' + CASE WHEN t1.hhmember2 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember2) THEN RIGHT(CAST(t1.hhmember2 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember3 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember3) THEN RIGHT(CAST(t1.hhmember3 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember4 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember4) THEN RIGHT(CAST(t1.hhmember4 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember5 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember5) THEN RIGHT(CAST(t1.hhmember5 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember6 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember6) THEN RIGHT(CAST(t1.hhmember6 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember7 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember7) THEN RIGHT(CAST(t1.hhmember7 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember8 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember8) THEN RIGHT(CAST(t1.hhmember8 AS nvarchar),2) ELSE NULL END, '') + 
					COALESCE(',' + CASE WHEN t1.hhmember9 <> t1.personid AND NOT EXISTS (SELECT flag_value from HHSurvey.NullFlags WHERE flag_value = t1.hhmember9) THEN RIGHT(CAST(t1.hhmember9 AS nvarchar),2) ELSE NULL END, ''), 
						1, 1, '')) END AS cotravelers,
			CONCAT(t1.o_purpose, '-',tpo.purpose) AS o_purpose, t1.dest_name, CONCAT(t1.d_purpose, '-',tpd.purpose) AS d_purpose, 
			CONCAT(CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) / 60)),'h',RIGHT('00'+CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, CASE WHEN t2.recid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year,t1.arrival_time_timestamp),DATEPART(month,t1.arrival_time_timestamp),DATEPART(day,t1.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t2.depart_time_timestamp END) % 60)),2),'m') AS duration_at_dest,
			CONCAT(CAST(t1.origin_lat AS VARCHAR(20)),', ',CAST(t1.origin_lng AS VARCHAR(20))) AS origin_coord,						 
			CONCAT(CAST(t1.dest_lat AS VARCHAR(20)),', ',CAST(t1.dest_lng AS VARCHAR(20))) AS dest_coord,
			t1.revision_code AS rc, t1.psrc_comment AS elevate_issue
	FROM HHSurvey.trip AS t1 LEFT JOIN HHSurvey.trip as t2 ON t1.personid = t2.personid AND (t1.tripnum+1) = t2.tripnum
		LEFT JOIN HHSurvey.trip_mode AS ma ON t1.mode_acc=ma.mode_id
		LEFT JOIN HHSurvey.trip_mode AS m1 ON t1.mode_1=m1.mode_id
		LEFT JOIN HHSurvey.trip_mode AS m2 ON t1.mode_2=m2.mode_id
		LEFT JOIN HHSurvey.trip_mode AS m3 ON t1.mode_3=m3.mode_id
		LEFT JOIN HHSurvey.trip_mode AS m4 ON t1.mode_4=m4.mode_id
		LEFT JOIN HHSurvey.trip_mode AS me ON t1.mode_egr=me.mode_id
		LEFT JOIN HHSurvey.trip_purpose AS tpo ON t1.o_purpose=tpo.purpose_id
		LEFT JOIN HHSurvey.trip_purpose AS tpd ON t1.d_purpose=tpd.purpose_id
	WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef2 WHERE t1.personid = tef2.personid);
GO

DROP VIEW IF EXISTS HHSurvey.pass2trip;
GO
CREATE VIEW HHSurvey.pass2trip WITH SCHEMABINDING
AS
SELECT [recid]
			,[hhid]
			,[personid]
			,[pernum]
			,[tripid]
			,[tripnum]
			,[traveldate]
			,[daynum]
			,[dayofweek]
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
			,[origin_name]
			,[origin_lat]
			,[origin_lng]
			,[dest_name]
			,[dest_lat]
			,[dest_lng]
			,[trip_path_distance]
			,[google_duration]
			,[reported_duration]
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
			,[o_purpose]
			,[d_purpose]
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
			,[psrc_comment]
			,[psrc_resolved]
FROM HHSurvey.Trip;
GO
CREATE UNIQUE CLUSTERED INDEX PK_pass2trip ON HHSurvey.pass2trip(recid);



--create separate views for FixieUI major record divisions

	DROP VIEW IF EXISTS HHSurvey.person_rm_seattle
	GO
	CREATE VIEW HHSurvey.person_rm_seattle WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode JOIN HHSurvey.household AS h ON h.hhid = p.hhid
	WHERE NOT EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND tef.error_flag LIKE 'missing % trip link') AND p.hhgroup=1 AND h.cityofseattle = 1
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL OR t.psrc_resolved IS NOT NULL))
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid)
		AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid);
	GO


	DROP VIEW IF EXISTS HHSurvey.person_rm_else
	GO
	CREATE VIEW HHSurvey.person_rm_else WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode JOIN HHSurvey.household AS h ON h.hhid = p.hhid
	WHERE NOT EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND tef.error_flag LIKE 'missing % trip link') AND p.hhgroup=1 AND h.cityofseattle <> 1
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL OR t.psrc_resolved IS NOT NULL))
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid)
		AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid);
	GO


	DROP VIEW IF EXISTS HHSurvey.person_rs
	GO
	CREATE VIEW HHSurvey.person_rs WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE NOT EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND tef.error_flag LIKE 'missing % trip link') AND p.hhgroup=2
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL OR t.psrc_resolved IS NOT NULL))
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid)
		AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid);
	GO


	DROP VIEW IF EXISTS HHSurvey.person_elev
	GO
	CREATE VIEW HHSurvey.person_elev WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE (Exists (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND t.psrc_comment IS NOT NULL AND t.psrc_resolved IS NULL)
		    OR Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND (tef.error_flag LIKE 'missing % trip link' OR tef.error_flag IN('time overlap')))
			OR Exists (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid))
		AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid);
	GO

	DROP VIEW IF EXISTS HHSurvey.person_by_error;
	GO
	CREATE VIEW HHSurvey.person_by_error WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef JOIN HHSurvey.Trip AS t ON tef.recid = t.recid WHERE tef.personid = p.personid AND tef.error_flag IN('mode_1 missing','too slow','purpose missing') AND t.psrc_comment IS NULL AND t.psrc_resolved IS NULL)
		AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid);
	--		AND NOT EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND tef.error_flag LIKE 'missing % trip link' );
	GO

	DROP VIEW IF EXISTS HHSurvey.person_all;
	GO
	CREATE VIEW HHSurvey.person_all WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid);
	GO


/* 	DROP VIEW IF EXISTS HHSurvey.person_by_error;
	GO
	CREATE VIEW HHSurvey.person_by_error AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE EXISTS (SELECT 1 FROM HHSurvey.Trip AS t JOIN HHSurvey.trip_error_flags AS tef ON t.recid = tef.recid 
				  	WHERE p.personid = t.personid AND tef.error_flag = 'excessive speed' AND CAST(DATEDIFF(second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric) Between 0 AND 60)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid);
	GO */	

	DROP PROCEDURE IF EXISTS HHSurvey.find_your_family;
	GO
	CREATE PROCEDURE HHSurvey.find_your_family 
		@target_recid numeric NULL --provide recid of reference member

	AS BEGIN
	SET NOCOUNT OFF;
	WITH cte_ref AS
			(SELECT t0.hhid, t0.depart_time_timestamp, t0.arrival_time_timestamp, t0.pernum, t0.driver
				FROM HHSurvey.Trip AS t0 
				WHERE t0.recid = @target_recid),
		 cte_mobile AS(
			SELECT 	t3.hhid, t3.pernum, ac1.agedesc,
					'enroute' AS member_status, 
					CONCAT(CAST(t3.origin_lat AS NVARCHAR(20)),', ',CAST(t3.origin_lng AS NVARCHAR(20))) AS prior_location,
					CONCAT(CAST(t3.dest_lat AS NVARCHAR(20)),', ',CAST(t3.dest_lng AS NVARCHAR(20))) AS next_destination, 
					CONCAT((CASE WHEN t3.pernum = cte_ref.pernum THEN 'reference person - ' ELSE '' END),
					 	CASE WHEN t3.driver = 1 THEN 'driver' 	
						 	 WHEN EXISTS (SELECT 1 FROM HHSurvey.AutoModes AS am WHERE t3.mode_1 = am.mode_id) THEN 'passenger' 
						 	 WHEN EXISTS (SELECT 1 FROM HHSurvey.TransitModes AS tm WHERE t3.mode_1 = tm.mode_id) THEN 'transit rider'
							 WHEN t3.mode_1 = 1 THEN 'pedestrian'
							 ELSE 'other' END) AS rider_status
				FROM HHSurvey.Trip AS t3
				JOIN cte_ref ON t3.hhid = cte_ref.hhid
				JOIN HHSurvey.Person AS p1 ON t3.personid = p1.personid LEFT JOIN HHSurvey.AgeCategories AS ac1 ON ac1.AgeCode = p1.age
				WHERE ((cte_ref.depart_time_timestamp BETWEEN t3.depart_time_timestamp AND t3.arrival_time_timestamp) 
						OR (cte_ref.arrival_time_timestamp BETWEEN t3.depart_time_timestamp AND t3.arrival_time_timestamp))),
		 cte_static AS
			(SELECT t1.hhid, t1.pernum, ac2.agedesc,
					'at rest' AS member_status, 
					CONCAT(CAST(t1.dest_lat AS NVARCHAR(20)),', ',CAST(t1.dest_lng AS NVARCHAR(20))) AS prior_location,
					CONCAT(CAST(t2.dest_lat AS NVARCHAR(20)),', ',CAST(t2.dest_lng AS NVARCHAR(20))) AS next_destination,
					'n/a' AS rider_status
				FROM HHSurvey.Trip AS t1
				LEFT JOIN HHsurvey.Trip AS t2 ON t1.personid = t2.personid AND t1.tripnum + 1 = t2.tripnum
				JOIN cte_ref ON t1.hhid = cte_ref.hhid AND NOT EXISTS (SELECT 1 FROM cte_mobile WHERE cte_mobile.pernum = t1.pernum)
				JOIN HHSurvey.Person AS p2 ON t2.personid = p2.personid LEFT JOIN HHSurvey.AgeCategories AS ac2 ON ac2.AgeCode = p2.age
				WHERE (cte_ref.depart_time_timestamp > t1.arrival_time_timestamp AND cte_ref.arrival_time_timestamp < t2.depart_time_timestamp)
					OR (cte_ref.depart_time_timestamp > t1.arrival_time_timestamp AND t2.depart_time_timestamp IS NULL)
		)
	SELECT * FROM cte_mobile UNION SELECT * FROM cte_static
	ORDER BY pernum;
	END
	GO

	DROP PROCEDURE IF EXISTS HHSurvey.trace_this_trip;
	GO
	CREATE PROCEDURE HHSurvey.trace_this_trip
		@target_recid numeric NULL --provide recid of reference member
	
	AS BEGIN
	SET NOCOUNT OFF;
	WITH cte AS
	(SELECT t.tripid, t.recid FROM HHSurvey.Trip AS t WHERE t.recid = @target_recid)
	SELECT c.traceid, CONVERT(NVARCHAR, c.collected_at, 22) AS timepoint, Round(DATEDIFF(Second, c.collected_at, cnxt.collected_at)/60,1) AS minutes_btwn, ROUND(c.point_geog.STDistance(cnxt.point_geog)/1609,2) AS miles_btwn, CONCAT(CAST(c.lat AS VARCHAR(20)),', ',CAST(c.lng AS VARCHAR(20))) AS coords
	FROM HHSurvey.Trace AS c JOIN cte ON c.tripid = cte.tripid LEFT JOIN HHSurvey.Trace AS cnxt ON c.traceid + 1 = cnxt.traceid AND c.tripid = cnxt.tripid
	WHERE cte.recid = @target_recid
	ORDER BY c.collected_at ASC;
	END
	GO

	DROP PROCEDURE IF EXISTS HHSurvey.examine_link_ingredients;
	GO
	CREATE PROCEDURE HHSurvey.examine_link_ingredients
		@target_recid numeric NULL --provide recid of reference member
	
	AS BEGIN
	SET NOCOUNT OFF;
	WITH cte AS
	(SELECT tid0.personid, tid0.trip_link FROM HHSurvey.trip_ingredients_done AS tid0 WHERE tid0.recid = @target_recid)
	SELECT tid.recid, tid.personid, tid.hhid, tid.tripnum, tid.daynum, tid.mode_1,
		FORMAT(tid.depart_time_timestamp,N'hh\:mm tt','en-US') AS depart_dhm,
		FORMAT(tid.arrival_time_timestamp,N'hh\:mm tt','en-US') AS arrive_dhm,
		ROUND(tid.trip_path_distance,1) AS miles,
		ROUND(tid.speed_mph,1) AS mph, 
		CONCAT(tid.o_purpose, '-',tpo.purpose) AS o_purpose, tid.dest_name, CONCAT(tid.d_purpose, '-',tpd.purpose) AS d_purpose, 
			CONCAT(CONVERT(varchar(30), (DATEDIFF(mi, tid.arrival_time_timestamp, t2.depart_time_timestamp) / 60)),'h',RIGHT('00'+CONVERT(varchar(30), (DATEDIFF(mi, tid.arrival_time_timestamp, CASE WHEN t2.recid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year,tid.arrival_time_timestamp),DATEPART(month,tid.arrival_time_timestamp),DATEPART(day,tid.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t2.depart_time_timestamp END) % 60)),2),'m') AS duration_at_dest,
			CONCAT(CAST(tid.origin_lat AS VARCHAR(20)),', ',CAST(tid.origin_lng AS VARCHAR(20))) AS origin_coord,						 
			CONCAT(CAST(tid.dest_lat AS VARCHAR(20)),', ',CAST(tid.dest_lng AS VARCHAR(20))) AS dest_coord,
			tid.revision_code AS rc, tid.psrc_comment AS elevate_issue
		FROM HHSurvey.trip_ingredients_done AS tid 
			JOIN cte ON tid.trip_link = cte.trip_link AND tid.personid = cte.personid
			LEFT JOIN HHSurvey.trip_ingredients_done as t2 ON tid.personid = t2.personid AND (tid.tripnum+1) = t2.tripnum
			LEFT JOIN HHSurvey.trip_purpose AS tpo ON tid.o_purpose=tpo.purpose_id
			LEFT JOIN HHSurvey.trip_purpose AS tpd ON tid.d_purpose=tpd.purpose_id
	ORDER BY tid.tripnum ASC;
	END
	GO

	DROP PROCEDURE IF EXISTS HHSurvey.link_trip_click;
	GO
	CREATE PROCEDURE HHSurvey.link_trip_click
		@ref_recid int = NULL
	
		AS BEGIN
	SET NOCOUNT OFF;
	DECLARE @recid_list nvarchar(255) = NULL
	IF (SELECT HHSurvey.RgxFind(HHSurvey.TRIM(t.psrc_comment),'^(\d+,?)+$',1) FROM HHSurvey.Trip AS t WHERE t.recid = @ref_recid) = 1
		BEGIN
		SELECT @recid_list = (SELECT HHSurvey.TRIM(t.psrc_comment) FROM HHSurvey.Trip AS t WHERE t.recid = @ref_recid)
		EXECUTE HHSurvey.link_trip_via_id @recid_list;
		SELECT @recid_list = NULL, @ref_recid = NULL
		END
	END
	GO
	

	DROP VIEW IF EXISTS HHSurvey.Person_Neil
	DROP VIEW IF EXISTS HHSurvey.person_Grant
	DROP VIEW IF EXISTS HHSurvey.person_Ben
	DROP VIEW IF EXISTS HHSurvey.person_Alex
	DROP VIEW IF EXISTS HHSurvey.Person_Mike
	GO

	--alternate view for Mike
	CREATE VIEW HHSurvey.person_Mike WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx JOIN HHSurvey.Trip AS t ON tefx.recid = t.recid WHERE p.personid = t.personid AND t.psrc_comment LIKE '%ADD %')
	GO  

	CREATE VIEW HHSurvey.person_Alex WITH SCHEMABINDING AS
	SELECT TOP 40 PERCENT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag IN('purpose missing'))
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid);
	GO

	CREATE VIEW HHSurvey.person_Ben WITH SCHEMABINDING AS
	SELECT TOP 70 PERCENT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag IN('purpose missing'))
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Alex AS pa WHERE pa.personid = p.personid);
	GO

	CREATE VIEW HHSurvey.person_Grant WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE NOT EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND (tef.error_flag LIKE 'missing % trip link'))
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL))
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid)
			AND EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Alex AS pa WHERE pa.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Ben AS pb WHERE pb.personid = p.personid);
	GO

	CREATE VIEW HHSurvey.person_Neil WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE NOT Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND (tef.error_flag LIKE 'missing % trip link'))
		AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Alex AS pa WHERE pa.personid = p.personid) 
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Grant AS pg WHERE pg.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Ben AS pb WHERE pb.personid = p.personid);
	GO

	/*
	CREATE VIEW HHSurvey.person_Mike WITH SCHEMABINDING AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx JOIN HHSurvey.Trip AS t ON tefx.recid = t.recid WHERE p.personid = tefx.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Alex AS pa WHERE pa.personid = p.personid) 
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Grant AS pg WHERE pg.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Neil AS pn WHERE pn.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Ben AS pb WHERE pb.personid = p.personid);
	GO  */




	      SELECT 'Alex: ', count(*) FROM HHSurvey.person_Alex
	UNION SELECT 'Ben: ', count(*) FROM HHSurvey.person_Ben
	UNION SELECT 'Grant: ', count(*) FROM HHSurvey.person_Grant
	UNION SELECT 'Neil: ', count(*) FROM HHSurvey.person_Neil
	UNION SELECT 'Mike: ', count(*) FROM HHSurvey.person_Mike