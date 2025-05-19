output "bigquery_dataset_id" {
  description = "作成された BigQuery データセットの ID"
  value       = module.bigquery.bigquery_dataset.id
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
