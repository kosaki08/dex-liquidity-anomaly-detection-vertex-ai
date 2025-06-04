variable "project_id" {
  type        = string
  description = "Cloud Scheduler ジョブをデプロイするプロジェクト ID"
}

variable "name" {
  type        = string
  description = "Cloud Scheduler ジョブの名前"
}

variable "region" {
  type        = string
  description = "Cloud Scheduler ジョブをデプロイするリージョン"
}

variable "job_name" {
  type        = string
  description = "Cloud Run Job の名前"
}

variable "schedule" {
  type        = string
  description = "ジョブの実行スケジュール（cron形式）"
}

variable "oauth_sa_email" {
  type        = string
  description = "認証に使用するサービスアカウントのメールアドレス"
}
