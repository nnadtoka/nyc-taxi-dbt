-- q2_1_busiest_hours.sql
--
-- Question:
-- What are the busiest hours?
--
-- Analysis period:
-- 2023-12-31 through 2024-02-29
--
-- Metric:
-- Total number of trips starting during each hour of the day.
--
-- Purpose:
-- Identify the overall daily demand pattern across the dataset.
--
-- Time-of-day buckets are added for easier interpretation.

SELECT
    pickup_hour,
    CASE
        WHEN pickup_hour BETWEEN 0 AND 5   THEN 'Overnight'
        WHEN pickup_hour BETWEEN 6 AND 9   THEN 'Morning'
        WHEN pickup_hour BETWEEN 10 AND 14 THEN 'Midday'
        WHEN pickup_hour BETWEEN 15 AND 20 THEN 'Afternoon / Evening Peak'
        WHEN pickup_hour BETWEEN 21 AND 23 THEN 'Late Evening'
    END AS time_of_day,
    SUM(hourly_trips) AS total_trips
FROM dbt_taxi.int_zone_hourly
WHERE pickup_date BETWEEN DATE '2023-12-31' AND DATE '2024-02-29'
GROUP BY pickup_hour, time_of_day
ORDER BY total_trips DESC;
