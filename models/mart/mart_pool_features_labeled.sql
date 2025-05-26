{{
  config(
    materialized            = 'incremental',
    unique_key              = ['pool_id', 'hour_ts'],
    incremental_strategy    = 'merge',
    invalidate_hard_deletes = true
  )
}}

-- 1) ソースとなる Mart データ
with source as (
  select
    dex_protocol,
    pool_id,
    hour_ts,
    tvl_usd,
    volume_usd,
    liquidity,
    vol_rate_24h,
    tvl_rate_24h,
    vol_ma_6h,
    vol_ma_24h,
    vol_tvl_ratio
  from {{ ref('mart_pool_features') }}
),

-- 2) プールごとの 90th percentile を計算
pct as (
  {% if target.type in ['snowflake', 'bigquery'] %}
    -- Snowflake / BigQuery 共通: percentile_cont
    select
      pool_id,
      percentile_cont(volume_usd, 0.9) as pct_90
    from source
    group by pool_id
  {% else %}
    -- DuckDB なら reservoir_quantile（近似）を使う
    select
      pool_id,
      reservoir_quantile(volume_usd, 0.9) as pct_90
    from source
    group by pool_id
  {% endif %}
)

-- 3) ラベル付与
select
  s.*,

  -- ラベル（is_anomaly）
  case
    when s.volume_usd >= p.pct_90 then true else false
  end                  as is_anomaly,

  -- Isolation Forest スコアは推論フェーズで上書きするため NULL で初期化
  cast(null as float64) as anomaly_score

from source s
join pct   p using (pool_id)

{% if is_incremental() %}
where s.hour_ts > (
  select coalesce(max(hour_ts), '1900-01-01'::timestamp) from {{ this }}
)
{% endif %}
