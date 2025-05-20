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

variable "model_image_uri" {
  type        = string
  description = "カスタムモデルのコンテナイメージ URI"
  default     = "asia-docker.pkg.dev/vertex-ai/prediction/sklearn-cpu.1-3:latest"
}

variable "env_suffix" {
  type        = string
  description = "環境を区別するサフィックス"
  default     = "dev"
}
