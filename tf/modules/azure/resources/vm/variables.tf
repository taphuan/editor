variable "name" {
  description = "Name of the VM instance"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where VM will be deployed"
  type        = string
}

variable "network_security_group_id" {
  description = "Network security group ID"
  type        = string
}

variable "public_ip_id" {
  description = "Public IP ID (optional, for public VMs)"
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
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

