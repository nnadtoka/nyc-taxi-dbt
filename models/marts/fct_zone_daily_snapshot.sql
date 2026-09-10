with daily as (
    select * from {{ ref('int_zone_daily') }}
),
snapshot as (
    select
        zone_id,
        trip_date as snapshot_date,
        daily_trips as trips_1d,
        sum(daily_trips) over w7  as trips_7d,
        sum(daily_trips) over w30 as trips_30d,
        round(sum(daily_fare_sum) over w7
              / nullif(sum(daily_trips) over w7, 0), 2)  as avg_fare_7d,
        round(sum(daily_fare_sum) over w30
              / nullif(sum(daily_trips) over w30, 0), 2) as avg_fare_30d,
        round(sum(daily_duration_sum) over w7
              / nullif(sum(daily_trips) over w7, 0), 2)  as avg_duration_min_7d
    from daily
    window
        w7  as (partition by zone_id order by trip_date
                range between interval '6 days'  preceding and current row),
        w30 as (partition by zone_id order by trip_date
                range between interval '29 days' preceding and current row)
)
select
    s.*,
    z.borough,
    z.zone_name
from snapshot s
left join {{ ref('stg_zones') }} z on s.zone_id = z.zone_id
