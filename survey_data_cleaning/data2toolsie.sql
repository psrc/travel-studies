DROP VIEW IF EXISTS data2toolsie;
GO
CREATE VIEW data2toolsie
AS
SELECT 	t1.hhid, t1.personid, age.agedesc, p.worker, p.student, p.education, p.license, 
		h.reported_lat AS home_lat, h.reported_lng AS home_lng, 
		p.work_lat, p.work_lng, 
		p.school_loc_lat AS school_lat, p.school_loc_lng AS school_lng,
		t1.tripid, t1.tripnum, t1.depart_time_timestamp, t1.arrival_time_timestamp, t1.mode_1, t1.mode_2, t1.mode_3, t1.mode_4, t1.driver, t1.origin_name, t1.dest_name, t1.origin_purpose, t1.dest_purpose, t1.dest_lat, t1.dest_lng, t1.origin_lat, t1.origin_lng, t1.trip_path_distance, t1.google_duration, t1.travelers_total, t1.dest_is_home, t1.dest_is_work, t1.recid, 
		t0.tripid AS prev_tripid, t0.tripnum AS prev_tripnum, t0.depart_time_timestamp AS prev_depart_time_timestamp, t0.arrival_time_timestamp AS prev_arrival_time_timestamp, t0.mode_1 AS prev_mode_1, t0.mode_2 AS prev_mode_2, t0.mode_3 AS prev_mode_3, t0.mode_4 AS prev_mode_4, t0.driver AS prev_driver, t0.origin_name AS prev_origin_name, t0.dest_name AS prev_dest_name, t0.origin_purpose AS prev_origin_purpose, t0.dest_purpose AS prev_dest_purpose, t0.dest_lat AS prev_dest_lat, t0.dest_lng AS prev_dest_lng, t0.origin_lat AS prev_origin_lat, t0.origin_lng AS prev_origin_lng, t0.trip_path_distance AS prev_trip_path_distance, t0.google_duration AS prev_google_duration, t0.travelers_total AS prev_travelers_total, t0.dest_is_home AS prev_dest_is_home, t0.dest_is_work AS prev_dest_is_work, t0.recid AS prev_recid,
		t2.tripid AS next_tripid, t2.tripnum AS next_tripnum,  t2.depart_time_timestamp AS next_depart_time_timestamp,  t2.arrival_time_timestamp AS next_arrival_time_timestamp,  t2.mode_1 AS next_mode_1,  t2.mode_2 AS next_mode_2,  t2.mode_3 AS next_mode_3,  t2.mode_4 AS next_mode_4,  t2.driver AS next_driver,  t2.origin_name AS next_origin_name,  t2.dest_name AS next_dest_name,  t2.origin_purpose AS next_origin_purpose,  t2.dest_purpose AS next_dest_purpose,  t2.dest_lat AS next_dest_lat,  t2.dest_lng AS next_dest_lng,  t2.origin_lat AS next_origin_lat,  t2.origin_lng AS next_origin_lng,  t2.trip_path_distance AS next_trip_path_distance,  t2.google_duration AS next_google_duration,  t2.travelers_total AS next_travelers_total,  t2.dest_is_home AS next_dest_is_home,  t2.dest_is_work AS next_dest_is_work,  t2.recid AS next_recid
		FROM trip AS t1 
			JOIN trip 				AS t0 	ON (t1.tripid-1)=t0.tripid 
			JOIN trip 				as t2 	ON (t1.tripid+1)=t2.tripid
			JOIN person 			AS p 	ON t1.hhid = p.hhid AND t1.personid = p.personid
			JOIN hhts_agecodes 		AS age 	ON p.age = age.agecode
			JOIN household 			AS h 	ON t1.hhid = h.hhid
			JOIN trip_error_flags 	AS tef 	ON t1.personid=tef.personid AND t1.tripnum = tef.tripnum						
		WHERE tef.error_flag IS NOT NULL;
GO