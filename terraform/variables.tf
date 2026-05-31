variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "bq_dataset_raw" {
  description = "BigQuery dataset for raw data"
  type        = string
  default     = "bursa_pulse_raw"
}

variable "bq_dataset_staging" {
  description = "BigQuery dataset for staging"
  type        = string
  default     = "bursa_pulse_staging"
}

variable "bq_dataset_mart" {
  description = "BigQuery dataset for mart/analytics"
  type        = string
  default     = "bursa_pulse_mart"
}
