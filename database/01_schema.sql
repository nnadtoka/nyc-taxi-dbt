CREATE TABLE raw_yellow_tripdata (
    vendor_id             INTEGER,
    pickup_datetime       TIMESTAMP,
    dropoff_datetime      TIMESTAMP,
    passenger_count       NUMERIC,
    trip_distance         NUMERIC,
    ratecode_id           NUMERIC,
    store_and_fwd_flag    TEXT,
    pu_location_id        INTEGER,
    do_location_id        INTEGER,
    payment_type          INTEGER,
    fare_amount           NUMERIC,
    extra                 NUMERIC,
    mta_tax               NUMERIC,
    tip_amount            NUMERIC,
    tolls_amount          NUMERIC,
    improvement_surcharge NUMERIC,
    total_amount          NUMERIC,
    congestion_surcharge  NUMERIC,
    airport_fee           NUMERIC
);

CREATE TABLE raw_taxi_zones (
    location_id  INTEGER,
    borough      TEXT,
    zone         TEXT,
    service_zone TEXT
);
