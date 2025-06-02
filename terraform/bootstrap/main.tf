# サービス有効化
resource "google_project_service" "services" {
  for_each = toset([
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  service = each.key

  disable_dependent_services = false
  disable_on_destroy         = false
}

# ステートバケット
resource "google_storage_bucket" "tf_state" {
  name     = var.state_bucket
  location = var.region

  # 暗号化
  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_state.id
  }

  # バージョニング
  versioning {
    enabled = true
  }
  # バケットレベルでのアクセス制御を統一
  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.services,
    google_kms_crypto_key_iam_member.gcs_object_encrypter
  ]
}

# サービスアカウント
resource "google_service_account" "tf_apply" {
  account_id   = "tf-apply-${var.env_suffix}"
  display_name = "Terraform Apply SA (${var.env_suffix})"
}

# KMS キーリング
resource "google_kms_key_ring" "terraform" {
  name     = "terraform-state-${var.env_suffix}"
  location = var.region

  depends_on = [
    google_project_service.services["cloudkms.googleapis.com"]
  ]
}

# KMS 暗号化キー
resource "google_kms_crypto_key" "terraform_state" {
  name     = "terraform-state-key"
  key_ring = google_kms_key_ring.terraform.id

  # 90日間のローテーション
  rotation_period = "7776000s"

  lifecycle {
    # 削除を防ぐ
    prevent_destroy = true
  }
}

# Terraform SAにKMS権限付与
resource "google_kms_crypto_key_iam_member" "terraform_state_encrypter" {
  crypto_key_id = google_kms_crypto_key.terraform_state.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.tf_apply.email}"
}

# Cloud Storage サービスアカウントに KMS 使用権限を付与
resource "google_kms_crypto_key_iam_member" "gcs_object_encrypter" {
  crypto_key_id = google_kms_crypto_key.terraform_state.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Cloud Build Service Identity
resource "google_project_service_identity" "cloudbuild_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "cloudbuild.googleapis.com"
}
