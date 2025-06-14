output "tf_apply_sa_email" {
  description = "Terraform Apply SA のメールアドレス"
  value       = google_service_account.tf_apply.email
}

output "state_bucket" {
  description = "Terraform state バケット名"
  value       = var.state_bucket
}
