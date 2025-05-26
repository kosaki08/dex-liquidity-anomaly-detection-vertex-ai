# BigQuery データセット定義
locals {
  # dev 環境では 30 日、prod では 365 日保持
  raw_retention_ms = var.env_suffix == "dev" ? 2592000000 : 31536000000
}

# ---------- RAW ----------
resource "google_bigquery_dataset" "dex_raw" {
  dataset_id  = "${var.dataset_prefix}_raw_${var.env_suffix}"
  project     = var.project_id
  location    = var.region
  description = "The GraphからのDEX流動性生データ"

  default_table_expiration_ms = local.raw_retention_ms
  labels                      = var.common_labels

  dynamic "default_encryption_configuration" {
    for_each = var.kms_key_name == null ? [] : [1]
    content {
      kms_key_name = var.kms_key_name
    }
  }
}

# ---------- STAGING ----------
resource "google_bigquery_dataset" "dex_staging" {
  dataset_id  = "${var.dataset_prefix}_staging_${var.env_suffix}"
  project     = var.project_id
  location    = var.region
  description = "The GraphからのDEX流動性生データを変換したデータ"

  labels = var.common_labels

  dynamic "default_encryption_configuration" {
    for_each = var.kms_key_name == null ? [] : [1]
    content {
      kms_key_name = var.kms_key_name
    }
  }
}

# ---------- FEATURES ----------
resource "google_bigquery_dataset" "dex_features" {
  dataset_id  = "${var.dataset_prefix}_features_${var.env_suffix}"
  project     = var.project_id
  location    = var.region
  description = "The GraphからのDEX流動性生データを変換し特徴量化したデータ"

  labels = var.common_labels

  dynamic "default_encryption_configuration" {
    for_each = var.kms_key_name == null ? [] : [1]
    content {
      kms_key_name = var.kms_key_name
    }
  }
}
