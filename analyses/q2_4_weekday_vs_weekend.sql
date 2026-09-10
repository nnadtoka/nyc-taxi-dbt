-- q2_4_weekday_vs_weekend.sql
--
-- Question:
-- Do weekday and weekend demand patterns differ?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Method:
-- Compare average trips per day by hour for weekdays versus weekends.
-- Only complete Monday-Sunday calendar weeks are included, so each
-- week contributes exactly 5 weekdays and 2 weekend days.
--
-- Difference:
-- Weekend minus weekday average daily trips.
--
-- Percentage:
-- Weekend difference relative to weekday average daily trips.

WITH date_range AS (

    SELECT
        DATE '2023-12-31' AS start_date,
        DATE '2024-02-29' AS end_date

),

complete_weeks AS (

    SELECT
        date_day
    FROM dbt_taxi.int_dim_date
    CROSS JOIN date_range
    WHERE date_day BETWEEN start_date AND end_date
      AND date_day >= DATE '2024-01-01'
      AND date_day + INTERVAL '6 days' <= end_date

),

hourly AS (

    SELECT
        CASE
            WHEN EXTRACT(ISODOW FROM h.pickup_date) IN (6, 7)
                THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        h.pickup_hour,
        SUM(h.hourly_trips) AS total_trips
    FROM dbt_taxi.int_zone_hourly h
    INNER JOIN complete_weeks d
        ON h.pickup_date = d.date_day
    GROUP BY 1, 2

),

day_counts AS (

    SELECT
        COUNT(*) FILTER (
            WHERE EXTRACT(ISODOW FROM date_day) BETWEEN 1 AND 5
        ) AS weekday_days,

        COUNT(*) FILTER (
            WHERE EXTRACT(ISODOW FROM date_day) IN (6, 7)
        ) AS weekend_days

    FROM complete_weeks

),

pivoted AS (

    SELECT
        pickup_hour,

        SUM(total_trips) FILTER (
            WHERE day_type = 'Weekday'
        ) AS weekday_trips,

        SUM(total_trips) FILTER (
            WHERE day_type = 'Weekend'
        ) AS weekend_trips

    FROM hourly
    GROUP BY pickup_hour

)

SELECT
    p.pickup_hour,

    -- Raw totals across the complete weeks
    p.weekday_trips,
    p.weekend_trips,

    -- Average trips per day
    ROUND(
        p.weekday_trips / NULLIF(d.weekday_days, 0),
        1
    ) AS avg_weekday_trips,

    ROUND(
        p.weekend_trips / NULLIF(d.weekend_days, 0),
        1
    ) AS avg_weekend_trips,

    -- Difference in average daily demand
    ROUND(
        (p.weekend_trips / NULLIF(d.weekend_days, 0))
        - (p.weekday_trips / NULLIF(d.weekday_days, 0)),
        1
    ) AS weekend_vs_weekday_diff,

    -- Percentage difference in average daily demand
    ROUND(
        100.0 * (
            (p.weekend_trips / NULLIF(d.weekend_days, 0))
            - (p.weekday_trips / NULLIF(d.weekday_days, 0))
        )
        / NULLIF(
            p.weekday_trips / NULLIF(d.weekday_days, 0),
            0
        ),
        1
    ) AS weekend_vs_weekday_pct

FROM pivoted p
CROSS JOIN day_counts d
ORDER BY p.pickup_hour;
