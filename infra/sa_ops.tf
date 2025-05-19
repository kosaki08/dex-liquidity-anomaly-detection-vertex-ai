locals {
  sa_ops_members = toset([
    google_service_account.sa_ops.email,
  ])
}

// 監視・運用 サービス アカウント
resource "google_service_account" "sa_ops" {
  account_id   = "sa-ops"
  display_name = "Service Account for Monitoring and Operations"
}

// Monitoring と Logging の閲覧権限
resource "google_project_iam_member" "sa_ops_monitoring" {
  for_each = local.sa_ops_members
  project  = local.project_id
  role     = "roles/monitoring.viewer"
  member   = "serviceAccount:${each.value}"
}
