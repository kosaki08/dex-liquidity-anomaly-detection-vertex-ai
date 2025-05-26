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

  # ローカルのモデル ZIP パス (存在チェック用)
  model_zip_path = abspath("${path.module}/../artifacts/${var.model_name}.zip")

  # ラベル
  common_labels = {
    environment = var.env_suffix          # dev/prod
    project     = "dex-anomaly-detection" # プロジェクト名
    project_id  = local.project_id        # GCPプロジェクトID
    managed_by  = "terraform"             # 管理方法
    team        = "ml-platform"           # チーム名
    cost_center = "research-dev"          # コスト管理用
  }
}
