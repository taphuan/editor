variable "name" {
  description = "Name of the VM instance"
  type        = string
}

variable "machine_type" {
  description = "Machine type"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name"
  type        = string
}

variable "network" {
  description = "Network name"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "tags" {
  description = "Network tags"
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
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

variable "public_ip" {
  description = "Assign public IP"
  type        = bool
  default     = false
}

