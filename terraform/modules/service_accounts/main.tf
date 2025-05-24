resource "google_service_account" "this" {
  for_each     = toset(var.sa_names)
  account_id   = "run-${each.key}-${var.env}"
  display_name = "${each.key} Cloud Run SA (${var.env})"
}
