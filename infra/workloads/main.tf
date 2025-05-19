locals {
  sa_training_roles       = ["roles/aiplatform.user", "roles/storage.objectAdmin"]
  sa_batch_predict_roles  = ["roles/aiplatform.user", "roles/storage.objectViewer"]
  sa_model_registry_roles = ["roles/aiplatform.admin", "roles/artifactregistry.reader"]
  sa_data_prep_roles      = ["roles/bigquery.dataEditor", "roles/storage.objectAdmin"]
  sa_orchestrator_roles   = ["roles/composer.admin"]
  sa_ops_roles            = ["roles/monitoring.viewer"]
}

## ---------- サービスアカウント ----------
# 1) トレーニング
resource "google_service_account" "sa_training" {
  project      = var.project_id
  account_id   = "sa-training-${var.env_suffix}"
  display_name = "Training Service Account (${var.env_suffix})"
}

# 2) バッチ推論
resource "google_service_account" "sa_batch_predict" {
  project      = var.project_id
  account_id   = "sa-batch-predict-${var.env_suffix}"
  display_name = "Batch Prediction Service Account (${var.env_suffix})"
}

# 3) モデル登録
resource "google_service_account" "sa_model_registry" {
  project      = var.project_id
  account_id   = "sa-model-registry-${var.env_suffix}"
  display_name = "Model Registry Service Account (${var.env_suffix})"
}

# 4) データ準備
resource "google_service_account" "sa_data_prep" {
  project      = var.project_id
  account_id   = "sa-data-prep-${var.env_suffix}"
  display_name = "Data Preparation and ETL Service Account (${var.env_suffix})"
}

# 5) オーケストレーション
resource "google_service_account" "sa_orchestrator" {
  project      = var.project_id
  account_id   = "sa-orchestrator-${var.env_suffix}"
  display_name = "Orchestration Service Account (${var.env_suffix})"
}

# 6) 監視・運用
resource "google_service_account" "sa_ops" {
  project      = var.project_id
  account_id   = "sa-ops-${var.env_suffix}"
  display_name = "Monitoring and Operations Service Account (${var.env_suffix})"
}

## ---------- IAM ロール付与 ----------
# 1) トレーニング
resource "google_project_iam_member" "sa_training_roles" {
  for_each = toset(local.sa_training_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_training.email}"
}

# 2) バッチ推論
resource "google_project_iam_member" "sa_batch_predict_roles" {
  for_each = toset(local.sa_batch_predict_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_batch_predict.email}"
}

# 3) モデル登録
resource "google_project_iam_member" "sa_model_registry_roles" {
  for_each = toset(local.sa_model_registry_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_model_registry.email}"
}

# 4) データ準備
resource "google_project_iam_member" "sa_data_prep_roles" {
  for_each = toset(local.sa_data_prep_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_data_prep.email}"
}

# 5) オーケストレーション
resource "google_project_iam_member" "sa_orchestrator_roles" {
  for_each = toset(local.sa_orchestrator_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_orchestrator.email}"
}

# 6) 監視・運用
resource "google_project_iam_member" "sa_ops_monitoring" {
  for_each = toset(local.sa_ops_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_ops.email}"
}
