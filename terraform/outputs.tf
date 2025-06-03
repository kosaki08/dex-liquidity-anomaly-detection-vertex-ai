output "bigquery_dataset_id" {
  description = "作成された BigQuery データセットの ID"
  value       = module.bigquery.raw_dataset_id
}

output "vertex_ai_endpoint_id" {
  description = "Vertex AI Endpoint のリソース ID"
  value       = google_vertex_ai_endpoint.prediction.id
}

output "vertex_ai_endpoint_name" {
  description = "Vertex AI Endpoint の名前"
  value       = google_vertex_ai_endpoint.prediction.name
}

output "data_bucket_name" {
  description = "The Graph 生 JSONL を置く GCS バケット名"
  value       = google_storage_bucket.data_bucket.name
}

output "featurestore_id" {
  description = "作成された Feature Store の ID"
  value       = try(module.feature_store[0].featurestore_id, null)
}

output "featurestore_name" {
  description = "作成された Feature Store の名前"
  value       = try(module.feature_store[0].featurestore_name, null)
}

output "entitytype_id" {
  description = "作成された Entity Type の ID"
  value       = try(module.feature_store[0].entitytype_id, null)
}

output "vertex_ai_endpoint_numeric_id" {
  description = "Vertex AI Endpoint の数値 ID"
  value       = split("/", google_vertex_ai_endpoint.prediction.id)[length(split("/", google_vertex_ai_endpoint.prediction.id)) - 1]
}

