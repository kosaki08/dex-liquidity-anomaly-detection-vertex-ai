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
    "bigquerydatatransfer.googleapis.com", # BigQuery Scheduled Query 用
    "dataflow.googleapis.com",             # Feature Store Import が内部で起動
    "cloudfunctions.googleapis.com",       # Cloud Functions のビルド用
    "cloudbuild.googleapis.com",           # Gen2 デプロイ時のビルド用
    "eventarc.googleapis.com",             # HTTP トリガ用
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

# Feature Store
module "feature_store" {
  source       = "./modules/feature_store"
  count        = var.enable_feature_store ? 1 : 0 # 条件付き作成
  project_id   = local.project_id
  project_name = "dex-anomaly-detection"
  region       = local.region
  env_suffix   = local.env_suffix
  kms_key_name = var.kms_key_name

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
  env_suffix            = local.env_suffix
  image_uri             = var.fetcher_image_uri
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
  env_suffix            = local.env_suffix
  image_uri             = var.fetcher_image_uri
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

# Vertex AI Model のデプロイ
resource "google_vertex_ai_endpoint" "prediction" {
  provider     = google-beta
  name         = "dex-prediction-endpoint-${local.env_suffix}"
  display_name = "DEX Anomaly Detection Endpoint"
  location     = local.region

  labels = local.common_labels
}

# API Gateway 用の Cloud Functions
module "prediction_gateway" {
  source = "./modules/cloud_functions"
  count  = var.enable_prediction_gateway ? 1 : 0

  name       = "prediction-gateway-${local.env_suffix}"
  region     = local.region
  project_id = local.project_id

  # ソースコード格納用バケット（既存のデータバケットを使用）
  source_bucket = google_storage_bucket.data_bucket.name

  # ソースディレクトリのパス
  source_dir = "${path.module}/../functions/prediction_gateway"

  # 外部に公開するため認証なし
  allow_unauthenticated = true

  environment_variables = {
    PROJECT_ID  = local.project_id
    ENDPOINT_ID = split("/", google_vertex_ai_endpoint.prediction.id)[4]
    REGION      = local.region
  }

  # 本番環境では最小インスタンス数を1に設定
  min_instances = var.env_suffix == "prod" ? 1 : 0
  max_instances = 10

  service_account = module.service_accounts.emails["vertex"]
  labels          = local.common_labels

  depends_on = [
    google_vertex_ai_endpoint.prediction,
    google_storage_bucket.data_bucket,
    google_project_service.services["cloudfunctions.googleapis.com"],
    google_project_service.services["cloudbuild.googleapis.com"],
  ]
}

# Looker Studio統合
module "looker_integration" {
  source = "./modules/looker_integration"
  count  = var.enable_looker_integration ? 1 : 0

  project_id          = local.project_id
  dataset_id          = module.bigquery.features_dataset_id
  features_dataset_id = module.bigquery.features_dataset_id
  features_table      = "mart_pool_features_labeled"
  region              = local.region
  common_labels       = local.common_labels

  # Looker Studioは通常、エンドユーザーのGoogleアカウントで認証するためサービスアカウントは不要
  looker_service_account = ""

  depends_on = [
    module.bigquery
  ]
}

# モデルアーティファクト用バケット
resource "google_storage_bucket" "model_artifacts" {
  name     = "${local.project_id}-models"
  location = local.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90 # 90日経過した古いバージョンを削除
    }
    action {
      type = "Delete"
    }
  }

  # 最新バージョンの管理用
  lifecycle_rule {
    condition {
      num_newer_versions = 5 # 最新5バージョンを保持
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "model_reader_ci" {
  for_each = toset(["dev", "prod"])

  bucket = google_storage_bucket.model_artifacts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:tf-apply-${each.key}@${local.project_id}.iam.gserviceaccount.com"
}

# モデルアーティファクト用バケットの読み取り権限付与
resource "google_storage_bucket_iam_member" "model_reader_runtime" {
  bucket = google_storage_bucket.model_artifacts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.sa["vertex"]}"
}
