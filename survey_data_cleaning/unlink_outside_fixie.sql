			DELETE FROM HHSurvey.Trip WHERE recid IN(66098,11707,50038,52257,52617,54140,61900,4669);
				ALTER TABLE HHSurvey.trip DISABLE TRIGGER tr_trip;

				SET IDENTITY_INSERT HHSurvey.Trip ON;
				
                WITH cte AS (SELECT tr.recid, t0.*FROM dbo.[4_Trip] AS t0 JOIN HHSurvey.tmpRecid AS tr ON t0.tripid = tr.tripid
                WHERE tr.recid IN(66098,66099,66100,11707,11708,11709,50038,50039,50040,52257,52258,52617,52618,54140,54141,54142,61900,61901,4669,4670,4671))
                INSERT INTO HHSurvey.Trip (
					recid
					,hhid
					,personid
					,pernum
					,tripid
					,tripnum
					,traveldate
					,daynum
					,dayofweek
					,hhgroup
					,copied_trip
					,completed_at
					,revised_at
					,revised_count
					,svy_complete
					,depart_time_mam
					,depart_time_hhmm
					,depart_time_timestamp
					,arrival_time_mam
					,arrival_time_hhmm
					,arrival_time_timestamp
					,origin_lat
					,origin_lng
					,dest_lat
					,dest_lng
					,trip_path_distance
					,google_duration
					,reported_duration
					,hhmember1
					,hhmember2
					,hhmember3
					,hhmember4
					,hhmember5
					,hhmember6
					,hhmember7
					,hhmember8
					,travelers_hh
					,travelers_nonhh
					,travelers_total
					,o_purpose
					,o_purpose_other
					,o_purp_cat
					,d_purpose
					,d_purpose_other
					,d_purp_cat
					,mode_1
					,mode_2
					,mode_3
					,mode_4
					,mode_type
					,driver
					,pool_start
					,change_vehicles
					,park_ride_area_start
					,park_ride_area_end
					,park_ride_lot_start
					,park_ride_lot_end
					,toll
					,toll_pay
					,taxi_type
					,taxi_pay
					,bus_type
					,bus_pay
					,bus_cost_dk
					,ferry_type
					,ferry_pay
					,ferry_cost_dk
					,air_type
					,air_pay
					,airfare_cost_dk
					,mode_acc
					,mode_egr
					,park
					,park_type
					,park_pay
					,transit_system_1
					,transit_system_2
					,transit_system_3
					,transit_system_4
					,transit_system_5
					,transit_system_6
					,transit_line_1
					,transit_line_2
					,transit_line_3
					,transit_line_4
					,transit_line_5
					,transit_line_6
					,speed_mph
					,user_added
					,user_merged
					,user_split
					,analyst_merged
					,analyst_split
					,analyst_split_loop
					,quality_flag
					,nonproxy_derived_trip
					,psrc_comment
					,origin_geog
					,dest_geog)
				SELECT recid
					,hhid
					,personid
					,pernum
					,tripid
					,tripnum
					,traveldate
					,daynum
					,dayofweek
					,hhgroup
					,copied_trip
					,completed_at
					,revised_at
					,revised_count
					,svy_complete
					,depart_time_mam
					,depart_time_hhmm
					,depart_time_timestamp
					,arrival_time_mam
					,arrival_time_hhmm
					,arrival_time_timestamp
					,origin_lat
					,origin_lng
					,dest_lat
					,dest_lng
					,trip_path_distance
					,google_duration
					,reported_duration
					,hhmember1
					,hhmember2
					,hhmember3
					,hhmember4
					,hhmember5
					,hhmember6
					,hhmember7
					,hhmember8
					,travelers_hh
					,travelers_nonhh
					,travelers_total
					,o_purpose
					,o_purpose_other
					,o_purp_cat
					,d_purpose
					,d_purpose_other
					,d_purp_cat
					,mode_1
					,mode_2
					,mode_3
					,mode_4
					,mode_type
					,driver
					,pool_start
					,change_vehicles
					,park_ride_area_start
					,park_ride_area_end
					,park_ride_lot_start
					,park_ride_lot_end
					,toll
					,toll_pay
					,taxi_type
					,taxi_pay
					,bus_type
					,bus_pay
					,bus_cost_dk
					,ferry_type
					,ferry_pay
					,ferry_cost_dk
					,air_type
					,air_pay
					,airfare_cost_dk
					,mode_acc
					,mode_egr
					,park
					,park_type
					,park_pay
					,transit_system_1
					,transit_system_2
					,transit_system_3
					,transit_system_4
					,transit_system_5
					,transit_system_6
					,transit_line_1
					,transit_line_2
					,transit_line_3
					,transit_line_4
					,transit_line_5
					,transit_line_6
					,speed_mph
					,user_added
					,user_merged
					,user_split
					,analyst_merged
					,analyst_split
					,analyst_split_loop
					,quality_flag
					,nonproxy_derived_trip
					,'restored'
					,geography::STGeomFromText('POINT(' + CAST(origin_lng    AS VARCHAR(20)) + ' ' + CAST(origin_lat 	AS VARCHAR(20)) + ')', 4326)
					,geography::STGeomFromText('POINT(' + CAST(dest_lng 	  AS VARCHAR(20)) + ' ' + CAST(dest_lat 	AS VARCHAR(20)) + ')', 4326)
					FROM cte;

				DELETE tid
				FROM HHSurvey.trip_ingredients_done AS tid 
				WHERE tid.recid IN(66098,66099,66100,11707,11708,11709,50038,50039,50040,52257,52258,52617,52618,54140,54141,54142,61900,61901,4669,4670,4671);

		EXECUTE HHSurvey.tripnum_update;

		WITH cte AS
		(SELECT t0.personid, t0.depart_time_timestamp AS start_stamp
				FROM HHSurvey.Trip AS t0 
				WHERE t0.tripnum = 1 AND t0.depart_time_timestamp IS NOT NULL)
		UPDATE t SET
			t.depart_time_hhmm  = FORMAT(t.depart_time_timestamp,N'hh\:mm tt','en-US'),
			t.arrival_time_hhmm = FORMAT(t.arrival_time_timestamp,N'hh\:mm tt','en-US'), 
			t.depart_time_mam   = DATEDIFF(minute, DATETIME2FROMPARTS(DATEPART(year,t.depart_time_timestamp),DATEPART(month,t.depart_time_timestamp),DATEPART(day,t.depart_time_timestamp),0,0,0,0,0),t.depart_time_timestamp),
			t.arrival_time_mam  = DATEDIFF(minute, DATETIME2FROMPARTS(DATEPART(year, t.arrival_time_timestamp), DATEPART(month,t.arrival_time_timestamp), DATEPART(day,t.arrival_time_timestamp),0,0,0,0,0),t.arrival_time_timestamp),
			t.daynum = 1 + DATEDIFF(day, cte.start_stamp, (CASE WHEN DATEPART(Hour, t.depart_time_timestamp) < 3 
																THEN CAST(DATEADD(Hour, -3, t.depart_time_timestamp) AS DATE)
																ELSE CAST(t.depart_time_timestamp AS DATE) END)),
			t.speed_mph			= CASE WHEN (t.trip_path_distance > 0 AND (CAST(DATEDIFF_BIG (second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/3600) > 0) 
										THEN  t.trip_path_distance / (CAST(DATEDIFF_BIG (second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/3600) 
										ELSE 0 END,
			t.reported_duration	= CAST(DATEDIFF(second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/60,
			--t.travel_time 	= CAST(DATEDIFF(second, t.depart_time_timestamp, t.arrival_time_timestamp) AS numeric)/60,  -- for edited records, this should be the accepted travel duration			   	
			t.dayofweek 		= DATEPART(dw, DATEADD(hour, 3, t.depart_time_timestamp)),
			t.dest_geog = geography::STGeomFromText('POINT(' + CAST(t.dest_lng AS VARCHAR(20)) + ' ' + CAST(t.dest_lat AS VARCHAR(20)) + ')', 4326), 
			t.origin_geog  = geography::STGeomFromText('POINT(' + CAST(t.origin_lng AS VARCHAR(20)) + ' ' + CAST(t.origin_lat AS VARCHAR(20)) + ')', 4326) 
		FROM HHSurvey.trip AS t JOIN cte ON t.personid = cte.personid
		WHERE t.personid IN(19103829102,19104719802,19103653401,19103798201,19100322701,19103943301,19100834102,19102358401,19104973303);

		UPDATE next_t SET
			next_t.o_purpose = t.d_purpose
			FROM HHSurvey.trip AS t JOIN HHSurvey.trip AS next_t ON t.personid = next_t.personid AND t.tripnum + 1 = next_t.tripnum
			WHERE t.personid IN(19103829102,19104719802,19103653401,19103798201,19100322701,19103943301,19100834102,19102358401,19104973303);


				EXECUTE HHSurvey.generate_error_flags;
				

			ALTER TABLE HHSurvey.trip ENABLE TRIGGER [tr_trip];
			SET IDENTITY_INSERT HHSurvey.Trip OFF;
