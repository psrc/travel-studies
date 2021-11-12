


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

UPDATE h
SET h.final_home_puma10=CONCAT('53',p.pumace10)
FROM HHSurvey.Household AS h JOIN ElmerGeo.dbo.BLOCK2010 AS b ON h.final_home_block=b.geoid10 JOIN ElmerGeo.dbo.REG10PUMA AS p ON b.Shape.STIntersects(p.Shape)=1
WHERE len(h.final_home_puma10)=5 

--update hhmember field

UPDATE HHSurvey.Trip 
SET hhmember_none=CASE WHEN travelers_hh>1 THEN 0 WHEN travelers_hh=1 THEN 1 ELSE NULL END
WHERE hhmember_none IS NULL;

UPDATE HHSurvey.Trip
SET hhmember1 =CASE WHEN hhmember1 IS NULL AND pernum =1 THEN personid ELSE hhmember1 END,
 hhmember2 =CASE WHEN hhmember2 IS NULL AND pernum =2 THEN personid ELSE hhmember2 END,
 hhmember3 =CASE WHEN hhmember3 IS NULL AND pernum =3 THEN personid ELSE hhmember3 END,
 hhmember4 =CASE WHEN hhmember4 IS NULL AND pernum =4 THEN personid ELSE hhmember4 END,
 hhmember5 =CASE WHEN hhmember5 IS NULL AND pernum =5 THEN personid ELSE hhmember5 END,
 hhmember6 =CASE WHEN hhmember6 IS NULL AND pernum =6 THEN personid ELSE hhmember6 END,
 hhmember7 =CASE WHEN hhmember7 IS NULL AND pernum =7 THEN personid ELSE hhmember7 END,
 hhmember8 =CASE WHEN hhmember8 IS NULL AND pernum =8 THEN personid ELSE hhmember8 END,
 hhmember9 =CASE WHEN hhmember9 IS NULL AND pernum =9 THEN personid ELSE hhmember9 END,
 hhmember10 =CASE WHEN hhmember10 IS NULL AND pernum =10 THEN personid ELSE hhmember10 END,
 hhmember11 =CASE WHEN hhmember11 IS NULL AND pernum =11 THEN personid ELSE hhmember11 END,
 hhmember12 =CASE WHEN hhmember12 IS NULL AND pernum =12 THEN personid ELSE hhmember12 END;

 --Remove invalid records from primary tables
SELECT * INTO HHSurvey.day_invalid_hh 
FROM HHSurvey.Day AS d
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE d.hhid=ti.hhid);
GO
DELETE d FROM HHSurvey.Day AS d
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE d.hhid=ti.hhid);
GO
SELECT * INTO HHSurvey.trip_invalid_hh 
FROM HHSurvey.Trip AS t
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE t.hhid=ti.hhid)
GO
DELETE t FROM HHSurvey.Trip AS t
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE t.hhid=ti.hhid);
GO
SELECT * INTO HHSurvey.person_invalid 
FROM HHSurvey.Person AS p
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE p.personid=ti.personid)
GO
DELETE p FROM HHSurvey.Person AS p
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE p.personid=ti.personid);
GO
SELECT * INTO HHSurvey.person_invalid_hh 
FROM HHSurvey.Person AS p
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE p.hhid=ti.hhid)
GO
DELETE p FROM HHSurvey.Person AS p
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE p.hhid=ti.hhid);
GO
SELECT * INTO HHSurvey.household_invalid 
FROM HHSurvey.Household AS h
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE h.hhid=ti.hhid);
GO
DELETE h FROM HHSurvey.Household AS h
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_invalid AS ti WHERE h.hhid=ti.hhid);
GO