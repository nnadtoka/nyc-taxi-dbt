\echo '=== Q1: Raw vs staged — how many rows dropped, and what fraction? ==='
select
    (select count(*) from public.raw_yellow_tripdata) as raw_rows,
    (select count(*) from dbt_taxi.stg_trips)          as staged_rows,
    round(100.0 * (
        (select count(*) from public.raw_yellow_tripdata)
      - (select count(*) from dbt_taxi.stg_trips)
    ) / nullif((select count(*) from public.raw_yellow_tripdata), 0), 2) as pct_dropped;

\echo ''
\echo '=== Q2: Date span — any out-of-month stragglers? ==='
select min(date(pickup_at)) as first_day,
       max(date(pickup_at)) as last_day,
       count(distinct date(pickup_at)) as distinct_days
from dbt_taxi.stg_trips;

\echo ''
\echo '=== Q3: Zone coverage — how many of the ~262 zones appear? ==='
select count(distinct pickup_zone_id) as zones_with_trips
from dbt_taxi.stg_trips;

\echo ''
\echo '=== Q4: Snapshot shape — rows, zones, day span ==='
select count(*) as snapshot_rows,
       count(distinct zone_id) as zones,
       min(snapshot_date) as first_snapshot,
       max(snapshot_date) as last_snapshot
from dbt_taxi.fct_zone_daily_snapshot;

\echo ''
\echo '=== Q5: Snapshot sparsity — actual rows vs dense zone-day grid ==='
select
    (select count(*) from dbt_taxi.fct_zone_daily_snapshot) as actual_rows,
    (select count(distinct zone_id) from dbt_taxi.fct_zone_daily_snapshot)
      * (select count(distinct snapshot_date) from dbt_taxi.fct_zone_daily_snapshot) as dense_grid_rows;
