output "raw_dataset_id" {
  description = "BigQuery raw dataset ID"
  value       = google_bigquery_dataset.raw.dataset_id
}

output "staging_dataset_id" {
  description = "BigQuery staging dataset ID"
  value       = google_bigquery_dataset.staging.dataset_id
}

output "mart_dataset_id" {
  description = "BigQuery mart dataset ID"
  value       = google_bigquery_dataset.mart.dataset_id
}
