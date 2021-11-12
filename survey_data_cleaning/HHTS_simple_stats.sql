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


		SELECT error_flag, /*pivoted.[1] AS rMove,*/ pivoted.[2] AS rSurvey
		FROM (SELECT tef.error_flag, t.data_source AS category, count(t.recid) AS n
				FROM HHSurvey.Trip AS t 
					JOIN HHSurvey.trip_error_flags AS tef ON t.recid = tef.recid 
				WHERE t.psrc_resolved IS NULL
				GROUP BY tef.error_flag, t.data_source) AS source
		PIVOT (SUM(n) FOR category IN ([1], [2])) AS pivoted
		ORDER BY pivoted.[1] DESC;

--Revision Code count

			  SELECT 1, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b1,',1)=1
		UNION SELECT 2, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b2,',1)=1
		UNION SELECT 3, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b3,',1)=1
		UNION SELECT 4, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b4,',1)=1
		UNION SELECT 5, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b5b?,',1)=1
		UNION SELECT 6, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b6,',1)=1
		UNION SELECT 7, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b7,',1)=1
		UNION SELECT 8, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b8,',1)=1
		UNION SELECT 9, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b9,',1)=1
		UNION SELECT 10, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b10,',1)=1
		UNION SELECT 11, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b11,',1)=1
		UNION SELECT 12, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b12,',1)=1
		UNION SELECT 13, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b13,',1)=1
		UNION SELECT 14, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b14,',1)=1
		UNION SELECT 15, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'15,',1)=1
		UNION SELECT 16, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b16,',1)=1
		UNION SELECT 17, count(*) FROM HHSurvey.Trip AS t WHERE Elmer.dbo.rgx_find(t.revision_code,'\b17,',1)=1;