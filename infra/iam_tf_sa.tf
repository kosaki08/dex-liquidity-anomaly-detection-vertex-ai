# 既存 SA を data で参照
data "google_service_account" "tf_apply" {
  account_id = "tf-apply-${var.env_suffix}"
  project    = local.project_id
}
