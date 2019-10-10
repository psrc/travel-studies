/*  ADD to Rulesy somewhere, but substitute the conditions instead of the error flag */

UPDATE t
SET t.d_purpose = 1, nxt.o_purpose = 1
FROM HHSUrvey.trip AS t JOIN HHSurvey.Household AS h ON t.hhid = h.hhid JOIN HHSurvey.trip AS nxt ON t.personid = nxt.personid AND t.tripid +1 = nxt_t.tripid
WHERE EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid AND tef.error_flag = 'too long at dest')
AND t.dest_geog.STDistance(h.home_geog) < 100;

UPDATE t
SET t.mode_1 = pt.mode_1
FROM HHSurvey.Trip as t 
    JOIN HHSurvey.Trip as pt ON t.personid = pt.personid AND t.tripid -1 = pt.tripid
    JOIN HHSurvey.Trip as nt ON t.personid = nt.personid AND t.tripid +1 = nt.tripid
    LEFT JOIN HHSurvey.fnVariableLookup('mode_1') as v ON t.mode_1 = v.code
WHERE pt.mode_1 = nt.mode_1 AND (v.label LIKE 'Missing%' OR t.mode_1 IS NULL OR t.mode_1 = 0) AND pt.daynum = t.daynum AND t.daynum = nt.daynum
    AND EXISTS (SELECT 1 FROM HHSurvey.automodes WHERE automodes.mode_id = pt.mode_1) --AND t.speed_mph between 2 AND 85;

/* Use schools layer in Elmer to determine K12 and recode adults to PUDO during school day with some turnaround limit; otherwise 'family activity'*/

UPDATE t
SET t.o_purpose = 55 
FROM HHSurvey.Trip AS t
WHERE t.d_purpose = 55 AND EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid AND tef.error_flag = 'initial trip purpose missing');

--recode as 52 any non-home overnight in a local residential area.  If out of state, reclass as 97

UPDATE t
SET t.psrc_comment = 'EXAMINE -UNLINK?'
FROM HHSurvey.Trip AS t 
WHERE t.revision_code LIKE '%8,%' AND EXISTS (SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE t.recid = tef.recid AND tef.error_flag LIKE 'same dest as %') AND t.psrc_comment IS NULL;

/* delete loop trips that have no activity time and no travel time -- these are probably signals bouncing around the neighborhood ?? */

/* Will need to run trip linking again on code 60 trips only --supervised match */
/* Link strings of work-related or work trips with movement < .25mi? */


UPDATE t
SET t.driver = 995
FROM HHSurvey.Trip AS t 
WHERE NOT EXISTS (SELECT 1 FROM STRING_SPLIT(t.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes)) 
AND EXISTS(SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid AND tef.error_flag = 'underage driver');

UPDATE t
SET t.driver = 995
FROM HHSurvey.Trip AS t 
WHERE NOT EXISTS (SELECT 1 FROM STRING_SPLIT(t.modes,',') WHERE VALUE IN(SELECT mode_id FROM HHSurvey.automodes)) 
AND EXISTS(SELECT 1 FROM HHSurvey.trip_error_flags AS tef WHERE tef.recid = t.recid AND tef.error_flag = 'unlicensed driver');

UNDELETE recid 44734  loop trip work?