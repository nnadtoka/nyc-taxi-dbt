-- q1_3_longest_average_duration.sql
--
-- Question:
-- Which zones have the longest average trip duration?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metric:
-- avg_duration_min_7d represents average trip duration over
-- the trailing 7-day window.
--
-- Minimum recent activity: 5 trips in the trailing 7 days
-- to reduce noise from very low-volume zones.

SELECT
    zone_id,
    zone_name,
    borough,
    snapshot_date,
    trips_7d,
    avg_duration_min_7d
FROM dbt_taxi.fct_zone_daily_snapshot
WHERE snapshot_date = (
    SELECT MAX(snapshot_date)
    FROM dbt_taxi.fct_zone_daily_snapshot
    WHERE snapshot_date BETWEEN DATE '2024-01-01' AND DATE '2024-02-29'
)
AND trips_7d >= 5
AND avg_duration_min_7d IS NOT NULL
ORDER BY avg_duration_min_7d DESC
LIMIT 20;
