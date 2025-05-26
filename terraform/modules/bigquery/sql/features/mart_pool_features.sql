WITH
  hourly_metrics AS (
    SELECT
      dex_protocol,
      pool_id,
      hour_ts,
      volume_usd,
      tvl_usd,
      liquidity,
      tx_count,
      -- 24時間前のデータ
      LAG (volume_usd, 24) OVER (
        PARTITION BY
          pool_id
        ORDER BY
          hour_ts
      ) as volume_usd_24h_ago,
      LAG (tvl_usd, 24) OVER (
        PARTITION BY
          pool_id
        ORDER BY
          hour_ts
      ) as tvl_usd_24h_ago,
      -- 移動平均
      AVG(volume_usd) OVER (
        PARTITION BY
          pool_id
        ORDER BY
          hour_ts ROWS BETWEEN 5 PRECEDING
          AND CURRENT ROW
      ) as vol_ma_6h,
      AVG(volume_usd) OVER (
        PARTITION BY
          pool_id
        ORDER BY
          hour_ts ROWS BETWEEN 23 PRECEDING
          AND CURRENT ROW
      ) as vol_ma_24h,
      -- 標準偏差
      STDDEV (volume_usd) OVER (
        PARTITION BY
          pool_id
        ORDER BY
          hour_ts ROWS BETWEEN 23 PRECEDING
          AND CURRENT ROW
      ) as vol_std_24h
    FROM
      `${project_id}.${staging_dataset}.stg_pool_hourly_all`
    WHERE
      NOT has_negative_values
  )
SELECT
  dex_protocol,
  pool_id,
  hour_ts,
  volume_usd,
  tvl_usd,
  liquidity,
  tx_count,
  -- 変化率
  SAFE_DIVIDE (
    volume_usd - volume_usd_24h_ago,
    NULLIF(volume_usd_24h_ago, 0)
  ) as vol_rate_24h,
  SAFE_DIVIDE (
    tvl_usd - tvl_usd_24h_ago,
    NULLIF(tvl_usd_24h_ago, 0)
  ) as tvl_rate_24h,
  -- 移動平均
  vol_ma_6h,
  vol_ma_24h,
  -- ボラティリティ
  vol_std_24h,
  -- 比率
  SAFE_DIVIDE (volume_usd, NULLIF(tvl_usd, 0)) as vol_tvl_ratio,
  -- Z-score
  SAFE_DIVIDE (volume_usd - vol_ma_24h, NULLIF(vol_std_24h, 0)) as volume_zscore,
  -- 時間特徴量
  EXTRACT(
    HOUR
    FROM
      hour_ts
  ) as hour_of_day,
  EXTRACT(
    DAYOFWEEK
    FROM
      hour_ts
  ) as day_of_week,
  -- データ鮮度
  TIMESTAMP_DIFF (CURRENT_TIMESTAMP(), hour_ts, HOUR) as hours_ago
FROM
  hourly_metrics
WHERE
  hour_ts >= TIMESTAMP_SUB (CURRENT_TIMESTAMP(), INTERVAL 90 DAY)