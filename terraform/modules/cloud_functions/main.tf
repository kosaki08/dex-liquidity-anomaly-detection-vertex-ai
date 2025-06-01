# Cloud Functions のソースコードを格納するバケット
resource "google_storage_bucket_object" "function_source" {
  name   = "functions/${var.name}-${data.archive_file.function.output_md5}.zip"
  bucket = var.source_bucket
  source = data.archive_file.function.output_path
}

# ソースコードのアーカイブ
data "archive_file" "function" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "/tmp/${var.name}.zip"
}

# Cloud Function (Gen2)
resource "google_cloudfunctions2_function" "function" {
  name     = var.name
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = var.source_bucket
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count    = var.max_instances
    min_instance_count    = var.min_instances
    timeout_seconds       = var.timeout_seconds
    available_memory      = var.memory
    service_account_email = var.service_account

    environment_variables = var.environment_variables
  }

  labels = var.labels
}

# HTTPトリガーの場合のIAM設定
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = google_cloudfunctions2_function.function.project
  location = google_cloudfunctions2_function.function.location
  name     = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
