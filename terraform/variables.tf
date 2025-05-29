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

# ---------- Feature Store 関連の変数 ----------
variable "enable_feature_store" {
  type        = bool
  description = "Feature Store を有効にするかどうか"
  default     = false
}

# variable "feature_store_node_count" {
#   type        = number
#   description = "Feature Store のオンライン配信ノード数"
#   default     = 1
# }
