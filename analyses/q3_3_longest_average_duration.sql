-- q3_3_longest_average_duration.sql
--
-- Question:
-- Which high-volume pickup-to-drop-off pairs have the longest average duration?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metric:
-- Average valid trip duration for each pickup-to-drop-off pair.
--
-- Minimum volume:
-- Only routes with at least 100 valid trips are included to reduce
-- noise from low-volume routes.

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
        SUM(r.daily_duration_sum)
        / NULLIF(SUM(r.daily_valid_trips), 0),
        2
    ) AS avg_duration_min

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

ORDER BY avg_duration_min DESC

LIMIT 20;