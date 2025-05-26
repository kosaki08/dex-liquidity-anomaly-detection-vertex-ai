variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
}

variable "project_number" {
  type        = string
  description = "GCP プロジェクト番号"
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
  default     = "terraform-state-portfolio-vertex-ai-dex"
}

variable "github_repository" {
  description = "GitHub リポジトリ名（organization/repository）"
  type        = string
  default     = "kosaki08/dex-liquidity-anomaly-detection-vertex-ai"
}

variable "allowed_branches" {
  description = "許可するブランチ一覧"
  type        = list(string)
  default     = ["refs/heads/main", "refs/heads/develop"]
}

variable "github_organization" {
  description = "GitHub organization名"
  type        = string
  default     = "kosaki08"
}

variable "repository_name" {
  description = "リポジトリ名"
  type        = string
  default     = "dex-liquidity-anomaly-detection-vertex-ai"
}
