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

# BigQuery データ閲覧権限
resource "google_project_iam_member" "vertex_pipeline_bq_reader" {
  project = local.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${local.sa["vertex-pipeline"]}"
}

# Cloud Run Job (Fetcher) の BigQuery 権限
resource "google_project_iam_member" "vertex_bigquery_editor" {
  project = local.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# BigQuery ジョブ実行権限
resource "google_project_iam_member" "vertex_bigquery_job_user" {
  project = local.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# Cloud Run Job 実行権限
resource "google_project_iam_member" "vertex_pipeline_run_invoker" {
  project = local.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${module.service_accounts.emails["vertex-pipeline"]}"
}

# Cloud Run Job の VPC アクセス権限
resource "google_project_iam_member" "vertex_pipeline_networkuser" {
  project = local.project_id
  role    = "roles/vpcaccess.user"
  member  = "serviceAccount:${module.service_accounts.emails["vertex-pipeline"]}"
}

# Cloud Run Job が pull するための Artifact Registry の読み取り権限
resource "google_project_iam_member" "vertex_pipeline_ar_reader" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${module.service_accounts.emails["vertex-pipeline"]}"
}

# Artifact Registry → Pull 権限
resource "google_project_iam_member" "vertex_ar_reader" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# VPC Access Connector 利用権限
resource "google_project_iam_member" "vertex_vpcaccess_user" {
  project = local.project_id
  role    = "roles/vpcaccess.user"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# BigQuery DTS 専用 SA に一括付与
resource "google_bigquery_dataset_iam_member" "bq_dts_dataset_editor" {
  dataset_id = module.bigquery.staging_dataset_id
  project    = local.project_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${local.project_number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
}

# Cloud Scheduler から Cloud Run Job を実行するための権限
resource "google_service_account_iam_member" "scheduler_impersonate_vertex_pipeline" {
  service_account_id = "projects/${local.project_id}/serviceAccounts/${module.service_accounts.emails["vertex-pipeline"]}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${local.project_number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

# ---------- Feature Store 関連の権限 ----------
# Feature Store ユーザー権限
resource "google_project_iam_member" "vertex_featurestore_user" {
  count   = var.enable_feature_store ? 1 : 0
  project = local.project_id
  role    = "roles/aiplatform.featurestoreUser"
  member  = "serviceAccount:${local.sa["vertex"]}"
}

# Feature Store 管理者権限
resource "google_project_iam_member" "vertex_pipeline_featurestore_admin" {
  count   = var.enable_feature_store ? 1 : 0
  project = local.project_id
  role    = "roles/aiplatform.featurestoreAdmin"
  member  = "serviceAccount:${local.sa["vertex-pipeline"]}"
}

# TODO: Cloud Run Job 用 SA 権限見直し
# run-vertex-*, run-vertex-pipeline-* には roles/run.invoker + 必要最小の Storage / Secret だけに絞る。
