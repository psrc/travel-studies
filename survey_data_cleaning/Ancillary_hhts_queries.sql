--Error Flag reporting crosstab

		WITH elevated AS 
			(SELECT cte_t.personid FROM HHSurvey.Trip AS cte_t
				WHERE (cte_t.psrc_comment IS NOT NULL) 
				GROUP BY cte_t.personid)
		SELECT error_flag, pivoted.[1] AS rMove, pivoted.[2] AS rSurvey, pivoted.[3] AS elevated
		FROM (SELECT tef.error_flag, CASE WHEN e.personid IS NOT NULL THEN 3 ELSE t.hhgroup END AS category, count(t.recid) AS n
				FROM HHSurvey.Trip AS t 
					JOIN HHSurvey.trip_error_flags AS tef ON t.recid = tef.recid 
					LEFT JOIN elevated AS e ON t.personid = e.personid 
				WHERE t.psrc_resolved IS NULL
				GROUP BY tef.error_flag, CASE WHEN e.personid IS NOT NULL THEN 3 ELSE t.hhgroup END) AS source
		PIVOT (SUM(n) FOR category IN ([1], [2], [3])) AS pivoted
		ORDER BY pivoted.[1] DESC;


		SELECT error_flag, pivoted.[1] AS rMove, pivoted.[2] AS rSurvey
		FROM (SELECT tef.error_flag, t.hhgroup AS category, count(t.recid) AS n
				FROM HHSurvey.Trip AS t 
					JOIN HHSurvey.trip_error_flags AS tef ON t.recid = tef.recid 
				WHERE t.psrc_resolved IS NULL
				GROUP BY tef.error_flag, t.hhgroup) AS source
		PIVOT (SUM(n) FOR category IN ([1], [2])) AS pivoted
		ORDER BY pivoted.[1] DESC;

--Revision Code count

			  SELECT 1, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b1,',1)=1
		UNION SELECT 2, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b2,',1)=1
		UNION SELECT 3, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b3,',1)=1
		UNION SELECT 4, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b4,',1)=1
		UNION SELECT 5, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b5b?,',1)=1
		UNION SELECT 6, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b6,',1)=1
		UNION SELECT 7, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b7,',1)=1
		UNION SELECT 8, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b8,',1)=1
		UNION SELECT 9, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b9,',1)=1
		UNION SELECT 10, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b10,',1)=1
		UNION SELECT 11, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b11,',1)=1
		UNION SELECT 12, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b12,',1)=1
		UNION SELECT 13, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b13,',1)=1
		UNION SELECT 14, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b14,',1)=1
		UNION SELECT 15, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'15,',1)=1
		UNION SELECT 16, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b16,',1)=1
		UNION SELECT 17, count(*) FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.revision_code,'\b17,',1)=1;

--Generic value lookup--alter as necessary

		SELECT cbv.[value], cbv.label
		FROM dbo.Codebook_080219_values AS cbv WHERE cbv.variable = 'age' ORDER BY cbv.value;

--Input query to get API times for excessive speed trips

		SELECT t1.recid, t1.revision_code, t1.psrc_comment, t1.mode_1, t1.trip_path_distance, t1.depart_time_hhmm, t1.arrival_time_hhmm, CONCAT(CAST(t1.origin_lat AS VARCHAR(20)),', ',CAST(t1.origin_lng AS VARCHAR(20))) AS origin_coord,						 
					CONCAT(CAST(t1.dest_lat AS VARCHAR(20)),', ',CAST(t1.dest_lng AS VARCHAR(20))) AS dest_coord
		FROM HHSurvey.Trip AS t1 
		WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE t1.recid = tef.recid AND tef.error_flag = 'excessive speed') --AND HHSurvey.RgxFind(t1.revision_code,'1[2,3],',1) <>1
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

		SELECT t.recid, Left(HHSurvey.RgxExtract(t.psrc_comment,'\d\d:',1),2) AS depart_hour, Right(HHSurvey.RgxExtract(t.psrc_comment,':\d\d',1),2) AS depart_minute, 
		CONCAT(CAST(t.dest_lat AS VARCHAR(20)),', ',CAST(t.dest_lng AS VARCHAR(20))) AS start_coord, CONCAT(CAST(h.home_lat AS VARCHAR(20)),', ',CAST(h.home_lng AS VARCHAR(20))) AS home_coord,
		t.psrc_comment 
			FROM HHSurvey.Trip AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			WHERE HHSurvey.RgxFind(t.psrc_comment,'^ADD RETURN HOME',1)=1 AND t.dest_geog.STDistance(h.home_geog) > 10;

--Input query to get purposes

		SELECT t.recid, CONCAT(CAST(nxt.origin_lat AS VARCHAR(20)),', ',CAST(nxt.origin_lng AS VARCHAR(20))) AS dest_coord, DATEDIFF(Minute, t.arrival_time_timestamp, nxt.depart_time_timestamp) AS dwell, p.age, p.student
			FROM HHSurvey.Trip AS t JOIN HHSurvey.Trip AS nxt ON t.personid = nxt.personid AND t.tripnum +1 = nxt.tripnum JOIN HHSurvey.Person AS p ON t.personid = p.personid
			WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid AND tef.error_flag = '"change mode" purpose')
				AND DATEDIFF(Minute, t.arrival_time_timestamp, nxt.depart_time_timestamp) > 30 AND t.psrc_comment IS NULL;			

