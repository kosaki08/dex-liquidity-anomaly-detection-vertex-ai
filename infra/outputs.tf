output "bigquery_dataset_id" {
  description = "作成された BigQuery データセットの ID"
  value       = module.bigquery.dataset_id
}

output "composer_environment_name" {
  description = "作成された Cloud Composer 環境の名前"
  value       = google_composer_environment.dex.name
}

output "composer_airflow_uri" {
  description = "作成された Cloud Composer 環境の Airflow UI の URL"
  value       = google_composer_environment.dex.config[0].airflow_uri
  sensitive   = true # URLには認証情報が含まれる場合があるため、sensitiveに設定
}

output "vertex_ai_endpoint_id" {
  description = "作成された Vertex AI エンドポイントの ID"
  value       = google_vertex_ai_endpoint.endpoint.id
}

output "vertex_ai_endpoint_name" {
  description = "作成された Vertex AI エンドポイントのリソース名"
  value       = google_vertex_ai_endpoint.endpoint.name
}

output "vertex_ai_model_id" {
  description = "デプロイされた Vertex AI モデルの ID"
  value       = google_vertex_ai_model.model.id
}

output "vertex_ai_model_name" {
  description = "デプロイされた Vertex AI モデルのリソース名"
  value       = google_vertex_ai_model.model.name
}
