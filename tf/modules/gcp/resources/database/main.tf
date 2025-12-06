locals {
  is_mysql = startswith(var.database_version, "MYSQL")
  is_postgres = startswith(var.database_version, "POSTGRES")
}

# Private IP Address
resource "google_compute_global_address" "private_ip" {
  name          = "${var.name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network
  project       = var.project_id
}

# VPC Peering
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

# Cloud SQL Instance
resource "google_sql_database_instance" "database" {
  name             = var.name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier                        = var.tier
    disk_size                   = var.disk_size
    disk_type                   = "PD_SSD"
    disk_autoresize             = true
    disk_autoresize_limit       = 0
    deletion_protection_enabled = false

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network
      enable_private_path_for_google_cloud_services = true
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length      = 1024
      record_application_tags  = true
      record_client_address   = true
    }
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  labels = var.labels
}

# Database
resource "google_sql_database" "database" {
  count    = local.is_postgres ? 1 : 0
  name     = var.name
  instance = google_sql_database_instance.database.name
  project  = var.project_id
}

# User
resource "google_sql_user" "database" {
  name     = var.username
  instance = google_sql_database_instance.database.name
  password = var.password
  project  = var.project_id
}

