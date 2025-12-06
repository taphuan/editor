variable "name" {
  description = "Storage account name (must be globally unique)"
  type        = string
}

variable "account_kind" {
  description = "Account kind (StorageV2, BlobStorage, etc.)"
  type        = string
  default     = "StorageV2"
}

variable "account_tier" {
  description = "Account tier (Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
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

