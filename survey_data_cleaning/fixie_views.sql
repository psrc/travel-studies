/* Defines the Views necessary to operate FixieUI  */

USE hhts_cleaning
GO

	DROP VIEW IF EXISTS HHSurvey.data2fixie;  --The primary subform view in FixieUI
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
				CONCAT(t1.origin_purpose, '-',tpo.purpose) AS origin_purpose, t1.dest_name, CONCAT(t1.dest_purpose, '-',tpd.purpose) AS dest_purpose, 
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
			LEFT JOIN HHSurvey.trip_purpose AS tpo ON t1.origin_purpose=tpo.purpose_id
			LEFT JOIN HHSurvey.trip_purpose AS tpd ON t1.dest_purpose=tpd.purpose_id;
	GO

	DROP VIEW IF EXISTS HHSurvey.pass2trip;  --View used to edit the trip table (since direct connection isn't possible)
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
		/*		,[completed_at]
				,[revised_at]
				,[revised_count]
		*/		,[svy_complete]
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
				,[origin_purpose]
				,[dest_purpose]
				,[mode_1]
		/*		,[mode_2]
				,[mode_3]
				,[mode_4]
				,[driver]
		*/		,[pool_start]
				,[change_vehicles]
		/*		,[park_ride_area_start]
				,[park_ride_area_end]
				,[park_ride_lot_start]
				,[park_ride_lot_end]
		*/		,[toll]
				,[toll_pay]
		--		,[taxi_type]
				,[taxi_pay]
		/*		,[bus_type]
				,[bus_pay]
				,[bus_cost_dk]
				,[ferry_type]
				,[ferry_pay]
				,[ferry_cost_dk]
				,[air_type]
				,[air_pay]
				,[airfare_cost_dk]
		*/		,[mode_acc]
				,[mode_egr]
		/*		,[park]
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
		*/		,[speed_mph]
				,[psrc_comment]
				,[psrc_resolved]
	FROM HHSurvey.Trip;
	GO
	CREATE UNIQUE CLUSTERED INDEX PK_pass2trip ON HHSurvey.pass2trip(recid);

-- All-inclusive person-level views for FixieUI (only for reference)

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


-- Person-level views for FixieUI Main forms, separated by staff so as to avoid editing conflicts

	DROP VIEW IF EXISTS HHSurvey.Person_Mary
		DROP VIEW IF EXISTS HHSurvey.person_Abdi
		DROP VIEW IF EXISTS HHSurvey.person_Parastoo
		DROP VIEW IF EXISTS HHSurvey.person_Polina
		DROP VIEW IF EXISTS HHSurvey.Person_Mike
		GO
/*
		--alternate view for Mike
		CREATE VIEW HHSurvey.person_Mike WITH SCHEMABINDING AS
		SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode 
		WHERE --Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx JOIN HHSurvey.Trip AS t ON tefx.recid = t.recid WHERE p.personid = tefx.personid AND tefx.error_flag IN('time overlap','long dwell'));
		p.personid IN(19101581902,19101888901,19102296902,19102536303,19103463902);
		GO  
	
		CREATE VIEW HHSurvey.person_Grant WITH SCHEMABINDING AS
		SELECT TOP 50 PERCENT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
		WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag IN('ends day, not home'))
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid);
		GO */

		
		--alternate view for Mike
		CREATE VIEW HHSurvey.person_Mike WITH SCHEMABINDING AS
		SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode 
		WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag = 'PUDO, no +/- travelers')
			AND Exists(SELECT 1 FROM HHSurvey.pudo_explain AS pe WHERE pe.personid = p.personid AND pe.theory = 'PUDOee, should have non-PUDO purpose');
		GO  

		CREATE VIEW HHSurvey.person_Polina WITH SCHEMABINDING AS
		SELECT TOP 50 PERCENT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
		WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag = 'PUDO, no +/- travelers')
			AND Exists(SELECT 1 FROM HHSurvey.pudo_explain AS pe WHERE pe.personid = p.personid AND pe.theory = 'Rulesy-inserted trip (after)');
		GO

		CREATE VIEW HHSurvey.person_Parastoo WITH SCHEMABINDING AS
		SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
		WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag = 'PUDO, no +/- travelers')
		AND Exists (SELECT 1 FROM HHSurvey.pudo_explain AS pe WHERE p.personid = pe.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid)
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Polina AS pa WHERE pa.personid = p.personid);
		GO 

		CREATE VIEW HHSurvey.person_Abdi WITH SCHEMABINDING AS
		SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
		WHERE Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid AND tefx.error_flag IN('PUDO, no +/- travelers'))
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid)
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Polina AS pa WHERE pa.personid = p.personid)
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Parastoo AS pb WHERE pb.personid = p.personid);
		GO

		CREATE VIEW HHSurvey.person_Mary WITH SCHEMABINDING AS
		SELECT p.personid, p.hhid AS hhid, p.pernum, ac.agedesc AS Age, 
			CASE WHEN p.worker  = 0 THEN 'No' ELSE 'Yes' END AS Works, 
			CASE WHEN p.student = 1 THEN 'No' WHEN student = 2 THEN 'PT' WHEN p.student = 3 THEN 'FT' ELSE 'No' END AS Studies, 
			CASE WHEN p.hhgroup = 1 THEN 'rMove' WHEN p.hhgroup = 2 THEN 'rSurvey' ELSE 'n/a' END AS HHGroup
		FROM HHSurvey.person AS p INNER JOIN HHSurvey.AgeCategories AS ac ON p.age = ac.agecode
		WHERE NOT Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.personid = p.personid AND (tef.error_flag LIKE 'missing % trip link'))
			AND Exists (SELECT 1 FROM HHSurvey.trip_error_flags AS tefx WHERE p.personid = tefx.personid)
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Mike AS pm WHERE pm.personid = p.personid)
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Polina AS pa WHERE pa.personid = p.personid) 
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Parastoo AS pg WHERE pg.personid = p.personid)
			AND NOT EXISTS (SELECT 1 FROM HHSurvey.person_Abdi AS pb WHERE pb.personid = p.personid);
		GO