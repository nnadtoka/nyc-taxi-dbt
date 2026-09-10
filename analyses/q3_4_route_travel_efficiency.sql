-- q3_4_route_travel_efficiency.sql
--
-- Question:
-- Which high-volume pickup-to-drop-off pairs have the lowest travel efficiency?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metric:
-- Average speed in miles per hour, calculated using only trips
-- with a valid duration.
--
-- Minimum volume:
-- Only routes with at least 100 valid trips are included.

SELECT
    r.pickup_zone_id,
    p.zone_name AS pickup_zone,
    p.borough   AS pickup_borough,

    r.dropoff_zone_id,
    d.zone_name AS dropoff_zone,
    d.borough   AS dropoff_borough,

    SUM(r.daily_trips) AS total_trips,

    SUM(r.daily_valid_trips) AS valid_trips,

    ROUND(
        SUM(r.daily_valid_distance_sum),
        2
    ) AS valid_distance_miles,

    ROUND(
        SUM(r.daily_duration_sum),
        2
    ) AS valid_duration_min,

    ROUND(
        SUM(r.daily_valid_distance_sum)
        / NULLIF(
            SUM(r.daily_duration_sum) / 60.0,
            0
        ),
        2
    ) AS average_speed_mph

FROM dbt_taxi.int_zone_route_daily r

LEFT JOIN dbt_taxi.stg_zones p
    ON r.pickup_zone_id = p.zone_id

LEFT JOIN dbt_taxi.stg_zones d
    ON r.dropoff_zone_id = d.zone_id

WHERE r.trip_date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'

  AND p.zone_name IS NOT NULL
  AND d.zone_name IS NOT NULL

GROUP BY
    r.pickup_zone_id,
    p.zone_name,
    p.borough,
    r.dropoff_zone_id,
    d.zone_name,
    d.borough

HAVING SUM(r.daily_valid_trips) >= 100

ORDER BY average_speed_mph ASC

LIMIT 20;