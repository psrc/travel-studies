SELECT COUNT(*) AS adult_workers
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
;

SELECT COUNT(*) AS adult_workers
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
  AND workplace IN ('Usually the same location (outside home)',
                    'Telework some days and travel to a work location some days')
;

SELECT COUNT(*) AS workers_with_work_coords
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
  AND workplace IN ('Usually the same location (outside home)',
                    'Telework some days and travel to a work location some days')
  AND work_lng IS NOT NULL
;

SELECT workplace, COUNT(*) AS workers_with_work_coords
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
  AND work_lng IS NOT NULL
GROUP BY workplace
;

SELECT survey_year, workplace, COUNT(*) AS workers_with_work_coords
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
  AND work_lng IS NOT NULL
GROUP BY survey_year, workplace
ORDER BY survey_year
;

SELECT DISTINCT survey_year, workplace
FROM [Elmer].[HHSurvey].[v_persons]
ORDER BY survey_year, workplace ASC
;

SELECT DISTINCT survey_year, telecommute_freq
FROM [Elmer].[HHSurvey].[v_persons]
ORDER BY survey_year, telecommute_freq ASC
;

SELECT household_id, person_id, work_lng, work_lat
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
  AND work_lng IS NOT NULL
  AND workplace IN ('Usually the same location (outside home)', 'Telework some days and travel to a work location some days')
;

SELECT p.household_id, p.person_id, h.final_home_lng, h.final_home_lat
FROM [Elmer].[HHSurvey].[v_persons] AS p
  INNER JOIN Elmer.HHSurvey.v_households AS h ON p.household_id = h.household_id
WHERE p.worker <> 'No jobs'
  AND p.age_category <> 'Under 18 years'
  AND p.work_lng IS NOT NULL
  AND p.workplace IN ('Usually the same location (outside home)', 'Telework some days and travel to a work location some days')
;

SELECT *, dbo.ToXY(work_lng, work_lat) AS work_geom
INTO #workers
FROM [Elmer].[HHSurvey].[v_persons]
WHERE worker <> 'No jobs'
  AND age_category <> 'Under 18 years'
  AND work_lng IS NOT NULL
  AND workplace IN ('Usually the same location (outside home)', 'Telework some days and travel to a work location some days')
;

SELECT CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END AS survey,
       ISNULL(reg.cnty_name, 'Out of Region') AS county,
       COUNT(*) AS workers_with_work_coords
FROM #workers AS w
    LEFT JOIN ElmerGeo.dbo.psrc_region_evw AS reg ON w.work_geom.STIntersects(reg.Shape) = 1
GROUP BY CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END, reg.cnty_name
ORDER BY CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END ASC, reg.cnty_name ASC
;

SELECT CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END AS survey,
       ISNULL(reg.cnty_name, 'Out of Region') AS county,
       COUNT(*) AS telecommuters
FROM #workers AS w
    LEFT JOIN ElmerGeo.dbo.psrc_region_evw AS reg ON w.work_geom.STIntersects(reg.Shape) = 1
WHERE w.telecommute_freq IN ('1 day a week', '2 days a week', '3 days a week',
                           '4 days a week', '5 days a week', '6-7 days a week',
                           '1-2 days', '3-4 days', '5+ days')
GROUP BY CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END, reg.cnty_name
ORDER BY CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END ASC, reg.cnty_name ASC
;

SELECT CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END AS survey,
       CASE WHEN reg.juris = 'Seattle' THEN 'Seattle'
            WHEN reg.juris IN ('Bellevue', 'Redmond') THEN 'Bellevue & Redmond'
            ELSE 'Rest of King Co.' END AS juris,
       COUNT(*) AS telecommuters_in_king
FROM #workers AS w
    LEFT JOIN ElmerGeo.dbo.psrc_region_evw AS reg ON w.work_geom.STIntersects(reg.Shape) = 1
WHERE reg.cnty_name = 'King'
    AND w.telecommute_freq IN ('1 day a week', '2 days a week', '3 days a week',
                           '4 days a week', '5 days a week', '6-7 days a week',
                           '1-2 days', '3-4 days', '5+ days')
GROUP BY CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END,
         CASE WHEN reg.juris = 'Seattle' THEN 'Seattle'
            WHEN reg.juris IN ('Bellevue', 'Redmond') THEN 'Bellevue & Redmond'
            ELSE 'Rest of King Co.' END
ORDER BY CASE WHEN w.survey_year IN (2017, 2019) THEN '2017/2019' ELSE '2021' END ASC,
         CASE WHEN reg.juris = 'Seattle' THEN 'Seattle'
            WHEN reg.juris IN ('Bellevue', 'Redmond') THEN 'Bellevue & Redmond'
            ELSE 'Rest of King Co.' END ASC
;
