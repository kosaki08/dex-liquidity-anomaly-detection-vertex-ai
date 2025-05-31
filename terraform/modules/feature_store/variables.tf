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

variable "kms_key_name" {
  description = "Feature Store暗号化用のCloud KMSキー名（prodのみ必須）"
  type        = string
  default     = null
}

variable "basic_features" {
  description = "基本的な特徴量定義（monitoring設定なし）"
  type = map(object({
    value_type  = string
    description = optional(string, "")
  }))
  default = {
    "volume_usd"    = { value_type = "DOUBLE" }
    "tvl_usd"       = { value_type = "DOUBLE" }
    "liquidity"     = { value_type = "DOUBLE" }
    "tx_count"      = { value_type = "INT64" }
    "vol_rate_24h"  = { value_type = "DOUBLE" }
    "tvl_rate_24h"  = { value_type = "DOUBLE" }
    "vol_ma_6h"     = { value_type = "DOUBLE" }
    "vol_ma_24h"    = { value_type = "DOUBLE" }
    "vol_std_24h"   = { value_type = "DOUBLE" }
    "vol_tvl_ratio" = { value_type = "DOUBLE" }
    "volume_zscore" = { value_type = "DOUBLE" }
    "hour_of_day"   = { value_type = "INT64" }
    "day_of_week"   = { value_type = "INT64" }
  }
}
