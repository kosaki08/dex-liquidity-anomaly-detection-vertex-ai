# ステートバケット
resource "google_storage_bucket" "tf_state" {
  name     = var.state_bucket
  location = var.region

  # バージョニング
  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
}

# サービスアカウント
resource "google_service_account" "tf_apply" {
  account_id   = "tf-apply-${var.env_suffix}"
  display_name = "Terraform Apply SA (${var.env_suffix})"
}
