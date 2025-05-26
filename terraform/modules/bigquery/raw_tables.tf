# Uniswap時系列テーブル
resource "google_bigquery_table" "pool_hourly_uniswap" {
  dataset_id = google_bigquery_dataset.dex_raw.dataset_id
  table_id   = "pool_hourly_uniswap_v3"
  project    = var.project_id

  time_partitioning {
    type          = "HOUR"
    field         = "hour_ts"
    expiration_ms = var.env_suffix == "dev" ? 7776000000 : null # dev: 90日
  }

  clustering = ["pool_id", "dex_protocol"]
  # pool_id: 特定プールの時系列分析で頻繁にフィルタ
  # dex_protocol: プロトコル別の集計クエリで使用

  schema = jsonencode([
    {
      name        = "raw"
      type        = "JSON"
      mode        = "REQUIRED"
      description = "The Graphから取得した生のJSONデータ（Uniswap V3 poolHourData）"
    },
    { name = "pool_id", type = "STRING", mode = "REQUIRED", description = "プールのコントラクトアドレス" },
    { name = "dex_protocol", type = "STRING", mode = "REQUIRED", description = "常にuniswap_v3" },
    { name = "hour_ts", type = "TIMESTAMP", mode = "REQUIRED", description = "時間タイムスタンプ" },
    { name = "load_ts", type = "TIMESTAMP", mode = "REQUIRED",
    description = "データ取り込み時刻", defaultValueExpression = "CURRENT_TIMESTAMP()" }
  ])

  labels = var.common_labels
}

# Sushiswap時系列テーブル
resource "google_bigquery_table" "pool_hourly_sushiswap" {
  dataset_id = google_bigquery_dataset.dex_raw.dataset_id
  table_id   = "pool_hourly_sushiswap_v3"
  project    = var.project_id

  # Uniswapと同じ構造
  time_partitioning {
    type          = "HOUR"
    field         = "hour_ts"
    expiration_ms = var.env_suffix == "dev" ? 7776000000 : null
  }

  clustering = ["pool_id", "dex_protocol"]
  # pool_id: 特定プールの時系列分析で頻繁にフィルタ
  # dex_protocol: プロトコル別の集計クエリで使用

  schema = jsonencode([
    {
      name        = "raw"
      type        = "JSON"
      mode        = "REQUIRED"
      description = "The Graphから取得した生のJSONデータ（Sushiswap poolHourData）"
    },
    { name = "pool_id", type = "STRING", mode = "REQUIRED", description = "プールのコントラクトアドレス" },
    { name = "dex_protocol", type = "STRING", mode = "REQUIRED", description = "常にsushiswap_v3" },
    { name = "hour_ts", type = "TIMESTAMP", mode = "REQUIRED", description = "時間タイムスタンプ" },
    { name = "load_ts", type = "TIMESTAMP", mode = "REQUIRED",
    description = "データ取り込み時刻", defaultValueExpression = "CURRENT_TIMESTAMP()" }
  ])

  labels = var.common_labels
}
