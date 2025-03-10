terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use latest compatible version
    }
  }
}

provider "google" {
  project = "gravitai-terraform"
  region  = "us-central1" # Change region as needed
}

# Define a unique prefix for all resources
locals {
  resource_prefix = var.project_id
}