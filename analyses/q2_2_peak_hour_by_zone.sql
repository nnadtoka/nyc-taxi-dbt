-- q2_2_peak_hour_by_zone.sql
--
-- Question:
-- What is the peak hour for each zone?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Minimum zone activity:
-- 20 trips across the analysis period to reduce noise from
-- very low-volume zones.

WITH zone_totals AS (

    SELECT
        zone_id,
        SUM(hourly_trips) AS total_zone_trips
    FROM dbt_taxi.int_zone_hourly
    WHERE pickup_date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'
    GROUP BY zone_id
    HAVING SUM(hourly_trips) >= 20

),

hourly_demand AS (

    SELECT
        h.zone_id,
        h.pickup_hour,
        SUM(h.hourly_trips) AS total_trips
    FROM dbt_taxi.int_zone_hourly h
    INNER JOIN zone_totals z
        ON h.zone_id = z.zone_id
    WHERE h.pickup_date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'
    GROUP BY h.zone_id, h.pickup_hour

),

ranked AS (

    SELECT
        zone_id,
        pickup_hour,
        total_trips,
        ROW_NUMBER() OVER (
            PARTITION BY zone_id
            ORDER BY total_trips DESC, pickup_hour
        ) AS rn
    FROM hourly_demand

)

SELECT
    r.zone_id,
    z.zone_name,
    z.borough,
    r.pickup_hour,
    CASE
        WHEN r.pickup_hour BETWEEN 0 AND 5   THEN 'Overnight'
        WHEN r.pickup_hour BETWEEN 6 AND 9   THEN 'Morning'
        WHEN r.pickup_hour BETWEEN 10 AND 14 THEN 'Midday'
        WHEN r.pickup_hour BETWEEN 15 AND 20 THEN 'Afternoon / Evening Peak'
        WHEN r.pickup_hour BETWEEN 21 AND 23 THEN 'Late Evening'
    END AS time_of_day,
    r.total_trips
FROM ranked r
LEFT JOIN dbt_taxi.stg_zones z
    ON r.zone_id = z.zone_id
WHERE r.rn = 1
ORDER BY r.zone_id;