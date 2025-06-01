variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery データセット ID（Lookerダッシュボード用ビューを作成）"
  type        = string
}

variable "features_dataset_id" {
  description = "特徴量データセットのID"
  type        = string
}

variable "looker_service_account" {
  description = "Looker Studio用のサービスアカウント"
  type        = string
  default     = "" # 空の場合はIAM設定をスキップ
}

variable "region" {
  description = "リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "common_labels" {
  description = "共通ラベル"
  type        = map(string)
  default     = {}
}

variable "features_table" {
  description = "特徴量テーブル名"
  type        = string
}
