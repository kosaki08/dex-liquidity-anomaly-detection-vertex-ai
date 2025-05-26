variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
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

# # ---------- Feature Store 関連の変数 ----------
# variable "enable_feature_store" {
#   type        = bool
#   description = "Feature Store を有効にするかどうか"
#   default     = true
# }

# variable "feature_store_node_count" {
#   type        = number
#   description = "Feature Store のオンライン配信ノード数"
#   default     = 1
# }
