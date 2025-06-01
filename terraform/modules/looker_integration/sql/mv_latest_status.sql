-- 最新 1 レコード／pool を返す Materialized View 本体
SELECT * EXCEPT(rn)
FROM (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY pool_id ORDER BY hour_ts DESC) rn
  FROM `${project_id}.${features_dataset}.${features_table}`
  WHERE hour_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
)
WHERE rn = 1;