# GitHub Actions Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "gh-pool"
  display_name              = "GitHub Actions Pool"
  description               = "GitHub Actions用のIDプール"
}

# GitHub Actions Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "gh-provider"
  display_name                       = "GitHub Actions Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # GitHubリポジトリとブランチを制限
  attribute_condition = "attribute.repository == '${var.github_organization}/${var.repository_name}' && contains(var.allowed_branches, attribute.ref)"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# dev 環境のTerraform SAにimpersonation権限を付与
resource "google_service_account_iam_member" "github_sa_impersonation_dev" {
  service_account_id = "tf-apply-dev@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_organization}/${var.repository_name}"
}

# prod 環境のTerraform SAにimpersonation権限を付与
resource "google_service_account_iam_member" "github_sa_impersonation_prod" {
  service_account_id = "tf-apply-prod@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_organization}/${var.repository_name}"
}
