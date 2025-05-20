locals {
  # GCP プロジェクト ID
  project_id = var.project_id

  # デプロイ先リージョン
  region = var.region

  # 環境を区別するサフィックス
  env_suffix = terraform.workspace

  # データセット名
  dataset_id = "${lower(var.dataset_prefix)}_raw_${terraform.workspace}"

  # サービスアカウント
  sa = module.service_accounts.emails

  # モデル名
  model_name = var.model_name

  # データバケット名
  bucket_name = "${var.project_id}-data-${terraform.workspace}"

  # ローカルのモデル ZIP パス (存在チェック用)
  model_zip_path = abspath("${path.module}/../artifacts/${var.model_name}.zip")
}
