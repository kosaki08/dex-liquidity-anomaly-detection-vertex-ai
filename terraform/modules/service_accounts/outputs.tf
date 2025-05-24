output "emails" {
  value = { for k, sa in google_service_account.this : k => sa.email }
}
