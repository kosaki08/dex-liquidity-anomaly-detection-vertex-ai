locals {
  state_bucket_name = var.state_bucket
}

# ステートバケットの権限付与
resource "google_storage_bucket_iam_member" "tf_sa_state_bucket" {
  bucket = local.state_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tf_apply.email}"
}

# 読み取り系ロール
resource "google_project_iam_member" "tf_sa_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# データバケットの bucket-level 権限
resource "google_storage_bucket_iam_member" "tf_sa_state_bucket_reader" {
  bucket = local.state_bucket_name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.tf_apply.email}"
}

# tf-apply SA に読み取り専用の IAM 可視化権限を付与
resource "google_project_iam_member" "tf_sa_security_reviewer" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# tf-apply SA に必要な管理権限を付与
resource "google_project_iam_member" "tf_sa_admin_roles" {
  for_each = toset([
    "roles/storage.admin",                   # GCS バケット管理
    "roles/iam.serviceAccountAdmin",         # サービスアカウント管理
    "roles/resourcemanager.projectIamAdmin", # プロジェクトレベルIAM管理 TODO: 権限が強いため、個別ロールへ分解する
    "roles/serviceusage.serviceUsageAdmin",  # API有効化
    "roles/compute.networkAdmin",            # VPC管理
    "roles/notebooks.admin",                 # Workbench 作成用
    "roles/aiplatform.admin",                # Vertex AI管理
    "roles/bigquery.admin",                  # BigQuery管理
    "roles/secretmanager.admin",             # シークレットマネージャー管理
    "roles/compute.securityAdmin",           # ファイアウォール更新用
    "roles/run.admin",                       # Cloud Run Job 管理
    "roles/cloudscheduler.admin",            # Cloud Scheduler 管理
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Service Account Token Creator (impersonation用)
resource "google_service_account_iam_member" "tf_sa_token_creator" {
  service_account_id = google_service_account.tf_apply.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.tf_apply.email}"
}

# tf-apply SA が run-vertex-pipeline-${var.env_suffix} を impersonate できるように
resource "google_service_account_iam_member" "tf_apply_can_use_vertex_pipeline_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/run-vertex-pipeline-${var.env_suffix}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.tf_apply.email}"
}

resource "google_service_account_iam_member" "tf_apply_use_vertex_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/run-vertex-${var.env_suffix}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.tf_apply.email}"
}

resource "google_service_account_iam_member" "tf_apply_use_vertex_pipeline_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/run-vertex-pipeline-${var.env_suffix}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Cloud Run Jobs の権限付与
resource "google_project_iam_member" "tf_sa_run_jobs" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}
