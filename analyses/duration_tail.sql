select
    percentile_cont(0.50) within group (order by duration_min) as p50,
    percentile_cont(0.90) within group (order by duration_min) as p90,
    percentile_cont(0.95) within group (order by duration_min) as p95,
    percentile_cont(0.99) within group (order by duration_min) as p99,
    percentile_cont(0.999) within group (order by duration_min) as p999,
    max(duration_min) as max_duration
from dbt_taxi.stg_trips
where duration_min > 0;
