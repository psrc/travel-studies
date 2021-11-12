--Generic value lookup--alter as necessary

		SELECT cbv.[value], cbv.label
		FROM HHSurvey.CodebookValues AS cbv WHERE cbv.variable = 'age' ORDER BY cbv.value;

--Input query to get API times for excessive speed trips

		SELECT t1.recid, t1.revision_code, t1.psrc_comment, t1.mode_1, t1.trip_path_distance, t1.depart_time_hhmm, t1.arrival_time_hhmm, CONCAT(CAST(t1.origin_lat AS VARCHAR(20)),', ',CAST(t1.origin_lng AS VARCHAR(20))) AS origin_coord,						 
					CONCAT(CAST(t1.dest_lat AS VARCHAR(20)),', ',CAST(t1.dest_lng AS VARCHAR(20))) AS dest_coord
		FROM HHSurvey.Trip AS t1 
		WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE t1.recid = tef.recid AND tef.error_flag = 'excessive speed') --AND Elmer.dbo.rgx_find(t1.revision_code,'1[2,3],',1) <>1
		ORDER BY t1.recid

--Input query to get API times for Missing Link trips

		SELECT  t.recid,
				CONCAT(CAST(t.dest_lat AS VARCHAR(20)),', ',CAST(t.dest_lng AS VARCHAR(20))) AS origin_coord,						 
				CONCAT(CAST(nxt.origin_lat AS VARCHAR(20)),', ',CAST(nxt.origin_lng AS VARCHAR(20))) AS dest_coord				 
			 FROM HHSurvey.Trip AS t 
			 	JOIN HHSurvey.Trip AS nxt ON nxt.personid = t.personid AND nxt.tripnum = t.tripnum + 1
				JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			 WHERE ABS(t.dest_geog.STDistance(nxt.origin_geog)) > 500;

--Input query to get API times for added return-home trips

		SELECT t.recid, Left(Elmer.dbo.rgx_extract(t.psrc_comment,'\d\d:',1),2) AS depart_hour, Right(Elmer.dbo.rgx_extract(t.psrc_comment,':\d\d',1),2) AS depart_minute, 
		CONCAT(CAST(t.dest_lat AS VARCHAR(20)),', ',CAST(t.dest_lng AS VARCHAR(20))) AS start_coord, CONCAT(CAST(h.home_lat AS VARCHAR(20)),', ',CAST(h.home_lng AS VARCHAR(20))) AS home_coord,
		t.psrc_comment 
			FROM HHSurvey.Trip AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			WHERE Elmer.dbo.rgx_find(t.psrc_comment,'^ADD RETURN HOME',1)=1 AND t.dest_geog.STDistance(h.home_geog) > 10;

--Input query to get purposes

		SELECT t.recid, CONCAT(CAST(nxt.origin_lat AS VARCHAR(20)),', ',CAST(nxt.origin_lng AS VARCHAR(20))) AS dest_coord, DATEDIFF(Minute, t.arrival_time_timestamp, nxt.depart_time_timestamp) AS dwell, p.age, p.student
			FROM HHSurvey.Trip AS t JOIN HHSurvey.Trip AS nxt ON t.personid = nxt.personid AND t.tripnum +1 = nxt.tripnum JOIN HHSurvey.Person AS p ON t.personid = p.personid
			WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid AND tef.error_flag = '"change mode" purpose')
				AND DATEDIFF(Minute, t.arrival_time_timestamp, nxt.depart_time_timestamp) > 30 AND t.psrc_comment IS NULL;			

