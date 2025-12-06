output "server_id" {
  description = "Database server ID"
  value       = var.engine == "PostgreSQL" ? azurerm_postgresql_flexible_server.database[0].id : azurerm_mysql_flexible_server.database[0].id
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = var.engine == "PostgreSQL" ? azurerm_postgresql_flexible_server.database[0].fqdn : azurerm_mysql_flexible_server.database[0].fqdn
}

output "port" {
  description = "Database port"
  value       = var.port
}

