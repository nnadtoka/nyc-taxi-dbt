# NYC Taxi dbt Project

A small analytics-engineering project that loads NYC yellow-taxi trip data into
Postgres and models it with dbt, following a medallion (raw → staging →
intermediate → mart) layering. The headline model is a per-zone **daily snapshot**
carrying rolling 1-day / 7-day / 30-day trip and fare metrics.

## The dataset we start from

Source: **NYC Taxi & Limousine Commission (TLC) Trip Record Data** — the public
yellow-taxi trip records, published monthly as Apache Parquet.
Documentation: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

The raw layer is built from two inputs:

- **Yellow taxi trips** — January and February 2024. Rather than load all ~6M
  rows, a **10% random sample of trips** is taken (`random_state=42`) while
  keeping the full date span, giving **597,215 rows**. Sampling on trips (not on
  dates) is deliberate: every day still appears, so the 7- and 30-day rolling
  windows stay meaningful. Each row is one trip, with pickup/dropoff timestamps,
  pickup/dropoff zone IDs, passenger count, distance, and fare components.
- **Taxi zone lookup** — the full lookup table (**265 rows**) mapping
  `LocationID` → borough / zone / service zone. Trips reference zones by ID, so
  this is the join used to attach borough and zone names.

Both are loaded verbatim into Postgres (`raw_yellow_tripdata`, `raw_taxi_zones`)
with permissive types — cleaning and typing happen downstream in dbt, not on
ingest, so data-quality decisions live in version-controlled models.

### What the raw data looks like (profiling)

Observations from `analyses/profiling_raw.sql` on the loaded data:

| Check | Result |
|---|---|
| Rows dropped by staging data-quality filters | **1.35%** (589,182 of 597,215 kept) |
| Date span | **2023-12-31 → 2024-02-29**, 61 distinct days |
| Zone coverage | **246 of 265** lookup zones have trips |
| Snapshot rows vs dense zone-day grid | **8,945** actual vs **15,006** possible (~40% of zone-days have no trips) |

Two quirks worth knowing:

- **Dates outside the month.** The January and February files include one trip
  with a pickup date of **2023-12-31**. This means the data covers 61 days
  instead of the expected 60 days. We keep this record because it is part of
  the source data.
- **Sparsity.** - **Sparsity.** ~40% of zone-day combinations have no trips in the observed data. These combinations are absent from the initial aggregation, which is why a date spine (one row per zone per day) is used for the snapshot model.

## Layers

- **raw** (`public.raw_*`) — loaded as-is from the sampled CSVs.
- **staging** (`stg_trips`, `stg_zones`) — cast, rename, and drop only
  indefensible rows (null timestamps, dropoff ≤ pickup, negative fares).
- **intermediate** (`int_zone_daily`) — one row per zone per day with daily sums.
- **mart** (`fct_zone_daily_snapshot`) — periodic snapshot at grain
  `zone_id × snapshot_date`, with rolling 1d/7d/30d metrics as typed columns.

## Quickstart

```sh
# 1. prepare the sampled data (writes data/*.csv.gz)
python prep_data.py

# 2. build and run the Postgres image (data baked in, loaded on first init)
docker build --tag nyc-taxi .
docker run --name nyc-taxi --detach --publish 5438:5432 nyc-taxi
# db available at postgresql://postgres:taxi@localhost:5438/postgres

# 3. build and test the models (classic dbt from the venv)
.venv/bin/dbt deps  --profiles-dir .
.venv/bin/dbt run   --profiles-dir .
.venv/bin/dbt test  --profiles-dir .
 alias dbt="$(pwd)/.venv/bin/dbt"

# 4. (optional) run the profiling queries
docker exec -i nyc-taxi psql -U postgres -f - < analyses/profiling_raw.sql
```

## Executive summary

The analysis is organized around a set of business questions designed to understand **where, when, and how taxi demand changes**, while demonstrating reusable analytical modeling patterns in dbt.

