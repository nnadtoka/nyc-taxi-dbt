-- Dataset profiling / exploration queries for the NYC taxi pipeline.
-- These are NOT models. `dbt run` ignores analyses/; `dbt compile` renders
-- them (resolving ref/source) into target/compiled/ so you can copy out the
-- runnable SQL. To run ad hoc against the container:
--   docker exec -i nyc-taxi psql -U postgres -f - < analyses/profiling.sql
-- Run individual blocks by pasting them into psql.

-- 1. Raw vs staged: how many rows did staging drop, and what fraction?
select
    (select count(*) from {{ source('nyc_taxi_raw', 'raw_yellow_tripdata') }}) as raw_rows,
    (select count(*) from {{ ref('stg_trips') }})                              as staged_rows,
    round(100.0 * (
        (select count(*) from {{ source('nyc_taxi_raw', 'raw_yellow_tripdata') }})
      - (select count(*) from {{ ref('stg_trips') }})
    ) / nullif((select count(*) from {{ source('nyc_taxi_raw', 'raw_yellow_tripdata') }}), 0), 2) as pct_dropped;

-- 2. Date span: are there out-of-month stragglers (TLC files leak adjacent months)?
select
    min(date(pickup_at))            as first_day,
    max(date(pickup_at))            as last_day,
    count(distinct date(pickup_at)) as distinct_days
from {{ ref('stg_trips') }};

-- 3. Zone coverage: how many of the ~262 taxi zones actually appear?
select count(distinct pickup_zone_id) as zones_with_trips
from {{ ref('stg_trips') }};

-- 4. Snapshot shape: rows, zones, day span.
select
    count(*)                as snapshot_rows,
    count(distinct zone_id) as zones,
    min(snapshot_date)      as first_snapshot,
    max(snapshot_date)      as last_snapshot
from {{ ref('fct_zone_daily_snapshot') }};

-- 5. Snapshot sparsity: actual rows vs dense zone-day grid.
--    The gap = zone-days with zero trips (missing rows the window silently skips).
select
    (select count(*) from {{ ref('fct_zone_daily_snapshot') }})                     as actual_rows,
    (select count(distinct zone_id) from {{ ref('fct_zone_daily_snapshot') }})
      * (select count(distinct snapshot_date) from {{ ref('fct_zone_daily_snapshot') }}) as dense_grid_rows;
