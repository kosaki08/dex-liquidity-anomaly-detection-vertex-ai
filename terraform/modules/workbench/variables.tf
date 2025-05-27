variable "project_id" {
  type        = string
  description = "GCP プロジェクト ID"
}

variable "zone" {
  type        = string
  description = "Workbench を置く GCE ゾーン"
  default     = "asia-northeast1-a"
}

variable "env_suffix" {
  type        = string
  description = "環境を区別するサフィックス"
  default     = "dev"
}

variable "sa_email" {
  type        = string
  description = "Workbench VM のサービスアカウント e-mail"
}

variable "network_self_link" {
  type        = string
  description = "VPC ネットワークの自己リンク"
}

variable "subnet_self_link" {
  type        = string
  description = "サブネットの自己リンク"
}
