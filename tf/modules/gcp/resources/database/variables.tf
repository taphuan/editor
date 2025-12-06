variable "name" {
  description = "Cloud SQL instance name"
  type        = string
}

variable "database_version" {
  description = "Database version (e.g., MYSQL_8_0, POSTGRES_14)"
  type        = string
}

variable "tier" {
  description = "Machine tier (e.g., db-f1-micro)"
  type        = string
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "private_ip_range" {
  description = "Private IP range for Cloud SQL"
  type        = string
}

variable "username" {
  description = "Root username"
  type        = string
}

variable "password" {
  description = "Root password"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "labels" {
  description = "Labels to apply"
  type        = map(string)
  default     = {}
}

