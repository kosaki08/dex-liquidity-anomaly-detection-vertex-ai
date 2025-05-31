output "service_name" {
  description = "Cloud Run Service の名前"
  value       = google_cloud_run_v2_service.this.name
}

output "service_uri" {
  description = "Cloud Run Service のURI"
  value       = google_cloud_run_v2_service.this.uri
}

output "service_id" {
  description = "Cloud Run Service のID"
  value       = google_cloud_run_v2_service.this.id
}
