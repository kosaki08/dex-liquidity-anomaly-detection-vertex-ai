variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "デプロイ先リージョン"
  type        = string
}

variable "env_suffix" {
  type        = string
  description = "環境を区別するサフィックス（モジュール呼び出し側が渡す）"
}

variable "network_name" {
  description = "作成する VPC ネットワークの名前"
  type        = string
  default     = "dex-network"
}

variable "vpc_connector_name" {
  description = "Serverless VPC Access Connector の名前"
  type        = string
  default     = "serverless-conn"
}

variable "subnet_ip_cidr_range" {
  description = "サブネットに割り当てる /24 などの CIDR"
  type        = string
  default     = "10.9.0.0/24"
}

variable "connector_ip_cidr_range" {
  description = "Serverless VPC Access Connector 用 /28 CIDR"
  type        = string
  default     = "10.8.0.0/28"
}
