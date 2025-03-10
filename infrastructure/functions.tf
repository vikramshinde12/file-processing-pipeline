# Create a Storage Bucket for Function Source Code
resource "google_storage_bucket" "cf_code_bucket" {
  name          = "${local.resource_prefix}_cf_code_bucket"
  location      = var.region
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.enable_apis]
}

# Upload Cloud Function Source Code (ZIP)
resource "google_storage_bucket_object" "file_process" {
  name   = "file-process.zip"
  bucket = google_storage_bucket.cf_code_bucket.name
  source = "file-process.zip"

  depends_on = [google_storage_bucket.cf_code_bucket]
}




# Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "csv_processing_function" {
  name     = "csv-processing-function"
  location = "us-central1"
  build_config {
    runtime     = "python312"
    entry_point = "process_csv"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_code_bucket.name
        object = google_storage_bucket_object.file_process.name
      }
    }
  }
  service_config {
    max_instance_count             = 1
    available_memory               = "256Mi"
    timeout_seconds                = 60
    all_traffic_on_latest_revision = true
    environment_variables = {
      DATASET_ID          = "${google_bigquery_dataset.dataset.dataset_id}"
      STAGING_TABLE_ID    = "${google_bigquery_table.stage_table.id}"
      FINAL_TABLE_ID      = "${google_bigquery_table.final_table.id}"
      ARCHIVE_BUCKET_NAME = "${google_storage_bucket.archive.name}"
    }
  }
}


# Upload Cloud Function Source Code (ZIP)
resource "google_storage_bucket_object" "file_validations" {
  name   = "file-validations.zip"
  bucket = google_storage_bucket.cf_code_bucket.name
  source = "file-validations.zip"

  depends_on = [google_storage_bucket.cf_code_bucket]
}

# Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "file_validations_function" {
  name     = "file-validations-function"
  location = "us-central1"
  build_config {
    runtime     = "python312"
    entry_point = "validate_file"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_code_bucket.name
        object = google_storage_bucket_object.file_validations.name
      }
    }
  }
  service_config {
    max_instance_count             = 1
    available_memory               = "256Mi"
    timeout_seconds                = 60
    all_traffic_on_latest_revision = true
    environment_variables = {
      ERROR_BUCKET_NAME   = "${google_storage_bucket.error.name}"
    }
  }

  event_trigger {
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = google_service_account.account.email
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.source.name
    }
  }
}