locals {
  # BigQuery DTS 専用 SA（project-number 固定）
  dts_sa = "service-${local.project_number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
  # objectCreator + objectViewer を一括付与
  dts_roles = ["roles/storage.objectCreator", "roles/storage.objectViewer"]
  # Cloud Run Job の SA
  vertex_pipeline_sa = module.service_accounts.emails["vertex-pipeline"]
}

# Feature Store インポート用のバケット
# tfsec:ignore:AVD-GCP-0066 dev環境はGoogle-managed暗号化で許容
resource "google_storage_bucket" "feature_import" {
  name                        = "${local.project_id}-feature-import"
  location                    = local.region
  uniform_bucket_level_access = true

  # バージョニング
  versioning {
    enabled = true
  }

  # 暗号化設定
  dynamic "encryption" {
    # CMEK (prod のみ強制)
    for_each = var.env_suffix == "prod" && var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  # - **通常運用**       : prevent_destroy が効くので誤 destroy はブロックされる
  # - **本当に削除したい場合** :
  #   1) terraform state rm google_storage_bucket.feature_import
  #   2) gcloud storage rm -r gs://${var.project_id}-feature-import
  #   3) （必要なら）state 再 import → terraform apply
  force_destroy = true # 破棄を許可。prevent_destroy が優先

  lifecycle {
    prevent_destroy = true # 事故防止。force_destroy よりこちらが優先される
  }
}

# Cloud Run Job の SA 向け objectViewer
resource "google_storage_bucket_iam_member" "feature_import_job_reader" {
  bucket = google_storage_bucket.feature_import.name
  role   = "roles/storage.objectViewer" # 読み取りのみ
  member = "serviceAccount:${local.vertex_pipeline_sa}"
}

# BigQuery DTS 専用 SA に一括付与
resource "google_storage_bucket_iam_member" "bq_dts_access" {
  for_each = toset(local.dts_roles)

  bucket = google_storage_bucket.feature_import.name
  role   = each.value
  member = "serviceAccount:${local.dts_sa}"
}

# Feature Store Import が読むバケット権限
resource "google_storage_bucket_iam_member" "aiplatform_sa_bucket_reader" {
  bucket = google_storage_bucket.feature_import.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${local.project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

# Vertex AI が読み書きするバケット権限
resource "google_storage_bucket_iam_member" "vertex_raw_bucket_writer" {
  bucket = google_storage_bucket.data_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.service_accounts.emails["vertex"]}"
}
