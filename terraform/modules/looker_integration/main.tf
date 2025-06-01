# BigQuery ビューの作成（Looker Studio用）
resource "google_bigquery_table" "looker_dashboard_view" {
  dataset_id = var.dataset_id
  table_id   = "looker_anomaly_dashboard"
  project    = var.project_id

  view {
    query = templatefile("${path.module}/sql/dashboard_view.sql", {
      project_id       = var.project_id
      features_dataset = var.features_dataset_id
      features_table   = var.features_table
      mv_table         = "mv_looker_latest_status"
    })
    use_legacy_sql = false
  }

  labels = var.common_labels

  depends_on = [google_bigquery_table.mv_looker_latest_status]
}

# 時系列集計ビュー
resource "google_bigquery_table" "looker_timeseries_view" {
  dataset_id = var.dataset_id
  table_id   = "looker_anomaly_timeseries"
  project    = var.project_id

  view {
    query = templatefile("${path.module}/sql/timeseries_view.sql", {
      project_id       = var.project_id
      features_dataset = var.features_dataset_id
      features_table   = var.features_table
    })
    use_legacy_sql = false
  }

  labels = var.common_labels
}

# Looker Studio用のデータソース権限（サービスアカウントが指定されている場合のみ）
resource "google_bigquery_dataset_iam_member" "looker_viewer" {
  count = var.looker_service_account != "" ? 1 : 0

  dataset_id = var.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.looker_service_account}"
  project    = var.project_id
}

# 最新ステータスを返す Looker ダッシュボード用通常ビュー
resource "google_bigquery_table" "mv_looker_latest_status" {
  dataset_id = var.dataset_id
  table_id   = "mv_looker_latest_status"
  project    = var.project_id

  materialized_view {
    query = templatefile("${path.module}/sql/mv_latest_status.sql", {
      project_id       = var.project_id
      dataset_id       = var.dataset_id
      features_dataset = var.features_dataset_id
      features_table   = var.features_table
    })
  }
  labels = var.common_labels
}
