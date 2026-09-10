select
    zone_id,
    snapshot_date,
    trips_1d,
    trips_7d,
    trips_30d,
    avg_fare_7d,
    avg_fare_30d,
    avg_duration_min_7d
from dbt_taxi.fct_zone_daily_snapshot
where trips_1d > 0
and zone_id = 1
order by zone_id, snapshot_date
limit 20;
