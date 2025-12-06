variable "name" {
  description = "Database server name"
  type        = string
}

variable "engine" {
  description = "Database engine (PostgreSQL, MySQL)"
  type        = string
}

variable "version" {
  description = "Database version"
  type        = string
}

variable "sku_name" {
  description = "SKU name (e.g., GP_Gen5_2)"
  type        = string
}

variable "storage_mb" {
  description = "Storage in MB"
  type        = number
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "username" {
  description = "Administrator username"
  type        = string
}

variable "password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port"
  type        = number
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

