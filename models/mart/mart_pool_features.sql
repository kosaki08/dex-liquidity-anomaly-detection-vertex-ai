{{ config(
    materialized            = 'table',
    unique_key              = ['pool_id', 'hour_ts'],
    incremental_strategy    = 'merge',
    invalidate_hard_deletes = true
) }}

with hourly as (

    select 'uniswap_v3'  as dex_protocol, * from {{ ref('stg_pool_hourly_uniswap_v3') }}
    union all
    select 'sushiswap_v3' as dex_protocol, * from {{ ref('stg_pool_hourly_sushiswap_v3') }}

), renamed as (

    select
        dex_protocol,
        pool_id,
        hour_ts,
        tvl_usd,
        volume_usd,
        liquidity,
        load_ts
    from hourly

)

select
    dex_protocol,
    pool_id,
    hour_ts,
    tvl_usd,
    volume_usd,
    liquidity,

    -- 24h 変化率
    (volume_usd
        / nullif(lag(volume_usd, 24) over (partition by pool_id order by hour_ts), 0)
    ) - 1 as vol_rate_24h,

    (tvl_usd
        / nullif(lag(tvl_usd, 24) over (partition by pool_id order by hour_ts), 0)
    ) - 1 as tvl_rate_24h,

    -- 移動平均
    avg(volume_usd) over (
        partition by pool_id order by hour_ts
        rows between 5 preceding and current row
    )              as vol_ma_6h,

    avg(volume_usd) over (
        partition by pool_id order by hour_ts
        rows between 23 preceding and current row
    )              as vol_ma_24h,

    -- TVL 比
    volume_usd / nullif(tvl_usd, 0) as vol_tvl_ratio,

    load_ts

from renamed

{% if is_incremental() %}
where hour_ts > coalesce((select max(hour_ts) from {{ this }}), '1900-01-01'::timestamp)
{% endif %}

