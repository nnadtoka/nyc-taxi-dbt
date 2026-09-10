{{ config(materialized='table') }}

with zones as (

    select distinct zone_id
    from {{ ref('int_zone_daily') }}

),

zone_date_grid as (

    select
        z.zone_id,
        d.date_day as trip_date
    from zones z
    cross join {{ ref('int_dim_date') }} d

),

daily as (

    select
        g.zone_id,
        g.trip_date,
        coalesce(d.daily_trips, 0)         as daily_trips,
        coalesce(d.daily_fare_sum, 0)      as daily_fare_sum,
        coalesce(d.daily_duration_sum, 0)  as daily_duration_sum,
        coalesce(d.daily_distance_sum, 0)  as daily_distance_sum,
        coalesce(d.daily_total_amount, 0)  as daily_total_amount
    from zone_date_grid g
    left join {{ ref('int_zone_daily') }} d
        on g.zone_id = d.zone_id
        and g.trip_date = d.trip_date

),

snapshot as (

    select
        zone_id,
        trip_date as snapshot_date,

        daily_trips as trips_1d,

        sum(daily_trips) over w7  as trips_7d,
        sum(daily_trips) over w30 as trips_30d,

        round(
            sum(daily_fare_sum) over w7
            / nullif(sum(daily_trips) over w7, 0),
            2
        ) as avg_fare_7d,

        round(
            sum(daily_fare_sum) over w30
            / nullif(sum(daily_trips) over w30, 0),
            2
        ) as avg_fare_30d,

        round(
            sum(daily_duration_sum) over w7
            / nullif(sum(daily_trips) over w7, 0),
            2
        ) as avg_duration_min_7d

    from daily

    window
        w7 as (
            partition by zone_id
            order by trip_date
            range between interval '6 days' preceding and current row
        ),

        w30 as (
            partition by zone_id
            order by trip_date
            range between interval '29 days' preceding and current row
        )

)

select
    s.*,
    z.borough,
    z.zone_name
from snapshot s
left join {{ ref('stg_zones') }} z
    on s.zone_id = z.zone_id