| Area | Question | Purpose |
|---|---|---|
| **1. Demand trends by zone** | Which zones have the highest recent activity? | Identify the zones with the strongest current demand using trailing 7-day activity. |
| | Which zones are seeing meaningful increases or decreases in recent demand? | Compare recent demand with a non-overlapping baseline using both relative and absolute change. |
| | Which zones have the longest average trip duration? | Identify areas where trips tend to take the longest, using a minimum-volume threshold to reduce noise. |
| **2. When and where demand peaks** | What are the busiest hours? | Identify the overall hourly demand pattern and sustained daily peak period. |
| | What is the peak hour for each zone? | Show how demand timing varies by pickup zone rather than assuming one city-wide peak. |
| | How do demand patterns differ by borough or service zone? | Compare hourly demand across geographic and service-area dimensions. |
| | Do weekday and weekend patterns differ? | Compare normalized hourly demand patterns between weekdays and weekends. |
| **3. Origin → destination corridors** | Which corridors have the highest trip volume? | Identify the most frequently traveled pickup-to-drop-off routes. |
| | Which generate the most passenger charges? | Identify the routes with the greatest total passenger-charge value and contrast them with high-volume routes. |
| | Which high-volume corridors have the longest average duration? | Identify frequently traveled routes with the greatest travel times using valid-duration trips. |
| | Which corridors have the lowest travel efficiency? | Use average speed to identify high-volume routes where trips take the longest relative to distance. |
| **4. Detect unusual activity** | Which zones have unusually high or low trip volume? | Detect statistically unusual recent demand by comparing the latest 7-day activity with each zone's historical distribution. An anomaly is defined as activity at least **3 standard deviations from the historical mean**. |

Together, these questions move from **descriptive demand analysis** to **temporal and dimensional comparisons**, then to **origin-destination modeling**, and finally to **statistical anomaly detection**. This provides a progression from reusable data models to increasingly analytical use cases while keeping each question tied to a clear business purpose.


Data modelling done here is done to answer specific selected questions that determine the required model grain and transformations. Corresponding queries, hopefully, named rather clearly, are placed under 
```analyses```
path in main project.


### 1. Demand trends by zone

#### **Question 1.1:** Which zones have the highest rolling 7-day trip volume?

Using `fct_zone_daily_snapshot`:

 
```
docker exec -i nyc-taxi psql -U postgres -f - < q1_1_highest_7d_activity.sql
```

#### **Question 1.2:**  Which zones are seeing meaningful increases or decreases in recent demand relative to their recent baseline?

Note1: Demand acceleration is measured by comparing average daily trips over the most recent 7 days with the average daily trips over the preceding 23 days.

Note2: To avoid misleading percentage changes from very low-volume zones, the analysis includes only zones with an average of at least 5 trips per day during the prior 23-day period.

```
docker exec -i nyc-taxi psql -U postgres -f - < q1_2_demand_acceleration.sql
```

The results are reported using both relative and absolute change:

- `demand_change_pct` shows the percentage increase or decrease in average daily trips.
- `daily_trip_change` shows the absolute change in average trips per day.

**Key observations:**

- Sunnyside had the largest relative increase among qualifying zones, at **+47.6%** or **+3.0 trips/day**.
- Alphabet City increased **+42.9%**, equivalent to **+6.3 trips/day**.
- JFK Airport increased **+18.0%**, but this represented the largest absolute increase among the highlighted zones at **+73.8 trips/day**.
- LaGuardia Airport increased **+15.6%**, or **+44.2 trips/day**.
- West Chelsea/Hudson Yards showed a notable decline of **-12.9%**, or **-22.2 trips/day**.
- Long Island City/Hunters Point declined **-17.2%**, or **-1.6 trips/day**.

The comparison shows why both relative and absolute change are useful: percentage growth highlights momentum, while absolute change indicates the scale of the demand shift.


#### **Question 1.3:**  Which zones have the longest average trip duration? 
Note: Performed research was done across zones with at least 5 trips in the most recent 7 days
```
docker exec -i nyc-taxi psql -U postgres -f - < q1_3_longest_average_duration.sql
```


