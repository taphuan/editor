output "instance_id" {
  description = "Cloud SQL instance ID"
  value       = google_sql_database_instance.database.id
}

output "connection_name" {
  description = "Connection name"
  value       = google_sql_database_instance.database.connection_name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.database.private_ip_address
}

output "port" {
  description = "Database port"
  value       = local.is_mysql ? 3306 : 5432
}

