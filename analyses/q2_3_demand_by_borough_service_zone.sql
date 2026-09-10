-- q2_3_demand_by_borough_service_zone.sql

SELECT
    z.borough,
    z.service_zone,
    h.pickup_hour,
    SUM(h.hourly_trips) AS total_trips
FROM dbt_taxi.int_zone_hourly h
LEFT JOIN dbt_taxi.stg_zones z
    ON h.zone_id = z.zone_id
WHERE h.pickup_date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'
GROUP BY
    z.borough,
    z.service_zone,
    h.pickup_hour
ORDER BY
    z.borough,
    z.service_zone,
    h.pickup_hour;
