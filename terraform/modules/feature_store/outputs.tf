output "featurestore_id" {
  description = "Feature Store のID"
  value       = google_vertex_ai_featurestore.main.id
}

output "featurestore_name" {
  description = "Feature Store の名前"
  value       = google_vertex_ai_featurestore.main.name
}

output "entitytype_id" {
  description = "Entity Type のID"
  value       = google_vertex_ai_featurestore_entitytype.dex_liquidity.id
}

output "feature_ids" {
  description = "作成された特徴量のID"
  value       = { for k, v in google_vertex_ai_featurestore_entitytype_feature.features : k => v.id }
}
