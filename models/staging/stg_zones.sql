select
    location_id as zone_id,
    borough,
    zone        as zone_name,
    service_zone
from {{ source('nyc_taxi_raw', 'raw_taxi_zones') }}
