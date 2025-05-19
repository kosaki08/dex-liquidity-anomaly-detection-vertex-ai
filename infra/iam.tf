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

