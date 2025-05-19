# サービス有効化
resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "composer.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",       # Composer/BigQuery バケット用
    "compute.googleapis.com",       # VPC ネットワーク用
    "vpcaccess.googleapis.com",     # Serverless VPC Access Connector 用
    "iamcredentials.googleapis.com" # サービスアカウント用
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
}


# データバケット
resource "google_storage_bucket" "data_bucket" {
  name = "${local.project_id}-data-${local.env_suffix}"
  labels = {
    env = local.env_suffix
  }
  location                    = local.region
  uniform_bucket_level_access = true
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}

# サービスアカウント
module "service_accounts" {
  source     = "./modules/service_accounts"
  project_id = local.project_id
  sa_names   = ["vertex"]
  env        = local.env_suffix # dev / prod
}

# BigQuery 用モジュール例
module "bigquery" {
  source      = "terraform-google-modules/bigquery/google"
  version     = "~> 7.0"
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

  deployed_models {
    model           = google_vertex_ai_model.model.id
    display_name    = "${local.model_name}-${local.env_suffix}"
    service_account = module.service_accounts.emails["vertex"]

    # 自動スケーリング設定
    automatic_resources {
      min_replica_count = 1
      max_replica_count = 3
    }
  }
}

# Vertex AI モデル
resource "google_vertex_ai_model" "model" {
  display_name = "${local.model_name}-${local.env_suffix}"
  region       = local.region

  # モデルアセットの GCS パス
  artifact_uri = "gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.model_artifact.name}"

  # 公式コンテナ
  container_spec {
    image_uri     = local.model_image_uri
    predict_route = "/predict"
    health_route  = "/health"
  }

  # 自動スケーリング
  supported_deployment_resources_types = ["AUTOMATIC_RESOURCES"]

  labels = {
    env = local.env_suffix
  }

  depends_on = [
    google_project_service.services["aiplatform.googleapis.com"]
  ]
}

# モデルアーカイブ（ZIP 等）を GCS にアップロード
resource "google_storage_bucket_object" "model_artifact" {
  name         = "models/${local.model_name}/${terraform.workspace}/${local.model_name}.zip"
  bucket       = google_storage_bucket.data_bucket.name
  source       = "${path.module}/artifacts/${local.model_name}.zip"
  content_type = "application/zip"
}

# ワークロード
module "workloads" {
  source     = "./workloads"
  project_id = local.project_id
  env_suffix = local.env_suffix

  depends_on = [google_project_service.services]
}
