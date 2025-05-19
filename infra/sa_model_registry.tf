locals {
  sa_model_registry_roles = [
    "roles/aiplatform.modelAdmin",  # モデル開発者
    "roles/artifactregistry.reader" # モデルイメージの読取
  ]
}

// モデル登録・管理 サービス アカウント
resource "google_service_account" "sa_model_registry" {
  account_id   = "sa-model-registry"
  display_name = "Service Account for Model Registry Management"
}

// Vertex AI のモデル開発者と Artifact Registry への読取権限
resource "google_project_iam_member" "sa_model_registry_roles" {
  for_each = toset(local.sa_model_registry_roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.sa_model_registry.email}"
}
