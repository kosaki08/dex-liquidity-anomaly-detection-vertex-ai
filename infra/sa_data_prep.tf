locals {
  sa_data_prep_roles = [
    "roles/bigquery.dataEditor", # BigQuery への読み書き
    "roles/storage.objectAdmin", # GCS バケットの読み書き
  ]
}

// データ準備／ETL サービス アカウント
resource "google_service_account" "sa_data_prep" {
  account_id   = "sa-data-prep"
  display_name = "Service Account for Data Preparation and ETL"
}

// BigQuery と Storage へのアクセス権限
resource "google_project_iam_member" "sa_data_prep_roles" {
  for_each = toset(local.sa_data_prep_roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.sa_data_prep.email}"
}
