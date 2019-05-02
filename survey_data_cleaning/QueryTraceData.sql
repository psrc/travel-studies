SELECT tc1.tripid, tc1.traceid, DATEDIFF(Minute, tc0.collected_at, tc1.collected_at) AS legprior, DATEDIFF(Minute, tc1.collected_at, tc2.collected_at) AS legnext, 
    CASE WHEN ABS(tc1.heading - tc0.heading) > 180 THEN 360 - ABS(tc1.heading - tc0.heading) ELSE ABS(tc1.heading - tc0.heading) END AS turnprior,
    CASE WHEN ABS(tc2.heading - tc1.heading) > 180 THEN 360 - ABS(tc2.heading - tc1.heading) ELSE ABS(tc2.heading - tc1.heading) END AS turnnext
FROM trace as tc1 LEFT JOIN trace AS tc0 ON tc1.tripid = tc0.tripid AND tc1.traceid - 1 = tc0.traceid
                  LEFT JOIN trace AS tc2 ON tc1.tripid = tc2.tripid AND tc1.traceid + 1 = tc2.traceid 
WHERE DATEDIFF(Minute, tc0.collected_at, tc1.collected_at) > 5 AND tc1.heading <>-1 AND tc0.heading<>-1
    AND (CASE WHEN ABS(tc1.heading - tc0.heading) > 180 THEN 360 - ABS(tc1.heading - tc0.heading) ELSE ABS(tc1.heading - tc0.heading) END > 135
    OR CASE WHEN ABS(tc2.heading - tc1.heading) > 180 THEN 360 - ABS(tc2.heading - tc1.heading) ELSE ABS(tc2.heading - tc1.heading) END > 135)
ORDER BY tc1.tripid, tc1.collected_at;