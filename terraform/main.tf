# サービス有効化
resource "google_project_service" "services" {
  for_each = toset([
    "bigquery.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",              # BigQuery バケット用
    "notebooks.googleapis.com",            # Vertex AI Notebook 用
    "compute.googleapis.com",              # VPC ネットワーク用
    "vpcaccess.googleapis.com",            # Serverless VPC Access Connector 用
    "iamcredentials.googleapis.com",       # サービスアカウント用
    "secretmanager.googleapis.com",        # シークレットマネージャー用
    "run.googleapis.com",                  # Cloud Run Job 用
    "cloudscheduler.googleapis.com",       # Cloud Scheduler 用
    "bigquerydatatransfer.googleapis.com", # ← BigQuery Scheduled Query 用
    "dataflow.googleapis.com",             # ← Feature Store Import が内部で起動
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
#tfsec:ignore:AVD-GCP-0066  dev環境はGoogle-managed暗号化で許容
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

  # 暗号化
  dynamic "encryption" {
    for_each = var.env_suffix == "prod" && var.kms_key_name != null ? [1] : [] # prod 環境で KMS キーが設定されている場合のみ暗号化
    content {
      # デフォルトの KMS キーを設定
      default_kms_key_name = var.kms_key_name
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

# BigQueryモジュール
module "bigquery" {
  source         = "./modules/bigquery"
  project_id     = local.project_id
  region         = local.region
  dataset_prefix = var.dataset_prefix
  env_suffix     = local.env_suffix
  common_labels  = local.common_labels
  kms_key_name   = var.kms_key_name
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

# BigQuery → GCS → Feature Store へのインポート定義
module "bq_export_feature_import" {
  source                 = "./modules/bq_export_feature_import"
  project_id             = local.project_id
  region                 = local.region
  destination_dataset_id = module.bigquery.staging_dataset_id
  dataset_id             = module.bigquery.features_dataset_id
}

# Notebook / Vertex AI Workbench
module "workbench" {
  source            = "./modules/workbench"
  project_id        = local.project_id
  zone              = var.workbench_zone
  env_suffix        = local.env_suffix # dev / prod
  network_self_link = module.network.network_self_link
  subnet_self_link  = module.network.subnetwork_self_link
  sa_email          = module.service_accounts.emails["vertex-pipeline"]

  depends_on = [
    google_project_service.services["notebooks.googleapis.com"]
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

# Uniswap フェッチャー
module "fetcher_job_uniswap" {
  source                = "./modules/cloud_run_job"
  project_id            = local.project_id
  name                  = "dex-fetch-uni-${local.env_suffix}"
  region                = local.region
  image_uri             = "${local.region}-docker.pkg.dev/${local.project_id}/ml/fetcher:latest"
  secret_name_graph_api = google_secret_manager_secret.api_keys["the-graph-api-key"].secret_id
  service_account       = module.service_accounts.emails["vertex"]
  vpc_connector         = module.network.connector_id
  deletion_protection   = var.env_suffix == "prod" # prod 環境では削除保護
  env_vars = {
    PROJECT_ID                    = local.project_id
    ENV_SUFFIX                    = local.env_suffix
    RAW_BUCKET                    = google_storage_bucket.data_bucket.name
    PROTOCOL                      = "uniswap"
    THE_GRAPH_UNISWAP_SUBGRAPH_ID = "5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV"
  }
  depends_on = [
    google_project_service.services["run.googleapis.com"]
  ]
}

# Uniswap フェッチャースケジュール
module "fetcher_schedule_uniswap" {
  source         = "./modules/cloud_scheduler"
  name           = "dex-fetch-uniswap-${local.env_suffix}"
  region         = local.region
  schedule       = "0 * * * *"
  job_name       = module.fetcher_job_uniswap.job_name
  oauth_sa_email = module.service_accounts.emails["vertex-pipeline"]
  depends_on     = [module.fetcher_job_uniswap]
}

# Sushiswap フェッチャー
module "fetcher_job_sushiswap" {
  source                = "./modules/cloud_run_job"
  project_id            = local.project_id
  name                  = "dex-fetch-sushi-${local.env_suffix}"
  region                = local.region
  image_uri             = "${local.region}-docker.pkg.dev/${local.project_id}/ml/fetcher:latest"
  secret_name_graph_api = google_secret_manager_secret.api_keys["the-graph-api-key"].secret_id
  service_account       = module.service_accounts.emails["vertex"]
  vpc_connector         = module.network.connector_id
  deletion_protection   = var.env_suffix == "prod" # prod 環境では削除保護
  env_vars = {
    PROJECT_ID                      = local.project_id
    ENV_SUFFIX                      = local.env_suffix
    RAW_BUCKET                      = google_storage_bucket.data_bucket.name
    PROTOCOL                        = "sushiswap"
    THE_GRAPH_SUSHISWAP_SUBGRAPH_ID = "5nnoU1nUFeWqtXgbpC54L9PWdpgo7Y9HYinR3uTMsfzs"
  }
  depends_on = [
    google_project_service.services["run.googleapis.com"]
  ]
}

# Sushiswap フェッチャースケジュール
module "fetcher_schedule_sushiswap" {
  source         = "./modules/cloud_scheduler"
  name           = "dex-fetch-sushiswap-${local.env_suffix}"
  region         = local.region
  schedule       = "0 * * * *"
  job_name       = module.fetcher_job_sushiswap.job_name
  oauth_sa_email = module.service_accounts.emails["vertex-pipeline"]
  depends_on     = [module.fetcher_job_sushiswap]
}

# ワークロード
module "workloads" {
  source     = "./workloads"
  project_id = local.project_id
  env_suffix = local.env_suffix

  depends_on = [google_project_service.services]
}
