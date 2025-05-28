data "google_client_config" "this" {}

resource "google_cloud_run_v2_job" "this" {
  name     = var.name
  location = var.region
  project  = data.google_client_config.this.project

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

        # Secret 参照 env
        env {
          name = "THE_GRAPH_API_KEY"

          value_source {
            secret_key_ref {
              secret  = var.secret_name_graph_api
              version = "latest"
            }
          }
        }
      }
      vpc_access { connector = var.vpc_connector }
      max_retries           = 3
      timeout               = "600s"
      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    }
  }
}
