# run locally once, before `docker build`
import pathlib, urllib.request
import pandas as pd

BASE   = "https://d37ci6vzurychx.cloudfront.net"
MONTHS = ["2024-01", "2024-02"]   # two consecutive months -> ~60-day span
FRAC   = 0.10                      # keep 10% of trips; 1.0 for the full set
SEED   = 42

data_dir = pathlib.Path("data");        data_dir.mkdir(exist_ok=True)
raw_dir  = pathlib.Path("raw_parquet"); raw_dir.mkdir(exist_ok=True)

frames = []
for m in MONTHS:
    fname = f"yellow_tripdata_{m}.parquet"
    dest  = raw_dir / fname
    if not dest.exists():                       # idempotent download
        print(f"downloading {fname} ...")
        urllib.request.urlretrieve(f"{BASE}/trip-data/{fname}", dest)
    df = pd.read_parquet(dest)
    if FRAC < 1.0:
        df = df.sample(frac=FRAC, random_state=SEED)
    frames.append(df)

trips = pd.concat(frames, ignore_index=True)
print(f"{len(trips):,} sampled trip rows across {MONTHS}")
trips.to_csv(data_dir / "yellow_tripdata_sample.csv.gz",
             index=False, compression="gzip")

zones = pd.read_csv(f"{BASE}/misc/taxi_zone_lookup.csv")
zones.to_csv(data_dir / "taxi_zone_lookup.csv.gz",
             index=False, compression="gzip")
print("wrote data/ ✓")
