select
    pickup_zone_id        as zone_id,
    date(pickup_at)       as trip_date,
    count(*)              as daily_trips,
    sum(fare_amount)      as daily_fare_sum,
    sum(duration_min)     as daily_duration_sum
from {{ ref('stg_trips') }}
group by 1, 2