--Generate 'execute sproc' for elevate comments

		SELECT CONCAT('EXECUTE HHSurvey.link_trip_via_id ''',Elmer.dbo.rgx_replace(t.psrc_comment,'LINK ','',1),'''; GO') FROM HHSurvey.Trip AS t WHERE (/*t.psrc_comment LIKE 'LINK%' OR */t.psrc_comment LIKE '[1-9]%[[1-9]') --GROUP BY t.personid, t.psrc_comment ORDER BY t.psrc_comment;

		SELECT CONCAT('EXECUTE HHSurvey.insert_new_trip ''',Elmer.dbo.rgx_replace(t.psrc_comment,'INSERT TRIP ','',1),'''; GO') FROM HHSurvey.Trip AS t WHERE (t.psrc_comment LIKE 'INSERT TRIP [1-9]%') --GROUP BY t.personid, t.psrc_comment ORDER BY t.psrc_comment;


		SELECT CONCAT('EXECUTE HHSurvey.split_trip_from_traces ', t.Recid,'; GO') FROM HHSurvey.Trip AS t WHERE t.psrc_comment LIKE 'SPLIT TRIP FROM TRACES%' AND Elmer.dbo.rgx_find(t.psrc_comment,'(loop|link)',1) <> 1 --GROUP BY t.Recid ORDER BY t.Recid;

		SELECT t.psrc_comment, CONCAT('EXECUTE HHSurvey.unlink_via_id ', t.Recid,';') FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.psrc_comment,'^unlink(?!.*\?)',1) = 1 GROUP BY t.psrc_comment, t.Recid ORDER BY t.Recid;

		WITH cte AS
		(SELECT t1.tripid FROM HHSurvey.Trip AS t1 WHERE Elmer.dbo.rgx_find(t1.revision_code,'8,',1) = 1 
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.trip_ingredients_done AS tid WHERE tid.personid = t1.personid AND tid.arrival_time_timestamp <= t1.arrival_time_timestamp AND tid.depart_time_timestamp >= t1.depart_time_timestamp))
		SELECT t.recid, t.personid, t.dest_purpose, nxt.dest_purpose, t.dest_geog.STDistance(nxt.dest_geog), t.psrc_comment FROM HHSurvey.Trip AS t /*JOIN cte ON cte.tripid = t.tripid */ JOIN HHSurvey.Trip AS nxt ON t.personid = nxt.personid AND t.tripnum + 1 = nxt.tripnum
		WHERE t.psrc_comment LIKE 'UNLINK[^\?]%' OR t.psrc_comment = 'UNLINK';

--Remove days marked as invalid

SELECT TOP 0 * INTO HHSurvey.trip_invalid FROM HHSurvey.Trip UNION ALL SELECT TOP 0 * FROM HHSurvey.Trip;

	/*	WITH cte AS (SELECT personid, daynum FROM HHSurvey.Trip WHERE psrc_comment LIKE 'INVALID%')
		DELETE FROM HHSurvey.Trip
		OUTPUT deleted.* INTO HHSurvey.trip_invalid
		WHERE EXISTS (SELECT 1 FROM cte WHERE trip.personid = cte.personid AND trip.daynum = cte.daynum);*/

--Error trip count

		SELECT count(*) FROM HHSurvey.Trip AS t WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid);

--Change modes trip count

		SELECT count(recid) FROM HHsurvey.trip WHERE dest_purpose = 60;
		SELECT count(recid) FROM HHsurvey.trip_error_flags WHERE error_flag = '"change mode" purpose'

--Tabulation for elevate comments

		SELECT CASE WHEN psrc_comment LIKE '%unlink%' /*OR psrc_comment LIKE '%examine link%'*/ THEN 'unlink?'
					WHEN psrc_comment LIKE '%add%' OR psrc_comment LIKE '%missing%' THEN 'add'
					WHEN psrc_comment LIKE 'LINK%' OR Elmer.dbo.rgx_find(psrc_comment,'\d+,\d+',1)=1 THEN 'link' 
					WHEN psrc_comment LIKE 'Origin%' THEN 'origin_purpose'
					ELSE 'other' END,
				count(*) FROM HHSurvey.Trip WHERE psrc_comment IS NOT NULL 
			GROUP BY CASE WHEN psrc_comment LIKE '%unlink%' /*OR psrc_comment LIKE '%examine link%'*/ THEN 'unlink?'
					WHEN psrc_comment LIKE '%add%' OR psrc_comment LIKE '%missing%' THEN 'add'
					WHEN psrc_comment LIKE 'LINK%' OR Elmer.dbo.rgx_find(psrc_comment,'\d+,\d+',1)=1 THEN 'link' 
					WHEN psrc_comment LIKE 'Origin%' THEN 'origin_purpose'
					ELSE 'other' END;

--Update travel time for edited records (calculated travel time not initially used for rMove)
/*
		UPDATE t
			SET t.travel_time = t.reported_duration
			FROM HHSurvey.Trip AS t LEFT JOIN dbo.hts_trip AS t0 ON t0.tripid = t.tripid
			WHERE (t.reported_duration <> t0.reported_duration OR t.travel_time = 0 OR t.travel_time IS NULL) AND t.hhgroup = 1 AND t.reported_duration > 0;*/

--Update trip_path_distance calculation for edited records where the coords were edited but distance wasn't
WITH cte AS (SELECT t.recid, 
	Elmer.dbo.route_mi_min(t.origin_lng, t.origin_lat, t.dest_lng, t.dest_lat, CASE WHEN t.mode_1=1 THEN 'walking' ELSE 'driving' END,'[BING KEY HERE]') AS mi_min_result
	--INTO dbo.tmpTPD1
	FROM HHSurvey.Trip AS t JOIN dbo.hts_trip AS t0 ON t.tripid=t0.tripid
	WHERE t.trip_path_distance > 0 AND NOT EXISTS (SELECT 1 FROM dbo.tmpTPD AS tz WHERE tz.recid=t.recid) 
		AND (ABS(t.dest_lat-t0.dest_lat) + ABS(t.dest_lng-t0.dest_lng) + ABS(t.origin_lat-t0.origin_lat) +  ABS(t.origin_lng-t0.origin_lng)) > 0.001 
		AND ABS(t.trip_path_distance-t0.trip_path_distance) < 0.01
		AND t.origin_lng BETWEEN -125 AND -116 AND t.dest_lng BETWEEN -125 AND -115 
		AND t.origin_lat BETWEEN 44 and 50 AND t.dest_lat BETWEEN 44 AND 50)
UPDATE tu 
	SET tu.trip_path_distance = CAST(LEFT(cte.mi_min_result, CHARINDEX(',',cte.mi_min_result)-1) AS float)
	FROM HHSurvey.Trip AS tu JOIN cte ON tu.recid=cte.recid WHERE cte.mi_min_result<>'0,0';

--Update trip_path_distance calculation where absent
WITH cte AS (SELECT t.recid, Elmer.dbo.route_mi_min(t.origin_lng, t.origin_lat, t.dest_lng, t.dest_lat, CASE WHEN t.mode_1=1 THEN 'walking' ELSE 'driving' END,'[BING KEY HERE]') AS mi_min_result
FROM HHSurvey.Trip AS t
WHERE (t.trip_path_distance IS NULL OR t.trip_path_distance=0) AND t.origin_lng BETWEEN -125 AND -116 AND t.dest_lng BETWEEN -125 AND -115 
AND t.origin_lat BETWEEN 44 and 50 AND t.dest_lat BETWEEN 44 AND 50 AND recid BETWEEN 8001 AND 20000)
UPDATE tu 
	SET tu.trip_path_distance = CAST(LEFT(cte.mi_min_result, CHARINDEX(',', cte.mi_min_result)-1) AS float)
	FROM HHSurvey.Trip AS tu JOIN cte ON tu.recid=cte.recid WHERE cte.mi_min_result<>'0,0';

--Update geoassignments; for county first use rectangular approximation to save computation

ALTER TABLE HHSurvey.Trip ADD dest_geom GEOMETRY NULL;

ALTER TABLE HHSurvey.Trip ADD origin_geom GEOMETRY NULL;

UPDATE t SET t.dest_geom=Elmer.dbo.ToXY(t.dest_lng, t.dest_lat) FROM HHSurvey.Trip AS t;

UPDATE t SET t.origin_geom=Elmer.dbo.ToXY(t.origin_lng, t.origin_lat) FROM HHSurvey.Trip AS t;

CREATE SPATIAL INDEX dest_geom_idx ON HHSurvey.Trip(dest_geom) USING GEOMETRY_AUTO_GRID
  WITH (BOUNDING_BOX = (xmin = 1095800, ymin = -97600, xmax = 1622700, ymax = 477600));

  CREATE SPATIAL INDEX origin_geom_idx ON HHSurvey.Trip(origin_geom) USING GEOMETRY_AUTO_GRID
  WITH (BOUNDING_BOX = (xmin = 1095800, ymin = -97600, xmax = 1622700, ymax = 477600));

ALTER TABLE HHSurvey.Trip ADD region_tripends int DEFAULT 0;

UPDATE t SET t.region_tripends=t.region_tripends+1 
FROM HHSurvey.Trip AS t JOIN ElmerGeo.dbo.PSRC_REGIONAL_OUTLINE AS r ON r.Shape.STIntersects(t.dest_geom)=1;

UPDATE t SET t.region_tripends=t.region_tripends+1 
FROM HHSurvey.Trip AS t JOIN ElmerGeo.dbo.PSRC_REGIONAL_OUTLINE AS r ON r.Shape.STIntersects(t.origin_geom)=1;

UPDATE t SET t.dest_city=r.city_name 
FROM HHSurvey.Trip AS t JOIN ElmerGeo.dbo.PSRC_REGION AS r ON r.Shape.STIntersects(t.dest_geom)=1
WHERE r.feat_type='city';

UPDATE t SET t.dest_zip=r.zipcode 
FROM HHSurvey.Trip AS t JOIN ElmerGeo.dbo.ZIP_CODES AS r ON r.Shape.STIntersects(t.dest_geom)=1;

SELECT t.region_tripends, count(*) FROM HHSurvey.Trip AS t GROUP BY t.region_tripends;

UPDATE t
SET t.dest_county=CASE WHEN (t.dest_lat BETWEEN 47.32417899933368 AND 47.77557543545566) AND (t.dest_lng BETWEEN -122.40491513697908 AND -121.47382388080176) THEN '033'
					   WHEN (t.dest_lat BETWEEN 46.987025526142794 AND 47.25521385921765) AND (t.dest_lng BETWEEN -122.61999268125203 AND -122.14483401659517) THEN '053'
					   WHEN (t.dest_lat BETWEEN 47.785624118154686 AND 48.29247321335945) AND (t.dest_lng BETWEEN -122.34422210698376 AND -121.18653784598449) THEN '061'
					   WHEN (t.dest_lat BETWEEN 47.5126145395748 AND 47.7726115311967) AND (t.dest_lng BETWEEN -122.73894212405432 AND -122.50273608266419) THEN '035'
					   ELSE NULL END
FROM HHSurvey.Trip AS t WHERE t.dest_county IS NULL;

UPDATE t
SET t.dest_county = r.county_fip
FROM HHSurvey.Trip AS t JOIN ElmerGeo.dbo.COUNTY_LINES AS r ON t.dest_geom.STIntersects(r.Shape)=1
WHERE r.psrc=1;