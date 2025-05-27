# プール特徴量テーブル
resource "google_bigquery_table" "mart_pool_features" {
  dataset_id = google_bigquery_dataset.dex_features.dataset_id
  table_id   = "mart_pool_features"
  project    = var.project_id

  view {
    query = templatefile("${path.module}/sql/features/mart_pool_features.sql", {
      project_id      = var.project_id
      staging_dataset = google_bigquery_dataset.dex_staging.dataset_id
    })
    use_legacy_sql = false
  }

  labels = var.common_labels

  depends_on = [
    google_bigquery_table.stg_pool_hourly_all
  ]
}

# ラベル付き特徴量テーブル（学習用）
resource "google_bigquery_table" "mart_pool_features_labeled" {
  dataset_id = google_bigquery_dataset.dex_features.dataset_id
  table_id   = "mart_pool_features_labeled"
  project    = var.project_id

  time_partitioning {
    type  = "DAY"
    field = "hour_ts"
  }

  schema = jsonencode([
    { name = "dex_protocol", type = "STRING", mode = "REQUIRED" },
    { name = "pool_id", type = "STRING", mode = "REQUIRED" },
    { name = "hour_ts", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "volume_usd", type = "FLOAT64", mode = "NULLABLE" },
    { name = "tvl_usd", type = "FLOAT64", mode = "NULLABLE" },
    { name = "liquidity", type = "FLOAT64", mode = "NULLABLE" },
    { name = "tx_count", type = "INT64", mode = "NULLABLE" },
    { name = "vol_rate_24h", type = "FLOAT64", mode = "NULLABLE" },
    { name = "tvl_rate_24h", type = "FLOAT64", mode = "NULLABLE" },
    { name = "vol_ma_6h", type = "FLOAT64", mode = "NULLABLE" },
    { name = "vol_ma_24h", type = "FLOAT64", mode = "NULLABLE" },
    { name = "vol_std_24h", type = "FLOAT64", mode = "NULLABLE" },
    { name = "vol_tvl_ratio", type = "FLOAT64", mode = "NULLABLE" },
    { name = "volume_zscore", type = "FLOAT64", mode = "NULLABLE" },
    { name = "hour_of_day", type = "INT64", mode = "NULLABLE" },
    { name = "day_of_week", type = "INT64", mode = "NULLABLE" },
    { name = "is_anomaly", type = "BOOL", mode = "NULLABLE" },      # ← y
    { name = "anomaly_score", type = "FLOAT64", mode = "NULLABLE" } # ← iforest_score
  ])

  labels = var.common_labels
}
