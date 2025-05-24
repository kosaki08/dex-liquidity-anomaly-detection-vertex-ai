locals {
  # GCP プロジェクト ID
  project_id = var.project_id

  # デプロイ先リージョン
  region = var.region

  # 環境を区別するサフィックス
  env_suffix = var.env_suffix

  # データセット名
  dataset_id = "${lower(var.dataset_prefix)}_raw_${var.env_suffix}"

  # サービスアカウント
  sa = module.service_accounts.emails

  # モデル名
  model_name = var.model_name

  # データバケット名
  bucket_name = "${var.project_id}-data-${var.env_suffix}"

  # ローカルのモデル ZIP パス (存在チェック用)
  model_zip_path = abspath("${path.module}/../artifacts/${var.model_name}.zip")

  # Terraform 実行時に impersonate する Service Account
  impersonate_sa = "tf-apply-${var.env_suffix}@${var.project_id}.iam.gserviceaccount.com"
}
