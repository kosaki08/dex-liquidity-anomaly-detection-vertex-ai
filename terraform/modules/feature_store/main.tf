# Feature Store本体（オンライン/オフライン特徴量の永続化ストレージ）
resource "google_vertex_ai_featurestore" "main" {
  name    = "${replace(var.project_name, "-", "_")}_featurestore_${var.env_suffix}"
  region  = var.region
  project = var.project_id

  labels = var.common_labels

  online_serving_config {
    fixed_node_count = var.online_serving_node_count
  }

  depends_on = [var.aiplatform_service_dependency]

  # KMS暗号化（prodのみ）
  dynamic "encryption_spec" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      kms_key_name = var.kms_key_name
    }
  }
}

# DEX liquidity data の Entity Type
resource "google_vertex_ai_featurestore_entitytype" "dex_liquidity" {
  name         = "dex_liquidity"
  featurestore = google_vertex_ai_featurestore.main.id

  labels = var.common_labels
}

# 基本的な特徴量のみ（monitoring設定なし）
resource "google_vertex_ai_featurestore_entitytype_feature" "features" {
  for_each = var.basic_features

  name       = each.key
  entitytype = google_vertex_ai_featurestore_entitytype.dex_liquidity.id

  labels     = var.common_labels
  value_type = each.value.value_type

  description = lookup(each.value, "description", null) # 存在しない場合は null
}
