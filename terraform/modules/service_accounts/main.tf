resource "google_service_account" "this" {
  for_each     = toset(var.sa_names)
  account_id   = "run-${each.key}-${var.env}"
  display_name = "${each.key} Service Account (${var.env})"
  project      = var.project_id
}
