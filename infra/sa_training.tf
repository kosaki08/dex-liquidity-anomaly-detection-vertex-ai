locals {
  sa_training_roles = [
    "roles/aiplatform.user",     # 学習ジョブ送信
    "roles/storage.objectAdmin", # 学習データ/成果物を書込む
  ]
}

// トレーニング サービス アカウント
resource "google_service_account" "sa_training" {
  account_id   = "sa-training"
  display_name = "Service Account for Training Models"
}

// Vertex AI と Storage へのアクセス権限
resource "google_project_iam_member" "sa_training_roles" {
  for_each = toset(local.sa_training_roles)
  project  = local.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sa_training.email}"
}
