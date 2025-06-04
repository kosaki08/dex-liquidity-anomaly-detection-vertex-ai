# Feature Store インポートジョブ
module "feature_import_job" {
  source = "./modules/cloud_run_job"
  count  = var.enable_feature_store ? 1 : 0
  depends_on = [
    module.feature_store,           # Feature Store 完成後に実行
    module.bq_export_feature_import # エクスポート先ビュー作成後
  ]

  project_id = local.project_id
  name       = "fs-import-${local.env_suffix}"
  region     = local.region
  env_suffix = local.env_suffix

  image_uri       = var.feature_import_image_uri
  service_account = module.service_accounts.emails["vertex-pipeline"]
  vpc_connector   = module.network.connector_id
  env_vars = {
    FEATURESTORE_ID = var.enable_feature_store ? module.feature_store[0].featurestore_id : ""
    GCS_PATH        = "gs://${local.project_id}-feature-import/hourly/*"
    REGION          = local.region
  }

  # 削除保護を無効化
  deletion_protection = false
}

# Feature Store インポートスケジュール
module "feature_import_schedule" {
  source = "./modules/cloud_scheduler"
  count  = var.enable_feature_store ? 1 : 0 # Feature Store が有効な場合のみ作成
  depends_on = [
    module.feature_import_job,
    module.bq_export_feature_import
  ]

  project_id = local.project_id
  name       = "fs-import-${local.env_suffix}"
  region     = local.region
  schedule   = "15 * * * *" # EXPORT が終わる15分後

  job_name       = var.enable_feature_store ? module.feature_import_job[0].job_name : ""
  oauth_sa_email = module.service_accounts.emails["vertex-pipeline"]
}
