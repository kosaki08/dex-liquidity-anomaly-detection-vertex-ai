locals {
  sa_orchestrator_roles = [
    "roles/aiplatform.pipelineRunner", # Vertex Pipelines の実行権限
    "roles/composer.admin",            # Cloud Composer の管理権限
  ]
}

// オーケストレーション サービス アカウント
resource "google_service_account" "sa_orchestrator" {
  account_id   = "sa-orchestrator"
  display_name = "Service Account for Orchestration"
}

// Vertex Pipelines と Cloud Composer の管理権限
resource "google_project_iam_member" "sa_orchestrator_roles" {
  for_each = toset(local.sa_orchestrator_roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.sa_orchestrator.email}"
}
