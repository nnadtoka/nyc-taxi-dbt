#!/bin/bash
set -e
export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL="psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB --host /var/run/postgresql"

echo "loading yellow_tripdata ..."
gunzip -c /data/yellow_tripdata_sample.csv.gz \
  | $PSQL -c "COPY raw_yellow_tripdata FROM STDIN WITH (FORMAT csv, HEADER true)"

csv_rows=$(( $(gunzip -c /data/yellow_tripdata_sample.csv.gz | wc -l) - 1 ))
db_rows=$($PSQL -tAc "SELECT count(*) FROM raw_yellow_tripdata")
echo "CSV rows: $csv_rows | DB rows: $db_rows"
[ "$csv_rows" -eq "$db_rows" ] || { echo "ROW COUNT MISMATCH"; exit 1; }

echo "loading taxi_zones ..."
gunzip -c /data/taxi_zone_lookup.csv.gz \
  | $PSQL -c "COPY raw_taxi_zones FROM STDIN WITH (FORMAT csv, HEADER true)"
echo "load complete ✓"
