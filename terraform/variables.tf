variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
}

variable "project_number" {
  type        = string
  description = "GCP プロジェクト番号"
  default     = null
}

variable "region" {
  type        = string
  description = "リソースを作成するリージョン"
  default     = "asia-northeast1"
}

variable "dataset_prefix" {
  type        = string
  description = "BigQuery データセット名のプレフィックス"
  default     = "dex"
}

variable "model_name" {
  type        = string
  description = "モデル名"
  default     = "iforest"
}

variable "env_suffix" {
  type        = string
  description = "環境を区別するサフィックス"
  default     = "dev"
}

variable "kms_key_name" {
  description = "BigQuery暗号化用のCloud KMSキー名"
  type        = string
  default     = null
}

variable "workbench_zone" {
  description = "Workbench を置く GCE ゾーン"
  type        = string
}

variable "fetcher_image_uri" {
  type        = string
  description = "Fetcher 用コンテナイメージ (digest 推奨)"

  validation {
    condition     = var.fetcher_image_uri != "dummy"
    error_message = "fetcher_image_uri cannot be 'dummy'. Please provide a valid container image URI."
  }
}

variable "feature_import_image_uri" {
  type        = string
  description = "Feature-import Job 用コンテナイメージ"

  validation {
    condition     = can(regex("^asia-northeast1-docker\\.pkg\\.dev/.+/(feature-import:latest|feature-import@sha256:[0-9a-f]{64})$", var.feature_import_image_uri))
    error_message = "feature_import_image_uri must be a valid Artifact Registry URI with either :latest tag or @sha256 digest"
  }
}

variable "enable_feature_store" {
  type        = bool
  description = "Feature Store を有効にするかどうか"
  default     = false
}

variable "enable_looker_integration" {
  type        = bool
  description = "Looker Studio統合を有効にするか"
  default     = true
}

variable "enable_prediction_gateway" {
  type        = bool
  description = "Cloud Functions予測ゲートウェイを有効にするか"
  default     = false
}
