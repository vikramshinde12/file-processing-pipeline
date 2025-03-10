import datetime

import functions_framework
import google.cloud.storage as storage
from google.cloud import bigquery
from datetime import datetime

import csv
import io
import json
import os

@functions_framework.http
def process_csv(request):
    request_json = request.get_json(silent=True)
    print(f"received payload: {request_json}")
    if request_json and 'gcs_uri' in request_json:
        gcs_uri = request_json['gcs_uri']
        bucket_name = gcs_uri.split('/')[2]
        file_name = '/'.join(gcs_uri.split('/')[3:])

        print(f"gcs_uri: {gcs_uri}")

        storage_client = storage.Client()
        source_bucket = storage_client.bucket(bucket_name)
        blob = source_bucket.blob(file_name)
        csv_string = blob.download_as_text()

        print(f"csv_string: {csv_string}")

        bigquery_client = bigquery.Client()
        dataset_id = os.environ.get('DATASET_ID') # Get environment variables
        staging_table_id = os.environ.get('STAGING_TABLE_ID')
        final_table_id = os.environ.get('FINAL_TABLE_ID')
        archive_bucket_name = os.environ.get('ARCHIVE_BUCKET_NAME')

        if not dataset_id or not staging_table_id or not final_table_id:
            return "Error: BigQuery configuration not set in environment variables.", 500

        # Load CSV to staging table
        table_ref = bigquery_client.dataset(dataset_id).table(staging_table_id)
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            autodetect=True,
            skip_leading_rows=1,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # Overwrite
        )
        load_job = bigquery_client.load_table_from_file(
            io.StringIO(csv_string), table_ref, job_config=job_config
        )
        load_job.result()  # Wait for load to complete

        print('at line 46')

        # Transform data and load to final table
        query = f"""
                INSERT INTO `{dataset_id}.{final_table_id}` (id, name, email, age, country, signup_date, last_login, status, purchase_amount, membership_level, source_filename, ingest_timestamp)
                SELECT
                    DISTINCT id,
                    TRIM(name) AS name,
                    TRIM(email) AS email,
                    SAFE_CAST(age AS INT64) AS age,
                    TRIM(country) AS country,
                    SAFE_CAST(signup_date AS DATE) AS signup_date,
                    SAFE_CAST(last_login AS DATE) AS last_login,
                    TRIM(status) AS status,
                    SAFE_CAST(purchase_amount AS FLOAT64) AS purchase_amount,
                    TRIM(membership_level) AS membership_level,
                    "{file_name}" AS source_filename,
                    current_timestamp as ingest_timestamp
                FROM (
                    SELECT
                        *,
                        ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) AS rn
                    FROM
                        `{dataset_id}.{staging_table_id}`
                    WHERE SAFE_CAST(purchase_amount AS FLOAT64) >= 0 -- Negative purchase check
                    AND SAFE_CAST(signup_date AS DATE) IS NOT NULL -- Invalid date check
                )
                WHERE rn = 1; -- Deduplication
                """

        query_job = bigquery_client.query(query)
        query_job.result()
        print(f"Data processed and loaded to {dataset_id}.{final_table_id}")


        # Move file to archive bucket
        archive_bucket = storage_client.bucket(archive_bucket_name)
        archive_file_name = f"{file_name}-archive-{datetime.now().strftime('%Y%m%d%H%M%S')}.csv"

        blob_copy = source_bucket.copy_blob(
            blob, archive_bucket, archive_file_name
        )


        print(
            "Blob {} in bucket {} copied to blob {} in bucket {}.".format(
                blob.name,
                source_bucket.name,
                blob_copy.name,
                archive_bucket.name,
            )
        )

        blob.delete()

        return "Data processed successfully"

    else:
        return "Error: gcs_uri not provided", 400