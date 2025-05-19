# 1) トレーニング
output "sa_training_email" {
  description = "Training SA のメールアドレス"
  value       = google_service_account.sa_training.email
}

# 2) バッチ推論
output "sa_batch_predict_email" {
  description = "Batch Prediction SA のメールアドレス"
  value       = google_service_account.sa_batch_predict.email
}

# 3) モデル登録
output "sa_model_registry_email" {
  description = "Model Registry SA のメールアドレス"
  value       = google_service_account.sa_model_registry.email
}

# 4) データ準備
output "sa_data_prep_email" {
  description = "Data Prep SA のメールアドレス"
  value       = google_service_account.sa_data_prep.email
}

# 5) オーケストレーション
output "sa_orchestrator_email" {
  description = "Orchestrator SA のメールアドレス"
  value       = google_service_account.sa_orchestrator.email
}

# 6) 監視・運用
output "sa_ops_email" {
  description = "Ops SA のメールアドレス"
  value       = google_service_account.sa_ops.email
}

