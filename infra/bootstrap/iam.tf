# ステートバケットの権限付与
resource "google_storage_bucket_iam_member" "tf_sa_state_bucket" {
  bucket = google_storage_bucket.tf_state.name
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
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.tf_apply.email}"
}

# tf-apply SA に読み取り専用の IAM 可視化権限を付与
resource "google_project_iam_member" "tf_sa_security_reviewer" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.tf_apply.email}"
}
