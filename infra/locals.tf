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

  # モデルイメージURI
  model_image_uri = "asia-docker.pkg.dev/vertex-ai/prediction/sklearn-cpu.1-3:latest"

  # データバケット名
  bucket_name = "${var.project_id}-data-${terraform.workspace}"
}
