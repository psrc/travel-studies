USE HouseholdTravelSurvey2019
GO
DROP VIEW IF EXISTS HHSurvey.data2fixie;
GO
CREATE VIEW HHSurvey.data2fixie
AS
SELECT t1.personid, t1.hhid, t1.pernum, t1.hhgroup, CASE WHEN EXISTS (SELECT 1 FROM trip WHERE trip.psrc_comment IS NOT NULL AND t1.personid = trip.personid) THEN 1 ELSE 0 END AS Elevated, 0 AS Seattle,
		t1.tripnum, t1.recid, 
        STUFF(	COALESCE(',' + CAST(ma.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m1.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m2.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m3.mode_desc AS nvarchar), '') + 
				COALESCE(',' + CAST(m4.mode_desc AS nvarchar), '') +
				COALESCE(',' + CAST(me.mode_desc AS nvarchar), ''), 1, 1, '') AS modes_desc,
		CONCAT(CAST(t1.daynum AS nvarchar),' ',CASE WHEN DATEDIFF(hh, t1.depart_time_timestamp, t1.arrival_time_timestamp)/24 > .99 THEN CONCAT('+ ',DATEDIFF(hh, t1.depart_time_timestamp, t1.arrival_time_timestamp)/24) ELSE NULL END) AS daynum,	 
		FORMAT(t1.depart_time_timestamp,N'hh\:mm tt','en-US') AS depart_dhm,
		FORMAT(t1.arrival_time_timestamp,N'hh\:mm tt','en-US') AS arrive_dhm,
		ROUND(t1.trip_path_distance,1) AS miles,
		ROUND(t1.speed_mph,1) AS mph, 
		ROUND(t1.dest_geom.STDistance(t1.origin_geom) * 69.171, 1) AS linear_miles,
		CASE WHEN DATEDIFF(minute, t1.depart_time_timestamp, t1.arrival_time_timestamp) > 0 
				THEN ROUND(t1.dest_geom.STDistance(t1.origin_geom) * 69.171 / (CAST(DATEDIFF(second, t1.depart_time_timestamp, t1.arrival_time_timestamp) AS decimal) / 3600),1) 
				ELSE -9999 END AS linear_mph,
		STUFF(
				(SELECT ',' + tef.error_flag
					FROM trip_error_flags AS tef
					WHERE tef.recid = t1.recid
					ORDER BY error_flag DESC
					FOR XML PATH('')), 1, 1, NULL) AS Error,
		CASE WHEN t1.travelers_total > 1 THEN CONCAT(CAST(t1.travelers_total - 1 AS nvarchar) ,' - ', 
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
						1, 1, '')) ELSE '' END AS cotravelers,
			CONCAT(t1.o_purpose, '-',tpo.purpose) AS o_purpose, t1.dest_name, CONCAT(t1.d_purpose, '-',tpd.purpose) AS d_purpose, 
			CONCAT(CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) / 60)),'h',RIGHT('00'+CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, CASE WHEN t2.recid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year,t1.arrival_time_timestamp),DATEPART(month,t1.arrival_time_timestamp),DATEPART(day,t1.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t2.depart_time_timestamp END) % 60)),2),'m') AS duration_at_dest,
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
	WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags WHERE t1.personid=trip_error_flags.personid);
GO

DROP VIEW IF EXISTS HHSurvey.pass2trip;
GO
CREATE VIEW HHSurvey.pass2trip
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
			,[origin_address]
			,[origin_lat]
			,[origin_lng]
			,[dest_name]
			,[dest_address]
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

USE HouseholdTravelSurvey2019
GO

--create separate views for FixieUI major record divisions

	DROP VIEW IF EXISTS HHSurvey.person_rm_seattle
	GO
	CREATE VIEW HHSurvey.person_rm_seattle AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode JOIN HHSurvey.household AS h ON h.hhid = p.hhid
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid) AND p.hhgroup=1 AND h.cityofseattle = 1
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL OR t.psrc_resolved IS NOT NULL));
	GO

	DROP VIEW IF EXISTS HHSurvey.person_rm_else
	GO
	CREATE VIEW HHSurvey.person_rm_else AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode JOIN HHSurvey.household AS h ON h.hhid = p.hhid
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid) AND p.hhgroup=1 AND h.cityofseattle <> 1
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL OR t.psrc_resolved IS NOT NULL));
	GO

	DROP VIEW IF EXISTS HHSurvey.person_rs
	GO
	CREATE VIEW HHSurvey.person_rs AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid) AND p.hhgroup=2
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND (t.psrc_comment IS NOT NULL OR t.psrc_resolved IS NOT NULL));
	GO

	DROP VIEW IF EXISTS HHSurvey.person_elev
	GO
	CREATE VIEW HHSurvey.person_elev AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE (Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid)
		OR Exists (SELECT 1 FROM HHSurvey.hh_error_flags AS hef WHERE hef.hhid = p.hhid))
		AND Exists (SELECT 1 FROM HHSurvey.Trip AS t WHERE p.personid = t.personid AND t.psrc_comment IS NOT NULL);
	GO

/* 	DROP VIEW IF EXISTS HHSurvey.person_by_error;
	GO
	CREATE VIEW HHSurvey.person_by_error AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND tef.error_flag IN('too slow','lone trip'))
	    AND (Not Exists (SELECT 1 FROM Sandbox.dbo.zipcode_wgs as zipwgs WHERE zipwgs.geom.STIntersects(t.dest_geom)=1) 
   			 OR Not Exists (SELECT 1 FROM Sandbox.dbo.zipcode_wgs as zipwgs WHERE zipwgs.geom.STIntersects(t.origin_geom)=1));
	GO */

	DROP VIEW IF EXISTS HHSurvey.person_by_error;
	GO
	CREATE VIEW HHSurvey.person_by_error AS
	SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
		CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
		CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
		CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
	FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
	WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND tef.error_flag IN('too long at dest'));
	GO	