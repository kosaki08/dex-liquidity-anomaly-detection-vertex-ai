data "google_client_config" "this" {}

resource "google_cloud_run_v2_job" "this" {
  name     = var.name
  location = var.region
  project  = data.google_client_config.this.project

  deletion_protection = var.deletion_protection

  # TODO: リソース設定強化
  # cpu / memory limits
  # concurrency の明示

  template {
    template {
      service_account = var.service_account
      containers {
        image = var.image_uri

        # 平文 env
        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }

        env {
          name  = "ENV_SUFFIX"
          value = var.env_suffix
        }

        # Secret 参照 env
        dynamic "env" {
          # シークレットがない場合は空オブジェクト
          for_each = var.secret_name_graph_api == null ? {} : {
            THE_GRAPH_API_KEY = var.secret_name_graph_api
          }
          content {
            name = "THE_GRAPH_API_KEY"
            value_source {
              secret_key_ref {
                secret  = env.value
                version = "latest"
              }
            }
          }
        }
      }
      vpc_access { connector = var.vpc_connector }
      max_retries           = 3
      timeout               = var.env_suffix == "prod" ? "900s" : "600s" # 環境によってタイムアウトを調整
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    }
  }
}
