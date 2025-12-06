variable "cloud_provider" {
  description = "Cloud provider to deploy to: aws, azure, or gcp"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Cloud provider must be one of: aws, azure, gcp"
  }
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "multi-cloud-vpc"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Cloud region to deploy resources"
  type        = string
  default     = ""
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC/VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones (will use defaults if not specified)"
  type        = list(string)
  default     = []
}

# Compute Configuration
variable "jumphost_instance_type" {
  description = "Instance type for jumphost"
  type        = string
  default     = "t3.micro" # AWS default, will be mapped per cloud
}

variable "jumphost_ssh_key" {
  description = "SSH public key for jumphost access"
  type        = string
  default     = ""
}

variable "enable_jumphost" {
  description = "Enable jumphost in public subnet"
  type        = bool
  default     = true
}

# Private VMs Configuration
variable "private_vms" {
  description = "List of private VMs to create"
  type = list(object({
    name         = string
    instance_type = string
    subnet_index = number
  }))
  default = [
    {
      name          = "private-vm-1"
      instance_type = "t3.micro"
      subnet_index  = 0
    }
  ]
}

# Database Configuration
variable "databases" {
  description = "List of databases to create"
  type = list(object({
    name         = string
    engine       = string      # mysql, postgresql, sqlserver (AWS), PostgreSQL, MySQL (Azure), mysql, postgres (GCP)
    version      = string
    instance_class = string    # db.t3.micro (AWS), GP_Gen5_2 (Azure), db-f1-micro (GCP)
    allocated_storage = number  # GB
    subnet_index     = number
    username         = string
    password         = string
    port             = number
  }))
  default = []
}

# Storage Configuration
variable "storage_accounts" {
  description = "List of storage accounts to create"
  type = list(object({
    name          = string
    account_kind  = string    # StorageV2 (Azure), Standard (AWS S3), STANDARD (GCS)
    account_tier  = string    # Hot/Cool (Azure), Standard/Intelligent-Tiering (AWS), STANDARD (GCS)
    replication_type = string # LRS/GRS (Azure), null (AWS), REGIONAL/MULTI_REGIONAL (GCS)
  }))
  default = []
}

# Vault Configuration
variable "vaults" {
  description = "List of vaults/secrets managers to create"
  type = list(object({
    name = string
  }))
  default = []
}

# Cloud-specific variables
variable "aws_access_key" {
  description = "AWS access key (optional, can use AWS credentials)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key (optional, can use AWS credentials)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_credentials_path" {
  description = "Path to GCP credentials JSON file"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
