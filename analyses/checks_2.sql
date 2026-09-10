select *
from dbt_taxi.fct_zone_daily_snapshot
where zone_id = 1
order by snapshot_date
limit 30;
