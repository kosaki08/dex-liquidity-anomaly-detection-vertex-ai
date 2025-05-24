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

# TODO: IAM権限エラーのため一時的に無効化
# 原因: 条件付きバインディングの削除権限不足
# 対応予定: Service Account Adminロール付与後に再有効化
# モデルデータ読み込み
# resource "google_project_iam_member" "vertex_model_data_reader" {
#   project = local.project_id
#   role    = "roles/storage.objectViewer"
#   member  = "serviceAccount:${local.sa["vertex"]}"

#   condition {
#     title      = "Restrict to model bucket"
#     expression = "resource.name.startsWith('projects/_/buckets/${local.bucket_name}/') || resource.name == 'projects/_/buckets/${local.bucket_name}'"
#   }
# }

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
