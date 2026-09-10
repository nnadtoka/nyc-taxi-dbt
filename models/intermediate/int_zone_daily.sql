select
    pickup_zone_id        as zone_id,
    date(pickup_at)       as trip_date,
    count(*)              as daily_trips,
    sum(fare_amount)      as daily_fare_sum,
    count(*) filter (
        where not is_valid_duration
    )                     as invalid_duration_trips,
    sum(
        case
            when is_valid_duration then duration_min
            else 0
        end
    ) as daily_duration_sum,
    sum(trip_distance)    as daily_distance_sum,
    sum(total_amount)     as daily_total_amount
from {{ ref('stg_trips') }}
group by 1, 2
