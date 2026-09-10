-- q2_3_top_origin_destination_pairs.sql
--
-- Question:
-- Which taxi origin-to-destination pairs have the most activity
-- and passenger charges?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metrics:
-- Total trips and total passenger charges (total_amount).
--
-- Purpose:
-- Identify the most frequently traveled and highest-value
-- pickup-to-drop-off pairs.

SELECT
    t.pickup_zone_id,
    p.zone_name AS pickup_zone,
    p.borough   AS pickup_borough,

    t.dropoff_zone_id,
    d.zone_name AS dropoff_zone,
    d.borough   AS dropoff_borough,

    COUNT(*) AS total_trips,
    ROUND(SUM(t.total_amount), 2) AS total_amount

FROM dbt_taxi.stg_trips t

LEFT JOIN dbt_taxi.stg_zones p
    ON t.pickup_zone_id = p.zone_id

LEFT JOIN dbt_taxi.stg_zones d
    ON t.dropoff_zone_id = d.zone_id

WHERE t.pickup_at::date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'
    AND p.zone_name IS NOT NULL
    AND d.zone_name IS NOT NULL

GROUP BY
    t.pickup_zone_id,
    p.zone_name,
    p.borough,
    t.dropoff_zone_id,
    d.zone_name,
    d.borough

ORDER BY total_trips DESC
LIMIT 20;
