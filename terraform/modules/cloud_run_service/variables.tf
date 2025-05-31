variable "name" {
  type        = string
  description = "Cloud Run Service の名前"
}

variable "region" {
  type        = string
  description = "Cloud Run Service をデプロイするリージョン"
}

variable "env_suffix" {
  type        = string
  description = "環境識別子（dev/prod）"
  default     = "dev"
}

variable "image_uri" {
  type        = string
  description = "コンテナイメージのURI"
}

variable "service_account" {
  type        = string
  description = "Cloud Run Service で使用するサービスアカウント"
}

variable "vpc_connector" {
  type        = string
  description = "VPCコネクタのID"
  default     = null
}

variable "allow_unauthenticated" {
  type        = bool
  description = "認証なしアクセスを許可するか"
  default     = false
}

variable "min_instances" {
  type        = number
  description = "最小インスタンス数"
  default     = 0
}

variable "max_instances" {
  type        = number
  description = "最大インスタンス数"
  default     = 10
}

variable "cpu_limit" {
  type        = string
  description = "CPU制限"
  default     = "2"
}

variable "memory_limit" {
  type        = string
  description = "メモリ制限"
  default     = "4Gi"
}

variable "env_vars" {
  description = "コンテナに渡す環境変数 (key → value)"
  type        = map(string)
  default     = {} # dev でも prod でも空で良い。呼び出し元で必要分を渡す
}
