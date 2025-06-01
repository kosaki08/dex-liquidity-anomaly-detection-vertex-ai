-- 時系列分析用ビュー
WITH hourly_stats AS (
  SELECT 
    DATE(hour_ts) as date,
    EXTRACT(HOUR FROM hour_ts) as hour,
    COUNT(DISTINCT pool_id) as active_pools,
    SUM(volume_usd) as total_volume,
    SUM(tvl_usd) as total_tvl,
    SUM(CASE WHEN is_anomaly THEN 1 ELSE 0 END) as anomaly_count,
    AVG(anomaly_score) as avg_anomaly_score
  FROM `${project_id}.${features_dataset}.${features_table}`
  WHERE hour_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  GROUP BY date, hour
)
SELECT 
  *,
  -- 異常検知率
  SAFE_DIVIDE(anomaly_count, active_pools) * 100 as anomaly_rate_pct,
  -- 前日比較
  LAG(total_volume, 24) OVER (ORDER BY date, hour) as volume_24h_ago,
  LAG(anomaly_count, 24) OVER (ORDER BY date, hour) as anomaly_count_24h_ago
FROM hourly_stats
ORDER BY date DESC, hour DESC