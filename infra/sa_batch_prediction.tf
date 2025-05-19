locals {
  sa_batch_predict_roles = [
    "roles/aiplatform.user",      # BatchPrediction 実行
    "roles/storage.objectViewer", # 入力データ／出力 GCS の閲覧
  ]
}

// バッチ推論 サービス アカウント
resource "google_service_account" "sa_batch_predict" {
  account_id   = "sa-batch-predict"
  display_name = "Service Account for Batch Prediction"
}

// Vertex AI バッチ推論と Storage への読取権限
resource "google_project_iam_member" "sa_batch_predict_roles" {
  for_each = toset(local.sa_batch_predict_roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.sa_batch_predict.email}"
}
