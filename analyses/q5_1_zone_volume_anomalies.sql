-- q5_1_zone_volume_anomalies.sql
--
-- Question:
-- Which zones have unusually high or low trip volume?
--
-- Recent period:
-- 2024-02-23 through 2024-02-29 (latest 7 days)
--
-- Baseline:
-- Preceding 23 days, 2024-01-31 through 2024-02-22
--
-- Comparison:
-- Recent average daily trips versus baseline average daily trips.
--
-- Because fct_zone_daily_snapshot is built from a complete zone × date
-- spine, days with no activity are represented with trips_1d = 0.

WITH recent AS (

    SELECT
        zone_id,
        zone_name,
        borough,
        SUM(trips_1d) AS recent_7d_trips,
        AVG(trips_1d) AS recent_avg_daily_trips
    FROM dbt_taxi.fct_zone_daily_snapshot
    WHERE snapshot_date BETWEEN DATE '2024-02-23' AND DATE '2024-02-29'
    GROUP BY
        zone_id,
        zone_name,
        borough

),

baseline AS (

    SELECT
        zone_id,
        AVG(trips_1d) AS baseline_avg_daily_trips
    FROM dbt_taxi.fct_zone_daily_snapshot
    WHERE snapshot_date BETWEEN DATE '2024-01-31' AND DATE '2024-02-22'
    GROUP BY zone_id

)

SELECT
    r.zone_id,
    r.zone_name,
    r.borough,

    r.recent_7d_trips,

    ROUND(
        r.recent_avg_daily_trips,
        1
    ) AS recent_avg_daily_trips,

    ROUND(
        b.baseline_avg_daily_trips,
        1
    ) AS baseline_avg_daily_trips,

    ROUND(
        r.recent_avg_daily_trips
        - b.baseline_avg_daily_trips,
        1
    ) AS daily_trip_change,

    ROUND(
        100.0
        * (
            r.recent_avg_daily_trips
            - b.baseline_avg_daily_trips
        )
        / NULLIF(b.baseline_avg_daily_trips, 0),
        1
    ) AS change_pct

FROM recent r

INNER JOIN baseline b
    ON r.zone_id = b.zone_id

WHERE b.baseline_avg_daily_trips > 0

ORDER BY
    ABS(
        r.recent_avg_daily_trips
        - b.baseline_avg_daily_trips
    ) DESC;
