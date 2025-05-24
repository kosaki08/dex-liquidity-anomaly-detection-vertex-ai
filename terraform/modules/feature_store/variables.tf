variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "dex-anomaly-detection"
}

variable "region" {
  description = "リージョン"
  type        = string
}

variable "env_suffix" {
  description = "環境サフィックス"
  type        = string
}

variable "common_labels" {
  description = "共通ラベル"
  type        = map(string)
}

variable "online_serving_node_count" {
  description = "オンライン配信のノード数"
  type        = number
  default     = 1
}

variable "aiplatform_service_dependency" {
  description = "AI Platform サービス有効化の依存関係"
  type        = any
  default     = null
}

# Phase 1: 基本的な特徴量のみ
variable "basic_features" {
  description = "基本的な特徴量定義（monitoring設定なし）"
  type = map(object({
    value_type = string
  }))
  default = {
    "liquidity_volume_24h" = {
      value_type = "DOUBLE"
    }
    "price_volatility" = {
      value_type = "DOUBLE"
    }
    "transaction_count" = {
      value_type = "INT64"
    }
    "pool_total_value_locked" = {
      value_type = "DOUBLE"
    }
  }
}
