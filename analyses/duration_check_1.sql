select
    min(duration_min) as min_duration,
    avg(duration_min) as avg_duration,
    max(duration_min) as max_duration
from dbt_taxi.stg_trips
where duration_min > 0;
