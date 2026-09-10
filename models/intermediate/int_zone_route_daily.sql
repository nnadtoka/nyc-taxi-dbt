{{ config(materialized='view') }}

select
    pickup_zone_id,
    dropoff_zone_id,
    date(pickup_at) as trip_date,

    count(*) as daily_trips,

    sum(total_amount) as daily_total_amount,

    sum(fare_amount) as daily_fare_sum,

    sum(
        case
            when is_valid_duration then duration_min
            else 0
        end
    ) as daily_duration_sum,

    sum(trip_distance) as daily_distance_sum,

    count(*) filter (
        where not is_valid_duration
    ) as invalid_duration_trips

from {{ ref('stg_trips') }}

where pickup_zone_id is not null
  and dropoff_zone_id is not null

group by
    pickup_zone_id,
    dropoff_zone_id,
    date(pickup_at)
