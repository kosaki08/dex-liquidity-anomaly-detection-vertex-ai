output "job_name" {
  value       = google_cloud_run_v2_job.this.name
  description = "Cloud Run Job の名前"
}
