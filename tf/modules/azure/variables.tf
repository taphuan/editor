variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure location/region"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "jumphost_vm_size" {
  description = "VM size for jumphost"
  type        = string
}

variable "private_vm_size" {
  description = "VM size for private VM"
  type        = string
}

variable "jumphost_ssh_key" {
  description = "SSH public key for jumphost"
  type        = string
  default     = ""
}

variable "enable_jumphost" {
  description = "Enable jumphost"
  type        = bool
  default     = true
}

variable "enable_private_vm" {
  description = "Enable private VM"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

