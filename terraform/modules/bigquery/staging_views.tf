# 共通の時系列データビュー
resource "google_bigquery_table" "stg_pool_hourly_all" {
  dataset_id = google_bigquery_dataset.dex_staging.dataset_id
  table_id   = "stg_pool_hourly_all"
  project    = var.project_id

  view {
    query = templatefile("${path.module}/sql/staging/stg_pool_hourly_all.sql", {
      project_id  = var.project_id
      raw_dataset = google_bigquery_dataset.dex_raw.dataset_id
      env_suffix  = var.env_suffix
    })
    use_legacy_sql = false
  }

  labels = var.common_labels
}
