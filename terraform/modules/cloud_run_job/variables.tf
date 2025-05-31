variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
}

variable "env_suffix" {
  description = "環境識別子（dev/prod）"
  type        = string
  default     = "dev"
}

variable "name" {
  type        = string
  description = "Cloud Run Job の名前"
}

variable "image_uri" {
  type        = string
  description = "コンテナイメージのURI"
}

variable "region" {
  type        = string
  description = "Cloud Run Job をデプロイするリージョン"
}

variable "service_account" {
  type        = string
  description = "Cloud Run Job で使用するサービスアカウント"
}

variable "env_vars" {
  type        = map(string)
  description = "Cloud Run Job の環境変数"
}

variable "secret_name_graph_api" {
  type        = string
  description = "Graph API のシークレット名"
  default     = null
}

variable "vpc_connector" {
  type        = string
  description = "VPCコネクタの名前"
}

variable "deletion_protection" {
  type        = bool
  description = "Cloud Run Job の削除保護"
  default     = true
}
