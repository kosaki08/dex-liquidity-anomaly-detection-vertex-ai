# 各リソースファイルを参照するBigQueryモジュールのエントリーポイント
output "raw_dataset_id" {
  description = "RAWデータセットのID"
  value       = google_bigquery_dataset.dex_raw.dataset_id
}

output "staging_dataset_id" {
  description = "StagingデータセットのID"
  value       = google_bigquery_dataset.dex_staging.dataset_id
}

output "features_dataset_id" {
  description = "FeaturesデータセットのID"
  value       = google_bigquery_dataset.dex_features.dataset_id
}
