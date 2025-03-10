# Create a Pub/Sub Topic
resource "google_pubsub_topic" "validated" {
  name = "${local.resource_prefix}_validated"

  labels = {
    environment = "dev"
  }

  depends_on = [google_project_service.enable_apis]
}

resource "google_pubsub_topic" "failed" {
  name = "${local.resource_prefix}_failed"

  labels = {
    environment = "dev"
  }

  depends_on = [google_project_service.enable_apis]
}
