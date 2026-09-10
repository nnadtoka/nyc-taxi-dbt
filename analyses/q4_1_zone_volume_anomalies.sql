-- q5_1_zone_volume_anomalies_v2.sql
--
-- Question:
-- Which zones have unusually high or low trip volume?
--
-- Latest period:
-- 2024-02-23 through 2024-02-29
--
-- Historical baseline:
-- Daily trailing-7-day trip volumes from 2024-01-07 through 2024-02-22.
--
-- Statistical method:
-- For each zone, calculate the historical mean and standard deviation
-- of trailing 7-day trip volume, then calculate a z-score for the
-- latest 7-day volume.
--
-- Anomaly. An anomaly is a zone whose latest 7-day trip volume is at least 3 standard deviations away from that zone’s historical mean 7-day trip volume:
-- z-score >= 3  -> unusually high
-- z-score <= -3 -> unusually low
--
-- Zones must have at least 10 historical observations and a non-zero
-- historical standard deviation.

WITH historical AS (

    SELECT
        zone_id,
        zone_name,
        borough,
        snapshot_date,
        trips_7d
    FROM dbt_taxi.fct_zone_daily_snapshot
    WHERE snapshot_date BETWEEN DATE '2024-01-07' AND DATE '2024-02-22'

),

historical_stats AS (

    SELECT
        zone_id,

        AVG(trips_7d) AS historical_avg_7d,

        STDDEV_SAMP(trips_7d) AS historical_stddev_7d,

        COUNT(*) AS historical_observations

    FROM historical
    GROUP BY zone_id

    HAVING COUNT(*) >= 10
       AND STDDEV_SAMP(trips_7d) > 0

),

latest AS (

    SELECT
        zone_id,
        zone_name,
        borough,
        snapshot_date,
        trips_7d AS latest_7d_trips
    FROM dbt_taxi.fct_zone_daily_snapshot
    WHERE snapshot_date = (
        SELECT MAX(snapshot_date)
        FROM dbt_taxi.fct_zone_daily_snapshot
        WHERE snapshot_date BETWEEN DATE '2024-02-23' AND DATE '2024-02-29'
    )

),

scored AS (

    SELECT
        l.zone_id,
        l.zone_name,
        l.borough,
        l.snapshot_date,
        l.latest_7d_trips,

        ROUND(s.historical_avg_7d, 1) AS historical_avg_7d,

        ROUND(s.historical_stddev_7d, 1) AS historical_stddev_7d,

        s.historical_observations,

        ROUND(
            l.latest_7d_trips - s.historical_avg_7d,
            1
        ) AS deviation_from_average,

        ROUND(
            (
                l.latest_7d_trips - s.historical_avg_7d
            ) / NULLIF(s.historical_stddev_7d, 0),
            2
        ) AS z_score

    FROM latest l
    INNER JOIN historical_stats s
        ON l.zone_id = s.zone_id

)

SELECT
    zone_id,
    zone_name,
    borough,
    snapshot_date,
    latest_7d_trips,
    historical_avg_7d,
    historical_stddev_7d,
    historical_observations,
    deviation_from_average,
    z_score,

    CASE
        WHEN z_score >= 2 THEN 'High'
        WHEN z_score <= -2 THEN 'Low'
        ELSE 'Normal'
    END AS anomaly_direction

FROM scored

WHERE ABS(z_score) >= 3

ORDER BY ABS(z_score) DESC;
