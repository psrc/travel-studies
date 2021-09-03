
USE Sandbox
GO

TRUNCATE TABLE Mike.trip_error_flags_nk;
DELETE tef 
		FROM Mike.trip_error_flags_nk AS tef 
		WHERE tef.personid = (CASE WHEN @target_personid IS NULL THEN tef.personid ELSE @target_personid END);

		-- 																									  LOGICAL ERROR LABEL 		
		DROP TABLE IF EXISTS #dayends;
		SELECT t.personid, ROUND(t.dest_lat,2) AS loc_lat, ROUND(t.dest_lng,2) as loc_lng, count(*) AS n 
			INTO #dayends
			FROM Mike.trip_nk AS t LEFT JOIN Mike.trip_nk AS next_t ON t.personid = next_t.personid AND t.tripnum + 1 = next_t.tripnum
					WHERE (next_t.tripid IS NULL											 -- either there is no 'next trip'
							OR (DATEDIFF(Day, t.arrival_time_timestamp, next_t.depart_time_timestamp) = 1 
								AND DATEPART(Hour, next_t.depart_time_timestamp) > 2 ))   -- or the next trip starts the next day after 3am)
					GROUP BY t.personid, ROUND(t.dest_lat,2), ROUND(t.dest_lng,2)
					HAVING count(*) > 1;

		ALTER TABLE #dayends ADD loc_geog GEOGRAPHY NULL;

		UPDATE #dayends 
			SET loc_geog = geography::STGeomFromText('POINT(' + CAST(loc_lng AS VARCHAR(20)) + ' ' + CAST(loc_lat AS VARCHAR(20)) + ')', 4326);
		
		WITH trip_ref AS (SELECT * FROM Mike.trip_nk AS t0),
			cte_dwell AS 
				(SELECT c.tripid, c.collected_at FROM Mike.trace AS c 
				JOIN Mike.trace AS cnxt ON c.traceid + 1 = cnxt.traceid AND c.tripid = cnxt.tripid
				WHERE DATEDIFF(Minute, c.collected_at, cnxt.collected_at) > 14),

			cte_tracecount AS (SELECT ctc.tripid, count(*) AS tracecount FROM Mike.trace AS ctc GROUP BY ctc.tripid HAVING count(*) > 2),

			error_flag_compilation(tripid, personid, tripnum, error_flag) AS
			(SELECT t.tripid, t.personid, t.tripnum,	           				   			                  'ends day, not home' AS error_flag
			FROM trip_ref AS t JOIN Mike.household AS h ON t.hhid = h.hhid
			LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE (DATEDIFF(Day, (CASE WHEN DATEPART(Hour, t.arrival_time_timestamp) < 3 THEN DATEADD(Hour, -3, t.arrival_time_timestamp) ELSE t.arrival_time_timestamp END), 
										 (CASE WHEN DATEPART(Hour, t_next.arrival_time_timestamp) < 3 THEN DATEADD(Hour, -3, t_next.depart_time_timestamp) WHEN t_next.arrival_time_timestamp IS NULL THEN DATEADD(Day, 1, t.arrival_time_timestamp) ELSE t_next.depart_time_timestamp END))) = 1  -- or the next trip starts the next day after 3am)
				AND t.dest_is_home IS NULL 
				AND t.dest_purpose NOT IN(1,34,52,55,62,97) 
				AND t.dest_geog.STDistance(h.home_geog) > 300
				AND NOT EXISTS (SELECT 1 FROM #dayends AS de WHERE t.personid = de.personid AND t.dest_geog.STDistance(de.loc_geog) < 300)	

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	           		   		   'starts, not from home' AS error_flag
			FROM trip_ref AS t JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE DATEDIFF(Day, t.arrival_time_timestamp, t_next.depart_time_timestamp) = 1 -- t_next is first trip of the day
					AND t.dest_is_home IS NULL AND dbo.TRIM(t_next.origin_name)<>'HOME'
					AND DATEPART(Hour, t_next.depart_time_timestamp) > 1  -- Night owls typically home before 2am

			 UNION ALL SELECT t.tripid, t.personid, t.tripnum, 									       		 'purpose missing' AS error_flag
				FROM trip_ref AS t
					LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE t.dest_purpose IS NULL

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,  								   'initial trip purpose missing' AS error_flag
				FROM trip_ref AS t 
				WHERE t.origin_purpose IS NULL AND t.tripnum = 1

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum, 											 'mode_1 missing' AS error_flag
				FROM trip_ref AS t
					LEFT JOIN trip_ref AS t_prev ON t.personid = t_prev.personid AND t.tripnum - 1 = t_prev.tripnum
					LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE t.mode_1 IS NULL
					AND t_prev.mode_1 IS NOT NULL  -- we don't want to focus on instances with large blocks of trips missing info
					AND t_next.mode_1 IS NOT NULL

			UNION ALL SELECT t.tripid, t.personid, t.tripnum, 					     'o purpose not equal to prior d purpose' AS error_flag
				FROM trip_ref AS t
					JOIN trip_ref AS t_prev ON t.personid = t_prev.personid AND t.tripnum - 1 = t_prev.tripnum
					WHERE t.origin_purpose <> t_prev.dest_purpose

			/*UNION ALL SELECT max( t.tripid),  t.personid, max( t.tripnum) AS tripnum, 							  'lone trip' AS error_flag
				FROM trip_ref 
				GROUP BY  t.personid 
				HAVING max( t.tripnum)=1
			*/ --Lone trips only for scrutiny when largely void of data; that's true of any  t. Handle in problematic HH review instead

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,									        	'underage driver' AS error_flag
				FROM Mike.person AS p
				JOIN trip_ref AS t ON p.personid = t.personid
				WHERE t.driver = 1 AND (p.age BETWEEN 1 AND 3)

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum, 									      'unlicensed driver' AS error_flag
				FROM trip_ref as t JOIN Mike.person AS p ON p.personid = t.personid
				WHERE p.license = 3 AND  t.driver = 1

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum, 							 		 'non-worker + work trip' AS error_flag
				FROM trip_ref AS t JOIN Mike.person AS p ON p.personid= t.personid
				WHERE p.worker = 0 AND  t.dest_purpose in(10,11,14)

			UNION ALL SELECT t.tripid, t.personid, t.tripnum, 												'excessive speed' AS error_flag
				FROM trip_ref AS t									
				WHERE 	((EXISTS (SELECT 1 FROM Mike.walkmodes WHERE walkmodes.mode_id = t.mode_1) AND t.speed_mph > 20)
					OR 	(EXISTS (SELECT 1 FROM Mike.bikemodes WHERE bikemodes.mode_id = t.mode_1) AND t.speed_mph > 40)
					OR	(EXISTS (SELECT 1 FROM Mike.automodes WHERE automodes.mode_id = t.mode_1) AND t.speed_mph > 85)	
					OR	(EXISTS (SELECT 1 FROM Mike.transitmodes WHERE transitmodes.mode_id = t.mode_1) AND t.mode_1 <> 31 AND t.speed_mph > 60)	
					OR 	(t.speed_mph > 600 AND (t.origin_lng between 116.95 AND 140) AND (t.dest_lng between 116.95 AND 140)))	-- approximates Pacific Time Zone until vendor delivers UST offset

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					  					   				'too slow' AS error_flag
				FROM trip_ref AS t
				WHERE DATEDIFF(Minute,  t.depart_time_timestamp,  t.arrival_time_timestamp) > 180 AND  t.speed_mph < 20		

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					  					   				'long dwell' AS error_flag
				FROM trip_ref AS t JOIN cte_tracecount ON t.tripid = cte_tracecount.tripid
				WHERE EXISTS (SELECT 1 FROM cte_dwell WHERE cte_dwell.tripid = t.tripid AND cte_dwell.collected_at > t.depart_time_timestamp AND cte_dwell.collected_at < t.arrival_time_timestamp)

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,				   					  		'no activity time after' AS error_flag
				FROM trip_ref as t JOIN Mike.trip_nk AS t_next ON t.personid=t_next.personid AND t.tripnum + 1 = t_next.tripnum
					WHERE DATEDIFF(Second,  t.depart_time_timestamp, t_next.depart_time_timestamp) < 60 
					AND  t.dest_purpose NOT IN(1,9,33,51,60,61,62,97) AND t.dest_purpose IS NOT NULL

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	   				           'no activity time before' AS error_flag
				FROM trip_ref as t JOIN Mike.trip_nk AS  t_next ON  t.personid=t_next.personid AND  t.tripnum + 1 = t_next.tripnum
				WHERE DATEDIFF(Second,  t.depart_time_timestamp, t_next.depart_time_timestamp) < 60 
					AND  t.dest_purpose NOT IN(1,9,33,51,60,61,62,97) AND t.dest_purpose IS NOT NULL		

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					        	 		         'same dest as next' AS error_flag
				FROM trip_ref as t JOIN Mike.trip_nk AS t_next ON  t.personid=t_next.personid AND t.tripnum + 1 =t_next.tripnum
					AND t.dest_lat = t_next.dest_lat AND t.dest_lng = t_next.dest_lng

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	       				            'same dest as prior' AS error_flag
				FROM trip_ref as t JOIN Mike.trip_nk AS t_next ON  t.personid=t_next.personid AND t.tripnum + 1 =t_next.tripnum 
					AND t.dest_lat = t_next.dest_lat AND t.dest_lng = t_next.dest_lng

			UNION ALL (SELECT t.tripid, t.personid, t.tripnum,					         				     	  'time overlap' AS error_flag
				FROM trip_ref AS t JOIN Mike.trip_nk AS compare_t ON  t.personid=compare_t.personid AND  t.tripid <> compare_t.tripid
				WHERE 	(compare_t.depart_time_timestamp  BETWEEN DATEADD(Minute, 2, t.depart_time_timestamp) AND DATEADD(Minute, -2, t.arrival_time_timestamp))
					OR	(compare_t.arrival_time_timestamp BETWEEN DATEADD(Minute, 2,  t.depart_time_timestamp) AND DATEADD(Minute, -2,  t.arrival_time_timestamp))
					OR	(t.depart_time_timestamp  BETWEEN DATEADD(Minute, 2, compare_t.depart_time_timestamp) AND DATEADD(Minute, -2, compare_t.arrival_time_timestamp))
					OR	(t.arrival_time_timestamp BETWEEN DATEADD(Minute, 2, compare_t.depart_time_timestamp) AND DATEADD(Minute, -2, compare_t.arrival_time_timestamp)))

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,								      'same transit line listed 2x+' AS error_flag
				FROM trip_ref AS t
    			WHERE EXISTS(SELECT count(*) 
								FROM (VALUES(t.transit_line_1),(t.transit_line_2),(t.transit_line_3),(t.transit_line_4),(t.transit_line_5)) AS transitline(member) 
								WHERE member IS NOT NULL AND member <> 0 GROUP BY member HAVING count(*) > 1)

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,	  		   			 		   	       'purpose at odds w/ dest' AS error_flag
				FROM trip_ref AS t JOIN Mike.household AS h ON t.hhid = h.hhid JOIN Mike.person AS p ON t.personid = p.personid
				WHERE (t.dest_purpose <> 1 and t.dest_is_home = 1) OR (t.dest_purpose NOT IN(9,10,11,14,60) and t.dest_is_work = 1)
					AND h.home_geog.STDistance(p.work_geog) > 500
 
			UNION ALL SELECT t.tripid, t.personid, t.tripnum,					                        'missing next trip link' AS error_flag
			FROM trip_ref AS t JOIN Mike.trip_nk AS t_next ON  t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE ABS(t.dest_geog.STDistance(t_next.origin_geog)) > 500  --500m difference or more

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	              	           'missing prior trip link' AS error_flag
			FROM trip_ref AS t JOIN Mike.trip_nk AS t_next ON t.personid = t_next.personid AND  t.tripnum + 1 = t_next.tripnum
				WHERE ABS(t.dest_geog.STDistance(t_next.origin_geog)) > 500	--500m difference or more			

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,	              	 			 			 '"change mode" purpose' AS error_flag	
				FROM trip_ref AS t JOIN Mike.trip_nk AS t_next ON t.personid = t_next.personid AND  t.tripnum + 1 = t_next.tripnum
					WHERE t.dest_purpose = 60 AND dbo.RgxFind(t_next.modes,'31|32',1) = 0 AND dbo.RgxFind(t.modes,'(31|32)',1) = 0
					AND t.travelers_total = t_next.travelers_total
/*
			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					          		  'PUDO, no +/- travelers' AS error_flag	--This is an error but we're choosing not to focus on it right now.
				FROM Mike.trip_nk
				LEFT JOIN Mike.trip_nk AS next_t ON  t.personid=next_t.personid	AND  t.tripnum + 1 = next_t.tripnum						
				WHERE  t.dest_purpose = 9 AND ( t.travelers_total = next_t.travelers_total)
*/
			UNION ALL SELECT t.tripid, t.personid, t.tripnum,					  				 	    	   'too long at dest' AS error_flag
				FROM trip_ref AS t JOIN Mike.trip_nk AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					WHERE   (t.dest_purpose IN(6,10,11,14)    		
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
								CASE WHEN t_next.tripid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 840)
    					OR  (t.dest_purpose IN(30)      			
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
								CASE WHEN t_next.tripid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 240)
   						OR  (t.dest_purpose IN(32,33,50,51,53,54,56,60,61) 	
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
						   		CASE WHEN t_next.tripid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 480)  

			UNION ALL SELECT t.tripid, t.personid, t.tripnum, 		  				   		          'non-student + school trip' AS error_flag
				FROM trip_ref AS t JOIN Mike.trip_nk as t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum JOIN Mike.person ON t.personid=person.personid 					
				WHERE t.dest_purpose = 6		
					AND (person.student NOT IN(2,3,4) OR person.student IS NULL) AND person.age > 4)

		INSERT INTO Mike.trip_error_flags_nk (tripid, personid, tripnum, error_flag)
			SELECT efc.tripid, efc.personid, efc.tripnum, efc.error_flag 
			FROM error_flag_compilation AS efc
			GROUP BY efc.tripid, efc.personid, efc.tripnum, efc.error_flag;

		DROP TABLE IF EXISTS #dayends;


		SELECT error_flag, pivoted.[1] AS rMove, pivoted.[2] AS rSurvey
		FROM (SELECT tef.error_flag, t.hhgroup AS category, count(t.tripid) AS n
				FROM Mike.Trip_nk AS t 
					JOIN Mike.trip_error_flags_nk AS tef ON t.tripid = tef.tripid
				GROUP BY tef.error_flag, t.hhgroup) AS source
		PIVOT (SUM(n) FOR category IN ([1], [2])) AS pivoted
		ORDER BY pivoted.[1] DESC;
