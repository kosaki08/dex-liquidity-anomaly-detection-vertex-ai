// オンライン推論 サービス アカウント
resource "google_service_account" "sa_prediction" {
  account_id   = "sa-prediction"
  display_name = "Service Account for Online Prediction"
}

// Vertex AI エンドポイントの使用と Logging/Monitoring へのアクセス権限
resource "google_project_iam_member" "sa_prediction_user" {
  project = local.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.sa_prediction.email}"
}
