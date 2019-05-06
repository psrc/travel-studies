DROP VIEW IF EXISTS trip_prev_next
DROP VIEW IF EXISTS data2toolsie_prev_next;
GO

CREATE VIEW trip_pn
AS
(SELECT t1.tripid AS master_tripid, 'current'   AS reference, t1.* FROM trip as t1 JOIN trip_error_flags 	AS tef 	ON t1.personid=tef.personid AND t1.tripnum = tef.tripnum
 UNION
 SELECT t1.tripid AS master_tripid, 'previous'  AS reference, t0.* FROM trip AS t1 JOIN trip 				AS t0 	ON (t1.tripid-1)=t0.tripid
 UNION
 SELECT t1.tripid AS master_tripid, 'next'      AS reference, t2.* FROM trip AS t1 JOIN trip 				AS t2 	ON (t1.tripid+1)=t2.tripid)
GO

CREATE VIEW data2toolsie_prev_next
AS
SELECT  trip_pn.master_tripid, trip_pn.tripnum,
        trip_pn.reference,
        trip_pn.personid,age.agedesc, p.worker, p.student,
        trip_pn.depart_time_timestamp, trip_pn.arrival_time_timestamp, 
        trip_pn.mode_1, trip_pn.mode_2, trip_pn.mode_3, trip_pn.mode_4, 
        trip_pn.driver, 
        trip_pn.dest_name, trip_pn.dest_purpose, trip_pn.dest_lat, trip_pn.dest_lng, 
        trip_pn.trip_path_distance, trip_pn.google_duration, trip_pn.travelers_total, 
        trip_pn.dest_is_home, trip_pn.dest_is_work
FROM trip_pn JOIN person        AS p ON trip_pn.hhid = p.hhid AND trip_pn.personid = p.personid
         JOIN hhts_agecodes AS age 	ON p.age = age.agecode
		 JOIN household 	AS h 	ON trip_pn.hhid = h.hhid;