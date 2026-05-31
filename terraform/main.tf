terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("${path.module}/service-account.json")
  project     = var.project_id
  region      = var.region
}

# Raw dataset — ingestion layer
resource "google_bigquery_dataset" "raw" {
  dataset_id    = var.bq_dataset_raw
  friendly_name = "Bursa Pulse Raw"
  description   = "Raw ingested data from yfinance and Frankfurter API"
  location      = var.region

  labels = {
    env     = "production"
    project = "bursa-pulse"
    layer   = "raw"
  }
}

# Staging dataset — cleaning and type casting
resource "google_bigquery_dataset" "staging" {
  dataset_id    = var.bq_dataset_staging
  friendly_name = "Bursa Pulse Staging"
  description   = "Cleaned and typed data, ready for transformation"
  location      = var.region

  labels = {
    env     = "production"
    project = "bursa-pulse"
    layer   = "staging"
  }
}

# Mart dataset — business-ready analytics tables
resource "google_bigquery_dataset" "mart" {
  dataset_id    = var.bq_dataset_mart
  friendly_name = "Bursa Pulse Mart"
  description   = "Dimensional models and analytics tables for reporting"
  location      = var.region

  labels = {
    env     = "production"
    project = "bursa-pulse"
    layer   = "mart"
  }
}
