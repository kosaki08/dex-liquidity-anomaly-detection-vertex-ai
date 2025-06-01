EXPORT DATA OPTIONS(
  uri = 'gs://${project_id}-feature-import/hourly/{run_time}/*',
  format = 'PARQUET'
) AS
SELECT
  pool_id                        AS entity_id,
  hour_ts                        AS feature_timestamp,
  volume_usd                     AS volume_usd,
  tvl_usd                        AS tvl_usd,
  liquidity                      AS liquidity,
  tx_count                       AS tx_count,
  vol_rate_24h                   AS vol_rate_24h,
  tvl_rate_24h                   AS tvl_rate_24h,
  vol_ma_6h                      AS vol_ma_6h,
  vol_ma_24h                     AS vol_ma_24h,
  vol_std_24h                    AS vol_std_24h,
  vol_tvl_ratio                  AS vol_tvl_ratio,
  volume_zscore                  AS volume_zscore,
  hour_of_day                    AS hour_of_day,
  day_of_week                    AS day_of_week
FROM `${project_id}.${dataset_id}.mart_pool_features_labeled`
WHERE hour_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
  AND hour_ts < CURRENT_TIMESTAMP();
