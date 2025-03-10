
# Source bucket
resource "google_storage_bucket" "source" {
  name          = "${local.resource_prefix}-source"
  location      = "us-central1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}

# Archive bucket
resource "google_storage_bucket" "archive" {
  name          = "${local.resource_prefix}-archive2"
  location      = "us-central1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}

# Error bucket
resource "google_storage_bucket" "error" {
  name          = "${local.resource_prefix}-error"
  location      = "us-central1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}
