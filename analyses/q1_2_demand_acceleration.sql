-- q1_2_demand_acceleration.sql
--
-- Question:
-- Which zones are accelerating or cooling relative to their recent baseline?
--
-- Recent demand: trailing 7 days
-- Baseline: average daily demand over the preceding 23 days
-- Analysis period: 2023-12-31 through 2024-02-29
--
-- Minimum baseline: 5 trips/day to avoid extreme percentage changes
-- from very low-volume zones.

WITH demand AS (

    SELECT
        zone_id,
        zone_name,
        borough,
        snapshot_date,
        trips_7d,
        trips_30d - trips_7d AS trips_prior_23d,

        ROUND(trips_7d / 7.0, 1) AS avg_daily_trips_7d,

        ROUND(
            (trips_30d - trips_7d) / 23.0,
            1
        ) AS avg_daily_trips_prior_23d

    FROM dbt_taxi.fct_zone_daily_snapshot

    WHERE snapshot_date = (
        SELECT MAX(snapshot_date)
        FROM dbt_taxi.fct_zone_daily_snapshot
        WHERE snapshot_date BETWEEN DATE '2024-01-01' AND DATE '2024-02-29'
    )
)

SELECT
    zone_id,
    zone_name,
    borough,
    snapshot_date,
    trips_7d,
    trips_prior_23d,
    avg_daily_trips_7d,
    avg_daily_trips_prior_23d,

    ROUND(
        avg_daily_trips_7d - avg_daily_trips_prior_23d,
        1
    ) AS daily_trip_change,

    ROUND(
        100.0
        * (avg_daily_trips_7d - avg_daily_trips_prior_23d)
        / NULLIF(avg_daily_trips_prior_23d, 0),
        1
    ) AS demand_change_pct

FROM demand

WHERE avg_daily_trips_prior_23d >= 5

ORDER BY demand_change_pct DESC;