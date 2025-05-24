variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
}

variable "region" {
  type        = string
  description = "リソースを作成するリージョン"
  default     = "asia-northeast1"
}

variable "env_suffix" {
  type        = string
  description = "環境を区別するサフィックス"
  default     = "dev"
}

variable "state_bucket" {
  description = "Terraform state を格納する GCS バケット名"
  type        = string
  default     = "terraform-state-portfolio-dex"
}
