variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "リソースを作成するリージョン"
  type        = string
}

variable "dataset_prefix" {
  description = "BigQuery データセット名のプレフィックス"
  type        = string
  default     = "dex"
}

variable "env_suffix" {
  description = "環境を区別するサフィックス（dev/prod）"
  type        = string
}

variable "common_labels" {
  description = "すべてのリソースに付与する共通ラベル"
  type        = map(string)
  default     = {}
}

variable "kms_key_name" {
  description = "BigQuery暗号化用のCloud KMSキー名（オプション）"
  type        = string
  default     = null
}
