locals {
  run_job_uri = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/${var.job_name}:run"
}

resource "google_cloud_scheduler_job" "this" {
  name     = var.name
  region   = var.region
  schedule = var.schedule # "0 * * * *"

  http_target {
    http_method = "POST"
    uri         = local.run_job_uri
    oidc_token {
      service_account_email = var.oauth_sa_email
    }
    # Run-Job API は body を使わないので空文字を base64encode
    body = base64encode("")
  }

  retry_config {
    max_retry_duration   = "3600s" # 1h
    min_backoff_duration = "30s"
    max_backoff_duration = "300s"
    max_doublings        = 5
  }
}
