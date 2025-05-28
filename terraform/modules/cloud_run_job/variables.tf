variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
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
}

variable "vpc_connector" {
  type        = string
  description = "VPCコネクタの名前"
}
