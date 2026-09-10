with source as (
    select * from {{ source('nyc_taxi_raw', 'raw_yellow_tripdata') }}
)
select
    vendor_id,
    pickup_datetime                                              as pickup_at,
    dropoff_datetime                                             as dropoff_at,
    pu_location_id                                               as pickup_zone_id,
    do_location_id                                               as dropoff_zone_id,
    passenger_count::int                                         as passenger_count,
    trip_distance,
    fare_amount,
    total_amount,
    extract(epoch from (dropoff_datetime - pickup_datetime))/60.0 as duration_min
from source
where pickup_datetime is not null
  and dropoff_datetime is not null
  and dropoff_datetime > pickup_datetime
  and fare_amount  >= 0
  and total_amount >= 0
