# Vertex AI
resource "google_project_iam_member" "vertex_user" {
  project = local.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# ログ書き込み
resource "google_project_iam_member" "vertex_runtime_logs" {
  project = local.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# Vertex AI ランタイムメトリクスの書き込み
resource "google_project_iam_member" "vertex_runtime_metrics" {
  project = local.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# モデルデータ読み込み
resource "google_project_iam_member" "vertex_model_data_reader" {
  project = local.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# Vertex Pipelines ジョブ実行（AI Platform User）
resource "google_project_iam_member" "vertex_pipeline_user" {
  project = local.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${local.sa["vertex-pipeline"]}"
}

# GCS 書き込み権限（パイプライン artefact 保存バケット用）
resource "google_project_iam_member" "vertex_pipeline_storage" {
  project = local.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${local.sa["vertex-pipeline"]}"
}

# BigQuery へロード
resource "google_project_iam_member" "vertex_pipeline_bq" {
  project = local.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${local.sa["vertex-pipeline"]}"
}