### 2. Demand patterns by time and geography

**Question:** How does demand vary by time of day and day of week?

Model: `int_zone_hourly`

**Grain:** `zone_id × pickup_date × pickup_hour`


#### **Question 2.1:**  What are the busiest hours?

```
docker exec -i nyc-taxi psql -U postgres -f - < q2_1_busiest_hours.sql
```

Taxi demand is strongly concentrated in the **afternoon and early evening**, with a broad sustained peak rather than a single isolated hour. Activity builds through the morning and midday, reaches its highest levels during the afternoon/evening peak, and then gradually declines through the late evening and overnight.

The morning and overnight periods consistently have lower demand than the afternoon/evening period.

#### **Question 2.2:**  What is the peak hour for each zone?

```
docker exec -i nyc-taxi psql -U postgres -f - < q2_2_peak_hour_by_zone.sql
```

Peak demand varies substantially by pickup zone rather than following a single city-wide pattern.

- Many high-volume Manhattan zones peak during the **afternoon and evening**.
- Morning peaks are more common across many **residential areas in Brooklyn, Queens, and the Bronx**.
- Some entertainment and nightlife-oriented areas show **late-evening or overnight** peaks.
- **Airport zones exhibit distinct patterns**, with JFK showing an afternoon/evening peak and LaGuardia a midday peak.

Overall, the analysis shows that demand timing is strongly influenced by the type and location of each pickup zone.

#### **Question 2.3:**  How do demand patterns differ by borough or service zone?

```
 docker exec -i nyc-taxi psql -U postgres -f - < q2_3_demand_by_borough_service_zone.sql
 ```

Demand patterns vary considerably by geography and service-zone type.

- **Manhattan Yellow Zone** demand is substantially more concentrated and builds through the day, with the strongest activity in the afternoon and early evening.
- **Boro Zone** activity follows a different pattern, with stronger morning demand and a gradual decline later in the day, particularly in Brooklyn and the Bronx.
- **Queens Airports** show a distinct demand profile, with activity increasing from the morning into the afternoon and remaining elevated into the evening.
- **Brooklyn Boro Zone** demand also remains relatively strong overnight and late in the evening compared with other borough-level Boro Zone patterns.

Overall, the results show that taxi demand is shaped not only by borough, but also by the **type of service area**. Residential, commercial, and airport zones exhibit distinctly different hourly demand profiles.

#### ** Question 2.4:** Do weekday and weekend patterns differ?

```
docker exec -i nyc-taxi psql -U postgres -f - < q2_4_weekday_vs_weekend.sql
```

Weekday and weekend demand are normalized to average trips per day using only complete Monday–Sunday weeks in the analysis period.

Weekday and weekend demand have distinctly different hourly patterns.

- **Late-night and overnight demand is much stronger on weekends**, with the largest weekend uplift occurring after midnight and again late in the evening.
- **Morning demand is substantially stronger on weekdays**, particularly during the early commute period.
- Around **midday and early afternoon**, weekday and weekend demand become much more similar.
- The **afternoon/evening peak remains stronger on weekdays**, especially during the core commuting hours.
- By late evening, demand shifts back toward **weekend dominance**.

Overall, the weekday pattern is more commute-oriented, while weekends show relatively stronger late-night activity and a flatter daytime profile.

### 3. Origin → destination corridors

We look at common routes between pickup and drop-off areas. Each pickup zone and drop-off zone combination is treated as a distinct route, allowing us to compare how frequently people travel that route, how much they are charged, how long those trips take, and how efficiently they travel.

**Question:** Which taxi origin→destination pairs have the most activity and total passender charges?

#### ** Question 3.1:** Which corridors have the highest trip volume?

``` 
docker exec -i nyc-taxi psql -U postgres -f - < q3_1_top_origin_destination_pairs.sql
```

