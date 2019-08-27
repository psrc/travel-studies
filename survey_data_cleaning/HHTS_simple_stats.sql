--Modes summary
    WITH cte AS
    (SELECT t.personid, (SELECT MAX(member) FROM (VALUES (t.mode_1), (t.mode_2),(t.mode_3),(t.mode_4)) AS modes(member) WHERE member <> 97) AS mode_x FROM HHSurvey.Trip AS t)
    SELECT cte.mode_x, count(*) AS tripcount
    FROM cte 
    GROUP BY cte.mode_x ORDER BY cte.mode_x;

--Purposes summary
    SELECT t.dest_purpose, count(t.tripid) FROM HHSurvey.Trip AS t GROUP BY t.dest_purpose;

--Distance category summary
    WITH cte AS (SELECT round(t.trip_path_distance,0) AS trip_miles FROM HHSurvey.Trip AS t)
    SELECT CASE WHEN cte.trip_miles < 10  THEN ROUND(cte.trip_miles,0)
                WHEN cte.trip_miles < 100 THEN ROUND(cte.trip_miles,-1)
                WHEN cte.trip_miles < 1000 THEN ROUND(cte.trip_miles,-2) 
                WHEN cte.trip_miles > 1000 THEN ROUND(cte.trip_miles,-3)
                END,
                count(*) AS dist_count
    FROM cte /*WHERE COALESCE(dbo.RgxFind(t.revision_code,'5,',1),0) = 0*/
    GROUP BY CASE WHEN cte.trip_miles < 10  THEN ROUND(cte.trip_miles,0)
                WHEN cte.trip_miles < 100 THEN ROUND(cte.trip_miles,-1)
                WHEN cte.trip_miles < 1000 THEN ROUND(cte.trip_miles,-2) 
                WHEN cte.trip_miles > 1000 THEN ROUND(cte.trip_miles,-3)
                  END
    ORDER BY CASE WHEN cte.trip_miles < 10  THEN ROUND(cte.trip_miles,0)
                WHEN cte.trip_miles < 100 THEN ROUND(cte.trip_miles,-1)
                WHEN cte.trip_miles < 1000 THEN ROUND(cte.trip_miles,-2) 
                WHEN cte.trip_miles > 1000 THEN ROUND(cte.trip_miles,-3)
                END;

--Trip error code count
SELECT error_flag, [1] AS rMove, [2] AS rSurvey
FROM
(SELECT t.hhgroup, tef.error_flag, t.recid
FROM HHSurvey.trip_error_flags AS tef JOIN HHSurvey.Trip as t ON t.recid=tef.recid) AS SourceTable
PIVOT
(
 count(recid)
 FOR hhgroup IN ([1], [2])
) AS pvt
ORDER BY pvt.error_flag;