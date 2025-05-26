# サービス有効化
resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "composer.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",        # Composer/BigQuery バケット用
    "compute.googleapis.com",        # VPC ネットワーク用
    "vpcaccess.googleapis.com",      # Serverless VPC Access Connector 用
    "iamcredentials.googleapis.com", # サービスアカウント用
    "secretmanager.googleapis.com"   # シークレットマネージャー用
  ])
  service = each.key
}

# VPC ネットワーク
module "network" {
  source                  = "./modules/network"
  project_id              = local.project_id
  region                  = local.region
  network_name            = "dex-network-${local.env_suffix}"
  vpc_connector_name      = "serverless-conn-${local.env_suffix}"
  subnet_ip_cidr_range    = "10.9.0.0/24"
  connector_ip_cidr_range = "10.8.0.0/28"
  env_suffix              = local.env_suffix

  depends_on = [
    google_project_service.services["compute.googleapis.com"],
  ]
}


# データバケット
resource "google_storage_bucket" "data_bucket" {
  name = "${local.project_id}-data-${local.env_suffix}"
  labels = {
    env = local.env_suffix
  }
  location                    = local.region
  uniform_bucket_level_access = true

  # バージョニング
  versioning {
    enabled = true
  }

  # ライフサイクルルール
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365 # 365 日後に削除
    }
  }

  # dev 環境の場合は強制的に削除可能に
  force_destroy = var.env_suffix == "dev" ? true : false
}

# サービスアカウント
module "service_accounts" {
  source     = "./modules/service_accounts"
  project_id = local.project_id
  sa_names   = ["vertex", "vertex-pipeline"]
  env        = local.env_suffix # dev / prod
}

# API キーを Secret Manager に保存
resource "google_secret_manager_secret" "api_keys" {
  for_each = toset(["the-graph-api-key", "slack-webhook-url"])

  secret_id = "${each.key}-${local.env_suffix}"

  replication {
    auto {}
  }

  labels = local.common_labels
}

# BigQuery 用モジュール例
module "bigquery" {
  source      = "terraform-google-modules/bigquery/google"
  version     = "~> 9.0"
  project_id  = local.project_id
  dataset_id  = local.dataset_id
  location    = local.region
  description = "DEX liquidity raw data (The Graph)"

  depends_on = [google_project_service.services]
}

# Vertex AI エンドポイント
resource "google_vertex_ai_endpoint" "endpoint" {
  name         = "${local.model_name}-endpoint-${local.env_suffix}"
  display_name = "${local.model_name}-endpoint-${local.env_suffix}"
  location     = local.region
  labels = {
    env = local.env_suffix
  }

  depends_on = [
    google_project_service.services["aiplatform.googleapis.com"],
  ]
}

# Feature Store
module "feature_store" {
  source       = "./modules/feature_store"
  count        = var.enable_feature_store ? 1 : 0 # 条件付き作成
  project_id   = local.project_id
  project_name = "dex-anomaly-detection"
  region       = local.region
  env_suffix   = local.env_suffix

  common_labels = local.common_labels

  # dev環境では最小構成
  online_serving_node_count = var.env_suffix == "dev" ? 1 : 2

  aiplatform_service_dependency = google_project_service.services["aiplatform.googleapis.com"]

  depends_on = [
    google_project_service.services["aiplatform.googleapis.com"],
  ]
}

# モデルアーカイブ（ZIP 等）を GCS にアップロード
resource "google_storage_bucket_object" "model_artifact" {
  count = fileexists(local.model_zip_path) ? 1 : 0

  lifecycle {
    precondition {
      condition     = fileexists(local.model_zip_path) || var.env_suffix == "dev"
      error_message = "モデルアーティファクトが見つかりません: ${local.model_zip_path}"
    }
  }

  name   = "models/${local.model_name}/${terraform.workspace}/${local.model_name}.zip"
  bucket = google_storage_bucket.data_bucket.name
  source = local.model_zip_path

  content_type = "application/zip"
}

# ワークロード
module "workloads" {
  source     = "./workloads"
  project_id = local.project_id
  env_suffix = local.env_suffix

  depends_on = [google_project_service.services]
}
