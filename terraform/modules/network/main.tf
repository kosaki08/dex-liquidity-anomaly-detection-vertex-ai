# 1) VPC ネットワーク作成
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 2) プライマリリージョンサブネット追加
resource "google_compute_subnetwork" "private" {
  project                  = var.project_id
  name                     = "${var.network_name}-subnet"
  ip_cidr_range            = var.subnet_ip_cidr_range
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # Secret Manager など Private Google APIs に到達するため設定
  log_config {
    aggregation_interval = "INTERVAL_5_MIN"       # ログ集計間隔5分ごと
    flow_sampling        = 0.5                    # サンプリング率50%
    metadata             = "INCLUDE_ALL_METADATA" # メタデータを含める
  }
}

# 3) Serverless VPC Access Connector
resource "google_vpc_access_connector" "connector" {
  project        = var.project_id
  name           = var.vpc_connector_name
  region         = var.region
  network        = google_compute_network.vpc.name
  ip_cidr_range  = var.connector_ip_cidr_range
  min_throughput = 300
  max_throughput = 600
}

# 4) インターネットへのアウトバウンドを許可
resource "google_compute_firewall" "allow_egress_internet" {
  name    = "${var.network_name}-egress"
  project = var.project_id
  network = google_compute_network.vpc.name

  direction = "EGRESS"
  allow {
    protocol = "tcp"
    ports = [
      "443", # HTTPS - GCP API、Container Registry、外部API通信
      "80"   # HTTP - 一部のパッケージダウンロード、リダイレクト用
    ]
  }

  destination_ranges = [
    "199.36.153.4/30",    # Private Google Access（GCP APIs）
    "169.254.169.254/32", # Metadata server（認証情報取得）
  ]
  priority = 65534 # GCP のデフォルトの最低優先度
}
