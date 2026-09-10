{{ config(materialized='view') }}

select
    pickup_zone_id                  as zone_id,
    date(pickup_at)                 as pickup_date,
    extract(hour from pickup_at)::int as pickup_hour,

    count(*)                        as hourly_trips,

    sum(fare_amount)                as hourly_fare_sum,
    sum(total_amount)              as hourly_total_amount,

    sum(
        case
            when is_valid_duration then duration_min
            else 0
        end
    )                               as hourly_duration_sum,

    sum(trip_distance)              as hourly_distance_sum,

    count(*) filter (
        where not is_valid_duration
    )                               as invalid_duration_trips

from {{ ref('stg_trips') }}

group by 1, 2, 3