--Generate 'execute sproc' for elevate comments

		SELECT t.recid, nxt.recid, CONCAT('EXECUTE HHSurvey.link_trip_via_id ''',HHSurvey.RgxReplace(t.psrc_comment,'LINK ','',1),'''; GO') FROM HHSurvey.Trip AS t JOIN HHSurvey.Trip AS nxt ON t.personid = nxt.personid AND t.tripnum + 1 = nxt.tripnum WHERE (t.psrc_comment LIKE 'LINK%' OR t.psrc_comment LIKE '[1-9]%[[1-9]') --GROUP BY t.personid, t.psrc_comment ORDER BY t.psrc_comment;

		SELECT CONCAT('EXECUTE HHSurvey.split_trip_from_traces ', t.Recid,'; GO') FROM HHSurvey.Trip AS t WHERE t.psrc_comment LIKE 'SPLIT TRIP FROM TRACES%' AND HHSurvey.RgxFind(t.psrc_comment,'(loop|link)',1) <> 1 --GROUP BY t.Recid ORDER BY t.Recid;

		SELECT t.psrc_comment, CONCAT('EXECUTE HHSurvey.unlink_via_id ', t.Recid,';') FROM HHSurvey.Trip AS t WHERE HHSurvey.RgxFind(t.psrc_comment,'^unlink(?!.*\?)',1) = 1 GROUP BY t.psrc_comment, t.Recid ORDER BY t.Recid;

		WITH cte AS
		(SELECT t1.tripid FROM HHSurvey.Trip AS t1 WHERE HHSurvey.RgxFind(t1.revision_code,'8,',1) = 1 
		AND NOT EXISTS (SELECT 1 FROM HHSurvey.trip_ingredients_done AS tid WHERE tid.personid = t1.personid AND tid.arrival_time_timestamp <= t1.arrival_time_timestamp AND tid.depart_time_timestamp >= t1.depart_time_timestamp))
		SELECT t.recid, t.personid, t.d_purpose, nxt.d_purpose, t.dest_geog.STDistance(nxt.dest_geog), t.psrc_comment FROM HHSurvey.Trip AS t /*JOIN cte ON cte.tripid = t.tripid */ JOIN HHSurvey.Trip AS nxt ON t.personid = nxt.personid AND t.tripnum + 1 = nxt.tripnum
		WHERE t.psrc_comment LIKE 'UNLINK[^\?]%' OR t.psrc_comment = 'UNLINK';

--Remove days marked as invalid

		WITH cte AS (SELECT personid, daynum FROM HHSurvey.Trip WHERE psrc_comment LIKE 'Invalid%')
		DELETE FROM HHSurvey.Trip
		OUTPUT deleted.* INTO HHSurvey.trip_invalid
		WHERE EXISTS (SELECT 1 FROM cte WHERE trip.personid = cte.personid AND trip.daynum = cte.daynum);

--Error trip count

		SELECT count(*) FROM HHSurvey.Trip AS t WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid);

--Change modes trip count

		SELECT count(recid) FROM HHsurvey.trip WHERE d_purpose = 60;
		SELECT count(recid) FROM HHsurvey.trip_error_flags WHERE error_flag = '"change mode" purpose'

--Tabulation for elevate comments

		SELECT CASE WHEN psrc_comment LIKE '%unlink%' /*OR psrc_comment LIKE '%examine link%'*/ THEN 'unlink?'
					WHEN psrc_comment LIKE '%add%' OR psrc_comment LIKE '%missing%' THEN 'add'
					WHEN psrc_comment LIKE 'LINK%' OR HHSurvey.RgxFind(psrc_comment,'\d+,\d+',1)=1 THEN 'link' 
					WHEN psrc_comment LIKE 'Origin%' THEN 'o_purpose'
					ELSE 'other' END,
				count(*) FROM HHSurvey.Trip WHERE psrc_comment IS NOT NULL 
			GROUP BY CASE WHEN psrc_comment LIKE '%unlink%' /*OR psrc_comment LIKE '%examine link%'*/ THEN 'unlink?'
					WHEN psrc_comment LIKE '%add%' OR psrc_comment LIKE '%missing%' THEN 'add'
					WHEN psrc_comment LIKE 'LINK%' OR HHSurvey.RgxFind(psrc_comment,'\d+,\d+',1)=1 THEN 'link' 
					WHEN psrc_comment LIKE 'Origin%' THEN 'o_purpose'
					ELSE 'other' END;

--Update travel time for edited records (calculated travel time not initially used for rMove)

		UPDATE t
			SET t.travel_time = t.reported_duration
			FROM HHSurvey.Trip AS t LEFT JOIN dbo.[4_Trip] AS t0 ON t0.tripid = t.tripid
			WHERE (t.reported_duration <> t0.reported_duration OR t.travel_time = 0 OR t.travel_time IS NULL) AND t.hhgroup = 1 AND t.reported_duration > 0;