-- q3_2_top_origin_destination_charges.sql
--
-- Question:
-- Which taxi pickup-to-drop-off pairs generate the most passenger charges?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metric:
-- Total passenger charges (total_amount) for each pickup-to-drop-off pair.
--
-- Purpose:
-- Identify the routes generating the highest passenger charges.

SELECT
    r.pickup_zone_id,
    p.zone_name AS pickup_zone,
    p.borough   AS pickup_borough,

    r.dropoff_zone_id,
    d.zone_name AS dropoff_zone,
    d.borough   AS dropoff_borough,

    ROUND(
        SUM(r.daily_total_amount),
        2
    ) AS total_passenger_charges

FROM dbt_taxi.int_zone_route_daily r

LEFT JOIN dbt_taxi.stg_zones p
    ON r.pickup_zone_id = p.zone_id

LEFT JOIN dbt_taxi.stg_zones d
    ON r.dropoff_zone_id = d.zone_id

WHERE r.trip_date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'

  -- Exclude routes with missing zone mappings.
  AND p.zone_name IS NOT NULL
  AND d.zone_name IS NOT NULL

GROUP BY
    r.pickup_zone_id,
    p.zone_name,
    p.borough,
    r.dropoff_zone_id,
    d.zone_name,
    d.borough

ORDER BY total_passenger_charges DESC

LIMIT 20;
