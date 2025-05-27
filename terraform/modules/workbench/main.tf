resource "google_workbench_instance" "this" {
  name     = "wb-${var.env_suffix}"
  project  = var.project_id
  location = var.zone

  # GCE 設定
  gce_setup {
    machine_type = "e2-medium" # 2 vCPU, 4GB RAM

    # ブートディスク
    boot_disk {
      disk_type    = "PD_SSD" # SSD
      disk_size_gb = 100      # 100GB
    }

    # サービスアカウント
    service_accounts {
      email = var.sa_email
    }

    # ネットワーク
    network_interfaces {
      network = var.network_self_link
      subnet  = var.subnet_self_link # サブネット
    }

    # VM イメージ
    vm_image {
      project = "deeplearning-platform-release"
      family  = "tf-latest-cpu"
    }

    # IP 転送
    enable_ip_forwarding = false
  }

  labels = {
    env   = var.env_suffix
    stack = "mlops"
  }
}
