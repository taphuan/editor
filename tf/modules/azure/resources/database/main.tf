locals {
  engine_map = {
    "PostgreSQL" = "postgresql"
    "MySQL"      = "mysql"
  }
}

# Database Server
resource "azurerm_postgresql_flexible_server" "database" {
  count              = var.engine == "PostgreSQL" ? 1 : 0
  name               = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.version

  administrator_login    = var.username
  administrator_password = var.password

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags
}

resource "azurerm_mysql_flexible_server" "database" {
  count              = var.engine == "MySQL" ? 1 : 0
  name               = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.version

  administrator_login    = var.username
  administrator_password = var.password

  sku_name   = var.sku_name
  storage {
    size_gb = var.storage_mb / 1024
  }

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = var.tags
}

# Private Endpoint
resource "azurerm_private_endpoint" "database" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = var.engine == "PostgreSQL" ? azurerm_postgresql_flexible_server.database[0].id : azurerm_mysql_flexible_server.database[0].id
    subresource_names              = var.engine == "PostgreSQL" ? ["postgresqlServer"] : ["mysqlServer"]
  }

  tags = var.tags
}

