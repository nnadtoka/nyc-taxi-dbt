select
    h.zone_id,
    count(*) as rows
from dbt_taxi.int_zone_hourly h
left join dbt_taxi.stg_zones z
    on h.zone_id = z.zone_id
where z.zone_id is null
group by h.zone_id
order by rows desc;
