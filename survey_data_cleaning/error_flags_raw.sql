	DROP TABLE IF EXISTS #dayends;
		SELECT t.personid, ROUND(t.dest_lat,2) AS loc_lat, ROUND(t.dest_lng,2) as loc_lng, count(*) AS n 
			INTO #dayends
			FROM dbo.[4_Trip] AS t LEFT JOIN dbo.[4_Trip] AS next_t ON t.personid = next_t.personid AND t.tripnum + 1 = next_t.tripnum
					WHERE (next_t.tripid IS NULL											 -- either there is no 'next trip'
							OR (DATEDIFF(Day, t.arrival_time_timestamp, next_t.depart_time_timestamp) = 1 
								AND DATEPART(Hour, next_t.depart_time_timestamp) > 2 ))   -- or the next trip starts the next day after 3am)
					GROUP BY t.personid, ROUND(t.dest_lat,2), ROUND(t.dest_lng,2)
					HAVING count(*) > 1;

		ALTER TABLE #dayends ADD loc_geog GEOGRAPHY NULL;

		UPDATE #dayends 
			SET loc_geog = geography::STGeomFromText('POINT(' + CAST(loc_lng AS VARCHAR(20)) + ' ' + CAST(loc_lat AS VARCHAR(20)) + ')', 4326);
		
		WITH trip_ref AS (SELECT t0.*, geography::STGeomFromText('POINT(' + CAST(t0.dest_lng 	  AS VARCHAR(20)) + ' ' + CAST(t0.dest_lat 	AS VARCHAR(20)) + ')', 4326) AS dest_geog,
			 geography::STGeomFromText('POINT(' + CAST(t0.origin_lng    AS VARCHAR(20)) + ' ' + CAST(t0.origin_lat 	AS VARCHAR(20)) + ')', 4326) AS origin_geog FROM dbo.[4_Trip] AS t0
						  WHERE (t0.dest_lat BETWEEN 46.725491 AND 48.392602) AND (t0.dest_lng BETWEEN -123.199429 AND -121.243746)), 
			cte_dwell AS 
				(SELECT c.tripid, c.collected_at, cnxt.collected_at AS nxt_collected FROM HHSurvey.Trace AS c 
				JOIN HHSurvey.Trace AS cnxt ON c.traceid + 1 = cnxt.traceid AND c.tripid = cnxt.tripid
				WHERE DATEDIFF(Minute, c.collected_at, cnxt.collected_at) > 14),

			cte_tracecount AS (SELECT ctc.tripid, count(*) AS tracecount FROM HHSurvey.Trace AS ctc GROUP BY ctc.tripid HAVING count(*) > 2)
			, error_flag_compilation(tripid, personid, tripnum, error_flag) AS (
			SELECT t.tripid, t.personid, t.tripnum,	           				   			                  'ends day, not home' AS error_flag
			FROM trip_ref AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
			LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE DATEDIFF(Day,(CASE WHEN DATEPART(Hour, t.arrival_time_timestamp) < 3 THEN DATEADD(Hour, -3, t.arrival_time_timestamp) ELSE t.arrival_time_timestamp END),
								   (CASE WHEN DATEPART(Hour, t_next.arrival_time_timestamp) < 3 THEN DATEADD(Hour, -3, t_next.depart_time_timestamp) WHEN t_next.arrival_time_timestamp IS NULL THEN DATEADD(Day, 1, t.arrival_time_timestamp) ELSE t_next.depart_time_timestamp END)) = 1  -- or the next trip starts the next day after 3am)
				AND t.d_purpose NOT IN(1,34,52,55,62,97) 
				--AND HHSurvey.RgxFind(t.psrc_comment,'ADD RETURN HOME \d?\d:\d\d',1) = 0
				AND t.dest_geog.STDistance(h.home_geog) > 300
				AND NOT EXISTS (SELECT 1 FROM #dayends AS de WHERE t.personid = de.personid AND t.dest_geog.STDistance(de.loc_geog) < 300)	

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	           		   		   'starts, not from home' AS error_flag
			FROM trip_ref AS t JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum JOIN HHSurvey.Household AS h ON t.hhid = h.hhid
				WHERE DATEDIFF(Day, t.arrival_time_timestamp, t_next.depart_time_timestamp) = 1 -- t_next is first trip of the day
					AND DATEPART(Hour, t_next.depart_time_timestamp) > 1  -- Night owls typically home before 2am
					AND t.dest_geog.STDistance(h.home_geog) > 300

			 UNION ALL SELECT t.tripid, t.personid, t.tripnum, 									       		 'purpose missing' AS error_flag
				FROM trip_ref AS t
					LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					JOIN HHSurvey.fnVariableLookup('d_purpose') as vl ON t.d_purpose = vl.code
					JOIN HHSurvey.fnVariableLookup('d_purpose') as v2 ON t.o_purpose = v2.code
					LEFT JOIN HHSurvey.fnVariableLookup('d_purpose') as v3 ON t_next.d_purpose = v3.code
				WHERE (vl.label LIKE 'Missing%' OR t.d_purpose IS NULL)
					--AND (v2.label NOT LIKE 'Missing%' AND t.d_purpose IS NOT NULL) -- we don't want to focus on instances with large blocks of trips missing info
					--AND (v3.label NOT LIKE 'Missing%' AND t.d_purpose IS NOT NULL)	

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,  								   'initial trip purpose missing' AS error_flag
				FROM trip_ref AS t 
				JOIN HHSurvey.fnVariableLookup('d_purpose') as vl ON t.o_purpose = vl.code
				WHERE vl.label like 'Missing%' AND t.tripnum = 1

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum, 											 'mode_1 missing' AS error_flag
				FROM trip_ref AS t
					LEFT JOIN trip_ref AS t_prev ON t.personid = t_prev.personid AND t.tripnum - 1 = t_prev.tripnum
					LEFT JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					JOIN HHSurvey.fnVariableLookup('mode_1') as vl ON t.mode_1 = vl.code
					LEFT JOIN HHSurvey.fnVariableLookup('mode_1') as v2 ON t_prev.mode_1 = v2.code
					LEFT JOIN HHSurvey.fnVariableLookup('mode_1') as v3 ON t_next.mode_1 = v3.code
				WHERE vl.label LIKE 'Missing%'
					AND v2.label NOT LIKE 'Missing%'  -- we don't want to focus on instances with large blocks of trips missing info
					AND v3.label NOT LIKE 'Missing%'

			UNION ALL SELECT t.tripid, t.personid, t.tripnum, 					     'o purpose not equal to prior d purpose' AS error_flag
				FROM trip_ref AS t
					JOIN trip_ref AS t_prev ON t.personid = t_prev.personid AND t.tripnum - 1 = t_prev.tripnum
					WHERE t.o_purpose <> t_prev.d_purpose AND DATEDIFF(Day, t_prev.arrival_time_timestamp, t.depart_time_timestamp) =0

			/*UNION ALL SELECT max( t.tripid),  t.personid, max( t.tripnum) AS tripnum, 							  'lone trip' AS error_flag
				FROM trip_ref 
				GROUP BY  t.personid 
				HAVING max( t.tripnum)=1
			*/ --Lone trips only for scrutiny when largely void of data; that's true of any  t. Handle in problematic HH review instead

			/*UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,									        	'underage driver' AS error_flag
				FROM HHSurvey.person AS p
				JOIN trip_ref AS t ON p.personid = t.personid
				WHERE t.driver = 1 AND (p.age BETWEEN 1 AND 3)

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum, 									      'unlicensed driver' AS error_flag
				FROM trip_ref as t JOIN HHSurvey.person AS p ON p.personid = t.personid
				WHERE p.license = 3 AND  t.driver = 1

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum, 							 		 'non-worker + work trip' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.person AS p ON p.personid= t.personid
				WHERE p.employment > 4 AND  t.d_purpose in(10,11,14)*/

			UNION ALL SELECT t.tripid, t.personid, t.tripnum, 												'excessive speed' AS error_flag
				FROM trip_ref AS t									
				WHERE 	((EXISTS (SELECT 1 FROM HHSurvey.walkmodes WHERE walkmodes.mode_id = t.mode_1) AND t.speed_mph > 20)
					OR 	(EXISTS (SELECT 1 FROM HHSurvey.bikemodes WHERE bikemodes.mode_id = t.mode_1) AND t.speed_mph > 40)
					OR	(EXISTS (SELECT 1 FROM HHSurvey.automodes WHERE automodes.mode_id = t.mode_1) AND t.speed_mph > 85)	
					OR	(EXISTS (SELECT 1 FROM HHSurvey.transitmodes WHERE transitmodes.mode_id = t.mode_1) AND t.mode_1 <> 31 AND t.speed_mph > 60)	
					OR 	(t.speed_mph > 600 AND (t.origin_lng between 116.95 AND 140) AND (t.dest_lng between 116.95 AND 140)))	-- approximates Pacific Time Zone until vendor delivers UST offset

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					  					   				'too slow' AS error_flag
				FROM trip_ref AS t
				WHERE DATEDIFF(Minute,  t.depart_time_timestamp,  t.arrival_time_timestamp) > 180 AND  t.speed_mph < 20		

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					  					   				'long dwell' AS error_flag
				FROM trip_ref AS t JOIN cte_tracecount ON t.tripid = cte_tracecount.tripid
				WHERE EXISTS (SELECT 1 FROM cte_dwell WHERE cte_dwell.tripid = t.tripid AND cte_dwell.collected_at > t.depart_time_timestamp AND cte_dwell.nxt_collected < t.arrival_time_timestamp)
					

			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,				   					  		'no activity time after' AS error_flag
				FROM trip_ref as t JOIN trip_ref AS t_next ON t.personid=t_next.personid AND t.tripnum + 1 = t_next.tripnum
				LEFT JOIN HHSurvey.fnVariableLookup('d_purpose') as v ON  t.d_purpose = v.code
				WHERE DATEDIFF(Second,  t.depart_time_timestamp, t_next.depart_time_timestamp) < 60 
					AND  t.d_purpose NOT IN(1,9,33,51,60,61,62,97) AND v.label <> 'Other purpose' AND v.label NOT LIKE 'Missing%'

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	   				           'no activity time before' AS error_flag
				FROM trip_ref as t JOIN trip_ref AS  t_next ON  t.personid=t_next.personid AND  t.tripnum + 1 = t_next.tripnum
					LEFT JOIN HHSurvey.fnVariableLookup('d_purpose') as v ON  t.d_purpose = v.code
				WHERE DATEDIFF(Second,  t.depart_time_timestamp, t_next.depart_time_timestamp) < 60
					AND  t.d_purpose NOT IN(1,9,33,51,60,61,62,97) AND v.label <> 'Other purpose' AND v.label NOT LIKE 'Missing%'			

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	       				            'same dest as prior' AS error_flag
				FROM trip_ref as t JOIN trip_ref AS t_next ON  t.personid=t_next.personid AND t.tripnum + 1 =t_next.tripnum 
					AND t.dest_lat = t_next.dest_lat AND t.dest_lng = t_next.dest_lng

			UNION ALL (SELECT t.tripid, t.personid, t.tripnum,					         				     	  'time overlap' AS error_flag
				FROM trip_ref AS t JOIN trip_ref AS compare_t ON  t.personid=compare_t.personid AND  t.tripid <> compare_t.tripid
				WHERE 	(compare_t.depart_time_timestamp  BETWEEN DATEADD(Minute, 2, t.depart_time_timestamp) AND DATEADD(Minute, -2, t.arrival_time_timestamp))
					OR	(compare_t.arrival_time_timestamp BETWEEN DATEADD(Minute, 2,  t.depart_time_timestamp) AND DATEADD(Minute, -2,  t.arrival_time_timestamp))
					OR	(t.depart_time_timestamp  BETWEEN DATEADD(Minute, 2, compare_t.depart_time_timestamp) AND DATEADD(Minute, -2, compare_t.arrival_time_timestamp))
					OR	(t.arrival_time_timestamp BETWEEN DATEADD(Minute, 2, compare_t.depart_time_timestamp) AND DATEADD(Minute, -2, compare_t.arrival_time_timestamp)))

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,								      'same transit line listed 2x+' AS error_flag
				FROM trip_ref AS t
    			WHERE EXISTS(SELECT count(*) 
								FROM (VALUES(t.transit_line_1),(t.transit_line_2),(t.transit_line_3),(t.transit_line_4),(t.transit_line_5)) AS transitline(member) 
								WHERE member IS NOT NULL and member not in (select flag_value from HHSurvey.NullFlags) AND member <> 0 GROUP BY member HAVING count(*) > 1)

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,	  		   			 		   	       'purpose at odds w/ dest' AS error_flag
				FROM trip_ref AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid JOIN HHSurvey.Person AS p ON t.personid = p.personid
				WHERE (t.d_purpose <> 1 AND t.dest_geog.STDistance(h.home_geog) < 50) OR (t.d_purpose NOT IN(9,10,11,14,60) AND t.dest_geog.STDistance(p.work_geog) < 50)
					AND h.home_geog.STDistance(p.work_geog) > 500
 
			UNION ALL SELECT t.tripid, t.personid, t.tripnum,					                        'missing next trip link' AS error_flag
			FROM trip_ref AS t JOIN trip_ref AS t_next ON  t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
				WHERE ABS(t.dest_geog.STDistance(t_next.origin_geog)) > 500  --500m difference or more

			UNION ALL SELECT t_next.tripid, t_next.personid, t_next.tripnum,	              	           'missing prior trip link' AS error_flag
			FROM trip_ref AS t JOIN trip_ref AS t_next ON t.personid = t_next.personid AND  t.tripnum + 1 = t_next.tripnum
				WHERE ABS(t.dest_geog.STDistance(t_next.origin_geog)) > 500	--500m difference or more			

			UNION ALL SELECT t.tripid, t.personid, t.tripnum,	              	 			 			 '"change mode" purpose' AS error_flag	
				FROM trip_ref AS t JOIN trip_ref AS t_next ON t.personid = t_next.personid AND  t.tripnum + 1 = t_next.tripnum
					WHERE t.d_purpose = 60
					AND t.travelers_total = t_next.travelers_total
/*
			UNION ALL SELECT  t.tripid,  t.personid,  t.tripnum,					          		  'PUDO, no +/- travelers' AS error_flag	--This is an error but we're choosing not to focus on it right now.
				FROM trip_ref
				LEFT JOIN trip_ref AS next_t ON  t.personid=next_t.personid	AND  t.tripnum + 1 = next_t.tripnum						
				WHERE  t.d_purpose = 9 AND ( t.travelers_total = next_t.travelers_total)
*/
			UNION ALL SELECT t.tripid, t.personid, t.tripnum,					  				 	    	   'too long at dest' AS error_flag
				FROM trip_ref AS t JOIN trip_ref AS t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum
					WHERE   (t.d_purpose IN(6,10,11,14)    		
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
								CASE WHEN t_next.tripid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 840)
    					OR  (t.d_purpose IN(30)      			
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
								CASE WHEN t_next.tripid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 240)
   						OR  (t.d_purpose IN(32,33,50,51,53,54,56,60,61) 	
						AND DATEDIFF(Minute, t.arrival_time_timestamp, 
						   		CASE WHEN t_next.tripid IS NULL 
									 THEN DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp),DATEPART(month, t.arrival_time_timestamp),DATEPART(day, t.arrival_time_timestamp),3,0,0,0,0) 
									 ELSE t_next.depart_time_timestamp END) > 480)  

			UNION ALL SELECT t.tripid, t.personid, t.tripnum, 		  				   		          'non-student + school trip' AS error_flag
				FROM trip_ref AS t JOIN trip_ref as t_next ON t.personid = t_next.personid AND t.tripnum + 1 = t_next.tripnum JOIN HHSurvey.person ON t.personid=person.personid 					
				WHERE t.d_purpose = 6		
					AND (person.student NOT IN(2,3,4) OR person.student IS NULL) AND person.age > 4)
			SELECT efc.error_flag, count(*) 
			FROM error_flag_compilation AS efc
			GROUP BY efc.error_flag;

		DROP TABLE IF EXISTS #dayends;