The highest-volume pickup-to-drop-off routes are concentrated in **Manhattan**, particularly among dense residential and commercial areas such as the Upper East Side, Midtown, Upper West Side, Lincoln Square, and Lenox Hill.

Several of the most frequently traveled routes are within the same zone, showing that a significant share of taxi demand comes from local trips as well as travel between neighboring areas.

#### ** Question 3.2:**  Which generate the most passenger charges?

```
docker exec -i nyc-taxi psql -U postgres -f - < q3_2_top_origin_destination_charges.sql
```

The routes generating the highest passenger charges are dominated by **airport connections**, particularly trips between JFK or LaGuardia and major Manhattan destinations.

Longer-distance airport trips generate substantially more passenger charges than many of the highest-volume local Manhattan routes. This highlights an important distinction between **trip volume and passenger-charge value**: the most frequently traveled routes are not necessarily the routes generating the most charges.

#### ** Question 3.3:** Which high-volume corridors have the longest average duration?

```
docker exec -i nyc-taxi psql -U postgres -f - < q3_3_longest_average_duration.sql
```
Average duration and average speed use only trips with valid duration measurements, with a minimum of 100 valid trips per corridor.

Among frequently traveled routes, the longest average trip durations are dominated by **JFK Airport connections**, both to and from Manhattan.

The results show that route duration varies substantially by destination and origin, with airport trips generally taking longer than shorter intra-Manhattan routes. This provides a useful distinction between **route popularity** and **travel time**: a route can be frequently traveled while still requiring substantially more time to complete.

#### ** Question 3.4:**  Which corridors have the lowest travel efficiency?

```
docker exec -i nyc-taxi psql -U postgres -f - < q3_4_route_travel_efficiency.sql
```

Travel efficiency is measured using average speed:

`average_speed_mph = trip_distance / (duration_min / 60)`

The analysis focuses on high-volume corridors and uses only trips with valid duration measurements.

The slowest corridors are concentrated in dense Manhattan areas, particularly around Midtown, Times Square, and Penn Station.

The Queensbridge/Ravenswood area shows the lowest average speed, consistent with significant traffic congestion around the Queensboro Bridge and Queens Plaza. This represents a meaningful operational signal of slow urban travel.

### 4. Detect unusual activity

#### ** Question 4.1 ** Which zones have unusually high or low trip volume?

Compare the latest incremental (here, latest of our range 7 days) period with the historical demand pattern for each zone.

The goal is to identify zones where recent trip activity is materially above or below what would normally be expected, providing an early signal of unusual demand or potential data-quality issues.

```
docker exec -i nyc-taxi psql -U postgres -f - < q4_1_zone_volume_anomalies.sql
```

The latest 7-day period was evaluated against each zone's historical 7-day demand distribution. An anomaly is defined as activity at least **3 standard deviations from the historical mean**.

The analysis identified several zones with unusually high recent demand, with no zones showing statistically significant low-demand anomalies during the latest period.

This approach is more robust than ranking percentage changes because it accounts for each zone's normal level and historical variability, reducing the influence of low-volume zones with large percentage swings.

### Analytical limitations

The dataset does not support:

- **Customer behavior:** no rider ID, so no retention, cohorts, or LTV.
- **Load factor:** no meaningful taxi capacity measure.
- **Scheduled delays:** no scheduled arrival/departure times.
- **Seasonality / YoY:** only Jan–Feb 2024.
- **Total NYC activity:** data is a 10% trip sample.

### Duration data quality

Trip duration is derived from pickup and drop-off timestamps. Based on profiling, trips longer than **180 minutes** are treated as duration outliers.

Rather than dropping these records, `stg_trips` adds an `is_valid_duration` flag. This keeps the trip available for activity, fare, and distance analysis while allowing duration-dependent metrics to use only valid trips.

`int_zone_daily` and `int_zone_route_daily` track valid and invalid duration populations separately. Duration-based measures such as average duration and average speed use the consistent valid-trip population, while `invalid_duration_trips` provides data-quality visibility.

