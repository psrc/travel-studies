DROP VIEW IF EXISTS trip_pn
DROP VIEW IF EXISTS data2toolsie_prev_next;
GO

CREATE VIEW trip_pn
AS
SELECT 
        tef.tripid AS master_tripid, trip.tripnum, trip.personid,
        tef.error_flag AS reference,
        trip.depart_time_timestamp, trip.arrival_time_timestamp, 
        trip.mode_1, trip.mode_2, trip.mode_3, trip.mode_4,
        trip.driver, 
        trip.dest_name, trip.dest_purpose, trip.dest_lat, trip.dest_lng, 
        trip.trip_path_distance, trip.google_duration, trip.travelers_total, 
        trip.dest_is_home, trip.dest_is_work
    FROM trip JOIN trip_error_flags AS tef ON trip.tripid = tef.tripid
 UNION
 SELECT 
        tef.tripid AS master_tripid, trip.tripnum, trip.personid,
        'previous' AS reference,
        trip.depart_time_timestamp, trip.arrival_time_timestamp, 
        trip.mode_1, trip.mode_2, trip.mode_3, trip.mode_4,
        trip.driver, 
        trip.dest_name, trip.dest_purpose, trip.dest_lat, trip.dest_lng, 
        trip.trip_path_distance, trip.google_duration, trip.travelers_total, 
        trip.dest_is_home, trip.dest_is_work
    FROM trip JOIN trip_error_flags AS tef ON trip.personid = tef.personid AND trip.tripnum= tef.tripnum-1
 UNION
 SELECT 
        tef.tripid AS master_tripid, trip.tripnum, trip.personid,
        'next' AS reference,
        trip.depart_time_timestamp, trip.arrival_time_timestamp, 
        trip.mode_1, trip.mode_2, trip.mode_3, trip.mode_4,
        trip.driver, 
        trip.dest_name, trip.dest_purpose, trip.dest_lat, trip.dest_lng, 
        trip.trip_path_distance, trip.google_duration, trip.travelers_total, 
        trip.dest_is_home, trip.dest_is_work
    FROM trip JOIN trip_error_flags AS tef ON trip.personid = tef.personid AND trip.tripnum= tef.tripnum+1;
GO

CREATE VIEW data2toolsie_prev_next
AS
SELECT  trip_pn.*, age.agedesc, p.worker, p.student,
        h.reported_lat AS home_lat, h.reported_lng AS home_lng, 
		p.work_lat, p.work_lng, 
		p.school_loc_lat AS school_lat, p.school_loc_lng AS school_lng
FROM trip_pn JOIN person        AS p ON trip_pn.personid = p.personid
         JOIN hhts_agecodes AS age 	ON p.age = age.agecode
		 JOIN household 	AS h 	ON p.hhid = h.hhid;