variable "name" {
  description = "Cloud Functionの名前"
  type        = string
}

variable "region" {
  description = "デプロイ先リージョン"
  type        = string
}

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "source_dir" {
  description = "関数のソースコードディレクトリ"
  type        = string
  default     = "../functions/prediction_gateway"
}

variable "source_bucket" {
  description = "ソースコードを格納するGCSバケット"
  type        = string
}

variable "runtime" {
  description = "ランタイム"
  type        = string
  default     = "python311"
}

variable "entry_point" {
  description = "エントリーポイント関数名"
  type        = string
  default     = "predict"
}

variable "memory" {
  description = "メモリ割り当て"
  type        = string
  default     = "256Mi"
}

variable "timeout_seconds" {
  description = "タイムアウト秒数"
  type        = number
  default     = 60
}

variable "min_instances" {
  description = "最小インスタンス数"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "最大インスタンス数"
  type        = number
  default     = 100
}

variable "service_account" {
  description = "サービスアカウントメールアドレス"
  type        = string
}

variable "environment_variables" {
  description = "環境変数"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "ラベル"
  type        = map(string)
  default     = {}
}

variable "allow_unauthenticated" {
  description = "認証なしアクセスを許可"
  type        = bool
  default     = false
}
