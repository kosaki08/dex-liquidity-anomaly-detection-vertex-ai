# Feature Store の作成
resource "google_vertex_ai_featurestore" "main" {
  name    = "${replace(var.project_name, "-", "_")}_featurestore_${var.env_suffix}"
  region  = var.region
  project = var.project_id

  labels = var.common_labels

  online_serving_config {
    fixed_node_count = var.online_serving_node_count
  }

  depends_on = [var.aiplatform_service_dependency]
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

  description = each.value.description
}
