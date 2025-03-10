import datetime
import functions_framework
import google.cloud.storage as storage
from google.cloud import pubsub_v1
from datetime import datetime
import csv
import io
import os
import json
from cloudevents.http.event import CloudEvent
import logging


@functions_framework.cloud_event
def validate_file(cloud_event: CloudEvent) -> None:

    print(f"start: {cloud_event}")
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_name = data["name"]
    gcs_uri = f"gs://{bucket_name}/{file_name}"

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_name)
    csv_string = blob.download_as_text()

    error_bucket_name = os.environ.get('ERROR_BUCKET_NAME')

    required_columns = {"id", "name", "email", "age", "country", "signup_date", "last_login", "status",
                        "purchase_amount", "membership_level"}

    print(bucket_name)
    print(gcs_uri)

    try:
        csv_file = csv.DictReader(io.StringIO(csv_string))

        # Check if the CSV is empty
        if not csv_file.fieldnames:
            raise ValueError("CSV file is empty or has no header.")

        # Check if all required columns are present
        missing_columns = required_columns - set(csv_file.fieldnames)
        if missing_columns:
            raise ValueError(f"Missing required columns: {missing_columns}")

        # Validation successful
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path("gravitai-demo", "csv-validated")
        
        # Convert dictionary to JSON string
        data = {"gcs_uri": gcs_uri}
        message_data = json.dumps(data).encode("utf-8")
        
        # Publish message
        publisher.publish(topic_path, message_data)
        print(f"Validation successful for {gcs_uri}")

    except Exception as e:
        print(f"Validation failed for {gcs_uri}: {e}")
        publisher = pubsub_v1.PublisherClient()
        topic_path = publisher.topic_path("gravitai-demo", "csv-validation-failed")
        message_data = f"Validation failed for {gcs_uri}: {e}".encode("utf-8")
        publisher.publish(topic_path, message_data)

        # Move file to error bucket
        error_bucket = storage_client.bucket(error_bucket_name)
        error_file_name = f"{file_name}-error-{datetime.now().strftime('%Y%m%d%H%M%S')}.csv"

        blob_copy = bucket.copy_blob(
            blob, error_bucket, error_file_name
        )


        print(
            "Blob {} in bucket {} copied to blob {} in bucket {}.".format(
                blob.name,
                bucket.name,
                blob_copy.name,
                error_bucket.name,
            )
        )

        blob.delete()