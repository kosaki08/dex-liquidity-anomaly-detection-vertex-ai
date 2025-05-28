locals {
  # 読み取りが必要な SA 一覧
  secret_readers = [
    module.service_accounts.emails["vertex"],          # run-vertex-dev
    module.service_accounts.emails["vertex-pipeline"], # run-vertex-pipeline-dev
  ]
}

resource "google_secret_manager_secret_iam_member" "graph_api_access" {
  for_each = toset(local.secret_readers)

  secret_id = google_secret_manager_secret.api_keys["the-graph-api-key"].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value}"
}
