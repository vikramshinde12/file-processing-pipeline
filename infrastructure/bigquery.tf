locals {
  resource_prefix2 = replace(var.project_id, "-", "_")
}

# Create a BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id    = "${local.resource_prefix2}_dataset"
  friendly_name = "My BigQuery Dataset"
  description   = "This dataset is created via Terraform"
  location      = "US"

  labels = {
    environment = "dev"
  }

  depends_on = [google_project_service.enable_apis]
}

# Stage table
resource "google_bigquery_table" "stage_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "${local.resource_prefix2}_user_stage"

  schema = <<EOF
[
  {"name": "id", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "email", "type": "STRING", "mode": "NULLABLE"},
  {"name": "age", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "country", "type": "STRING", "mode": "NULLABLE"},
  {"name": "signup_date", "type": "DATE", "mode": "NULLABLE"},
  {"name": "last_login", "type": "DATE", "mode": "NULLABLE"},
  {"name": "status", "type": "STRING", "mode": "NULLABLE"},
  {"name": "purchase_amount", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "membership_level", "type": "STRING", "mode": "NULLABLE"}
]
EOF

  labels = {
    environment = "dev"
  }

  depends_on = [google_project_service.enable_apis]
}


# Final table
resource "google_bigquery_table" "final_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "${local.resource_prefix2}_users"

  schema = <<EOF
[
  {"name": "id", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "email", "type": "STRING", "mode": "NULLABLE"},
  {"name": "age", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "country", "type": "STRING", "mode": "NULLABLE"},
  {"name": "signup_date", "type": "DATE", "mode": "NULLABLE"},
  {"name": "last_login", "type": "DATE", "mode": "NULLABLE"},
  {"name": "status", "type": "STRING", "mode": "NULLABLE"},
  {"name": "purchase_amount", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "membership_level", "type": "STRING", "mode": "NULLABLE"},
  {"name": "source_filename", "type": "STRING", "mode": "NULLABLE"},
  {"name": "ingest_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"}
]
EOF

  time_partitioning {
    type  = "DAY"
    field = "ingest_timestamp"
  }

  labels = {
    environment = "dev"
  }

  depends_on = [google_project_service.enable_apis]
}
