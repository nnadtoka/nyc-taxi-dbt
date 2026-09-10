-- Question:
-- Which zones have the highest trailing 7-day activity?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metric:
-- trips_7d represents the total number of trips originating
-- from each zone during the trailing 7-day window.
--
-- Purpose:
-- Identify the zones with the highest recent demand.

select
    zone_id,
    zone_name,
    borough,
    snapshot_date,
    trips_7d
from dbt_taxi.fct_zone_daily_snapshot
WHERE snapshot_date = (
    SELECT MAX(snapshot_date)
    FROM dbt_taxi.fct_zone_daily_snapshot
    WHERE snapshot_date BETWEEN DATE '2024-01-01' AND DATE '2024-02-29'
)
order by trips_7d desc
limit 20;
