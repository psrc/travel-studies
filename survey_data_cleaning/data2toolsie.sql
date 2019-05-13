DROP VIEW IF EXISTS data2toolsie_hh;
DROP VIEW IF EXISTS data2toolsie_t;
GO
/*
CREATE VIEW data2toolsie_hh
AS
 SELECT 
	p.personid, 
	Concat(CASE WHEN p.worker = 1 THEN 'Wrk ' ELSE '' END, CASE WHEN p.student=2 THEN 'Std PT ' WHEN p.student=3 THEN 'Std FT' ELSE '' END) AS Commute, 
	ad.age_desc 
	h.reported_lat AS home_lat, h.reported_lng AS home_lng, 
	p.work_lat, p.work_lng, 
	p.school_loc_lat AS school_lat, p.school_loc_lng AS school_lng,
	FROM person AS p JOIN age_desc AS ad ON p.age = ad.age_code 
	WHERE p.hhid = LEFT(t.personid,8) ORDER BY p.age DESC; 
GO
*/
CREATE VIEW data2toolsie_t
AS
SELECT 	t1.personid, t1.hhid,
		t1.tripnum, t1.modes, LEFT(CONVERT(time(0), t1.depart_time_timestamp, 108), 5) AS depart_hhmm, t1.speed_mph, 
							STUFF(	COALESCE(',' + RIGHT(CAST(t1.hhmember1 AS nvarchar),2), '') +
									COALESCE(',' + RIGHT(CAST(t1.hhmember2 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember3 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember4 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember5 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember6 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember7 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember8 AS nvarchar),2), '') + 
									COALESCE(',' + RIGHT(CAST(t1.hhmember9 AS nvarchar),2), ''), 1, 1, '') AS hhmemembers,
		t1.dest_name, t1.dest_purpose, CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) / 60)) + ':' + RIGHT('00'+CONVERT(varchar(30), (DATEDIFF(mi, t1.arrival_time_timestamp, t2.depart_time_timestamp) % 60)),2) AS activity_duration_hhmm, t1.dest_lat, t1.dest_lng
		FROM trip AS t1
			JOIN trip as t2 ON t1.personid = t2.personid AND (t1.tripnum+1) = t2.tripnum
		WHERE t1.hhgroup = 2 ;
GO