# Enable Required Google Cloud APIs
resource "google_project_service" "enable_apis" {
  for_each = toset([
    "storage.googleapis.com",              # Cloud Storage API
    "cloudresourcemanager.googleapis.com", # Resource Manager API
    "iam.googleapis.com",                  # Identity & Access Management API
    "artifactregistry.googleapis.com",     # Artifact Registry AP
    "cloudbuild.googleapis.com",           #Cloud Build API 
    "run.googleapis.com",                  # Cloud Run Admin API 
    "pubsub.googleapis.com",               #Cloud Pub/Sub API 
    "bigquery.googleapis.com",             # BigQuery API
    "workflows.googleapis.com",            # Workflows
    "eventarc.googleapis.com",             # Eventarc API
    "cloudfunctions.googleapis.com"        # Cloud Function API

  ])

  project = var.project_id
  service = each.key

  disable_on_destroy = false
}