resource "google_bigquery_data_transfer_config" "export_mart_pool_features" {
  display_name   = "export_feature_values_parquet"
  data_source_id = "scheduled_query"
  schedule       = "every 1 hours" # 00分スタート

  destination_dataset_id = var.destination_dataset_id
  project                = var.project_id
  location               = var.region

  params = {
    query = templatefile("${path.module}/export_feature_values.sql", {
      project_id = var.project_id,
      dataset_id = var.dataset_id,
    })
    destination_table_name_template = "unused" # EXPORT DATA なので実際には使わない
    write_disposition               = "WRITE_TRUNCATE"
  }
}
