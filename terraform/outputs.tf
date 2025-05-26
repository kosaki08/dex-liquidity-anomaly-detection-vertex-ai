output "bigquery_dataset_id" {
  description = "作成された BigQuery データセットの ID"
  value       = module.bigquery.raw_dataset_id
}

output "vertex_ai_endpoint_id" {
  description = "作成された Vertex AI エンドポイントの ID"
  value       = google_vertex_ai_endpoint.endpoint.id
}

output "vertex_ai_endpoint_name" {
  description = "作成された Vertex AI エンドポイントのリソース名"
  value       = google_vertex_ai_endpoint.endpoint.name
}

output "data_bucket_name" {
  description = "The Graph 生 JSONL を置く GCS バケット名"
  value       = google_storage_bucket.data_bucket.name
}

# ---------- Feature Store 関連の output ----------
output "featurestore_id" {
  description = "作成された Feature Store の ID"
  value       = var.enable_feature_store ? module.feature_store[0].featurestore_id : null
}

output "featurestore_name" {
  description = "作成された Feature Store の名前"
  value       = var.enable_feature_store ? module.feature_store[0].featurestore_name : null
}

output "entitytype_id" {
  description = "作成された Entity Type の ID"
  value       = var.enable_feature_store ? module.feature_store[0].entitytype_id : null
}
