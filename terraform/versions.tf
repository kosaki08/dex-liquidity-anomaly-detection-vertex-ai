terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.35.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.35.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">=2.7.0"
    }
  }
}
