DROP VIEW IF EXISTS data2toolsie_hh;
GO
CREATE VIEW data2toolsie_hh
AS
SELECT 
	p.personid, 
	Concat(CASE WHEN p.worker = 1 THEN 'Wrk ' ELSE '' END, CASE WHEN p.student=2 THEN 'Std PT ' WHEN p.student=3 THEN 'Std FT' ELSE '' END) AS Commute, 
	ad.age_desc,
	h.reported_lat AS home_lat, h.reported_lng AS home_lng 
	FROM person AS p 
		JOIN age_desc AS ad ON p.age = ad.age_code 
		JOIN household AS h ON p.hhid = h.hhid
		JOIN trip AS t1 ON p.hhid = t1.hhid; 
GO

DROP VIEW IF EXISTS data2toolsie_t;
GO
CREATE VIEW data2toolsie_t 
AS
SELECT 	t1.personid, t1.hhid,
		t1.tripnum, t1.tripid,
        STUFF(	COALESCE(',' + tmacc.mode_desc, '') +
				COALESCE(',' + tm1.mode_desc, '') + 
				COALESCE(',' + tm2.mode_desc, '') + 
				COALESCE(',' + tm3.mode_desc, '') + 
				COALESCE(',' + tm4.mode_desc, '') + 
				COALESCE(',' + tmegr.mode_desc, ''), 1, 1, '') AS modes_desc, t1.depart_time_timestamp,
		LEFT(CONVERT(time(0), t1.depart_time_timestamp, 108), 5) AS depart_hhmm, CONCAT(CAST(ROUND(t1.speed_mph,1) AS NVARCHAR(10)),'mph') AS speed, 
		STUFF(	COALESCE(',' + RIGHT(CAST(t1.hhmember1 AS nvarchar),2), '') +
				COALESCE(',' + RIGHT(CAST(t1.hhmember2 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember3 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember4 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember5 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember6 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember7 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember8 AS nvarchar),2), '') + 
				COALESCE(',' + RIGHT(CAST(t1.hhmember9 AS nvarchar),2), ''), 1, 1, '') AS hhmemembers,
		'' AS dest_name, '' AS dest_purpose, '' AS activity_duration_hhmm, t1.origin_lat AS lat, t1.origin_lng AS lng, 0 as dest, 'USA' AS country, 'WA' AS state, t1.dest_city AS city
		FROM trip AS t1
		LEFT JOIN trip_mode AS tmacc ON t1.mode_acc = tmacc.mode_id 
		LEFT JOIN trip_mode AS tm1 ON t1.mode_1 = tm1.mode_id
		LEFT JOIN trip_mode AS tm2 ON t1.mode_2 = tm2.mode_id
		LEFT JOIN trip_mode AS tm3 ON t1.mode_3 = tm3.mode_id
		LEFT JOIN trip_mode AS tm4 ON t1.mode_4 = tm4.mode_id
		LEFT JOIN trip_mode AS tmegr ON t1.mode_egr = tmegr.mode_id 
		WHERE t1.hhgroup = 2 
UNION ALL
SELECT 	t1.personid, t1.hhid,
		t1.tripnum, t1.tripid, '' AS modes_desc, '' AS depart_time_timestamp,'' AS depart_hhmm, '' AS speed, '' AS hhmemembers,
		t1.dest_name, tp.purpose AS dest_purpose, 
		CONCAT(CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) / 60)),'hr',RIGHT('00'+CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) % 60)),2),'min') AS duration_at_dest,
		t1.dest_lat AS lat, t1.dest_lng AS lng, 1 AS dest, 'USA' AS country, 'WA' AS state, t1.dest_city AS city
		FROM trip AS t1
			LEFT JOIN trip as t2 ON t1.personid = t2.personid AND (t1.tripnum+1) = t2.tripnum
			JOIN trip_purpose AS tp ON t1.dest_purpose = tp.purpose_id
		WHERE t1.hhgroup = 2;
GO

DROP VIEW IF EXISTS data2frontend;
GO
CREATE VIEW data2frontend WITH SCHEMABINDING
AS
SELECT t1.personid, t1.hhid,
		t1.tripnum, 
        STUFF(	COALESCE(',' + CAST(t1.mode_acc AS nvarchar), '') + 
				COALESCE(',' + CAST(t1.mode_1 AS nvarchar), '') + 
				COALESCE(',' + CAST(t1.mode_2 AS nvarchar), '') + 
				COALESCE(',' + CAST(t1.mode_3 AS nvarchar), '') + 
				COALESCE(',' + CAST(t1.mode_4 AS nvarchar), '') +
				COALESCE(',' + CAST(t1.mode_egr AS nvarchar), ''), 1, 1, '') AS modes_desc, 
		FORMAT(t1.depart_time_timestamp,N'dd- hh\:mm tt','en-US') AS depart_dhm, 
		ROUND(t1.speed_mph,1) AS mph, 
		ROUND(t1.trip_path_distance,1) AS miles,
		FORMAT(t1.arrival_time_timestamp,N'dd- hh\:mm tt','en-US') AS arrive_dhm,
		CASE WHEN tef.error_flag IS NOT NULL THEN tef.error_flag ELSE '' END AS error,
		CASE WHEN t1.travelers_total > 1 THEN CONCAT(CAST(t1.travelers_total - 1 AS nvarchar) ,' - ', 
				STUFF(	COALESCE(',' + CASE WHEN t1.hhmember1 <> t1.personid THEN RIGHT(CAST(t1.hhmember1 AS nvarchar),2) ELSE NULL END, '') +
				COALESCE(',' + CASE WHEN t1.hhmember2 <> t1.personid THEN RIGHT(CAST(t1.hhmember2 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember3 <> t1.personid THEN RIGHT(CAST(t1.hhmember3 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember4 <> t1.personid THEN RIGHT(CAST(t1.hhmember4 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember5 <> t1.personid THEN RIGHT(CAST(t1.hhmember5 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember6 <> t1.personid THEN RIGHT(CAST(t1.hhmember6 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember7 <> t1.personid THEN RIGHT(CAST(t1.hhmember7 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember8 <> t1.personid THEN RIGHT(CAST(t1.hhmember8 AS nvarchar),2) ELSE NULL END, '') + 
				COALESCE(',' + CASE WHEN t1.hhmember9 <> t1.personid THEN RIGHT(CAST(t1.hhmember9 AS nvarchar),2) ELSE NULL END, ''), 1, 1, '')) ELSE '' END AS cotravelers,
			t1.dest_name, tp.purpose AS dest_purpose, 
			CONCAT(CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) / 60)),'h',RIGHT('00'+CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) % 60)),2),'m') AS activity_duration_hhmm,
			t1.revision_code AS rc
	FROM Mike.trip AS t1 LEFT JOIN Mike.trip as t2 ON t1.personid = t2.personid AND (t1.tripnum+1) = t2.tripnum
	LEFT JOIN Mike.trip_purpose AS tp ON t1.dest_purpose=tp.purpose_id
	LEFT JOIN Mike.trip_error_flags AS tef ON t1.tripid=tef.tripid
	WHERE EXISTS (SELECT 1 FROM Mike.trip_error_flags AS tef WHERE t1.personid=tef.personid);
GO
