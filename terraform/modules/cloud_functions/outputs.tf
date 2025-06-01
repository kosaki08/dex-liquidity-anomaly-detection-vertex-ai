output "function_uri" {
  description = "Cloud FunctionのURI"
  value       = google_cloudfunctions2_function.function.service_config[0].uri
}

output "function_name" {
  description = "Cloud Functionの名前"
  value       = google_cloudfunctions2_function.function.name
}
