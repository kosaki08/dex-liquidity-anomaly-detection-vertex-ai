-- Looker Studio用ダッシュボードビュー
WITH latest_predictions AS (
  SELECT 
    pool_id,
    hour_ts,
    volume_usd,
    tvl_usd,
    liquidity,
    anomaly_score,
    is_anomaly,
    ROW_NUMBER() OVER (PARTITION BY pool_id ORDER BY hour_ts DESC) as rn
  FROM `${project_id}.${features_dataset}.${features_table}`
  WHERE hour_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
),
pool_summary AS (
  SELECT 
    pool_id,
    COUNT(*) as total_hours,
    SUM(CASE WHEN is_anomaly THEN 1 ELSE 0 END) as anomaly_hours,
    AVG(volume_usd) as avg_volume,
    AVG(tvl_usd) as avg_tvl,
    MAX(anomaly_score) as max_anomaly_score
  FROM latest_predictions
  GROUP BY pool_id
)
SELECT 
  lp.pool_id,
  lp.hour_ts,
  lp.volume_usd,
  lp.tvl_usd,
  lp.liquidity,
  lp.anomaly_score,
  CASE 
    WHEN lp.is_anomaly THEN 'Anomaly Detected'
    ELSE 'Normal'
  END as status,
  -- アラート用のフラグ（最新の異常のみ）
  CASE 
    WHEN lp.is_anomaly AND lp.rn = 1 THEN TRUE
    ELSE FALSE
  END as needs_alert,
  -- 集計情報
  ps.anomaly_hours,
  ps.total_hours,
  ROUND(SAFE_DIVIDE(ps.anomaly_hours, ps.total_hours) * 100, 2) as anomaly_rate_pct,
  ps.avg_volume,
  ps.avg_tvl,
  ps.max_anomaly_score
FROM latest_predictions lp
JOIN pool_summary ps ON lp.pool_id = ps.pool_id
WHERE lp.rn <= 168 -- 過去7日間の時間別データ