# Configure providers based on selected cloud
provider "aws" {
  region     = var.cloud_provider == "aws" ? var.region : "us-east-1"
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null
}

provider "azurerm" {
  features {}
  subscription_id = var.cloud_provider == "azure" ? var.azure_subscription_id : null
  client_id       = var.cloud_provider == "azure" ? var.azure_client_id : null
  client_secret   = var.cloud_provider == "azure" ? var.azure_client_secret : null
  tenant_id       = var.cloud_provider == "azure" ? var.azure_tenant_id : null
}

provider "google" {
  project     = var.cloud_provider == "gcp" ? var.gcp_project_id : null
  credentials = var.cloud_provider == "gcp" && var.gcp_credentials_path != "" ? file(var.gcp_credentials_path) : null
  region      = var.cloud_provider == "gcp" ? var.region : null
}

# Local values for common naming and configuration
locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      Provider    = var.cloud_provider
    }
  )

  # Map instance types per cloud
  instance_type_map = {
    aws = {
      jumphost     = var.jumphost_instance_type
      private_vm   = var.private_vm_instance_type
    }
    azure = {
      jumphost     = var.jumphost_instance_type == "t3.micro" ? "Standard_B1s" : var.jumphost_instance_type
      private_vm   = var.private_vm_instance_type == "t3.micro" ? "Standard_B1s" : var.private_vm_instance_type
    }
    gcp = {
      jumphost     = var.jumphost_instance_type == "t3.micro" ? "e2-micro" : var.jumphost_instance_type
      private_vm   = var.private_vm_instance_type == "t3.micro" ? "e2-micro" : var.private_vm_instance_type
    }
  }

  # Default regions per cloud
  default_regions = {
    aws   = "us-east-1"
    azure = "eastus"
    gcp   = "us-central1"
  }

  selected_region = var.region != "" ? var.region : local.default_regions[var.cloud_provider]
}

# Deploy AWS resources
module "aws_network" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  source = "./modules/aws"

  project_name         = var.project_name
  environment          = var.environment
  region               = local.selected_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  jumphost_instance_type = local.instance_type_map.aws.jumphost
  private_vm_instance_type = local.instance_type_map.aws.private_vm
  jumphost_ssh_key        = var.jumphost_ssh_key

  enable_jumphost   = var.enable_jumphost
  enable_private_vm = var.enable_private_vm

  tags = local.common_tags
}

# Deploy Azure resources
module "azure_network" {
  count  = var.cloud_provider == "azure" ? 1 : 0
  source = "./modules/azure"

  project_name         = var.project_name
  environment          = var.environment
  location             = local.selected_region
  vnet_cidr            = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  jumphost_vm_size   = local.instance_type_map.azure.jumphost
  private_vm_size    = local.instance_type_map.azure.private_vm
  jumphost_ssh_key   = var.jumphost_ssh_key

  enable_jumphost   = var.enable_jumphost
  enable_private_vm = var.enable_private_vm

  tags = local.common_tags
}

# Deploy GCP resources
module "gcp_network" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  source = "./modules/gcp"

  project_name         = var.project_name
  environment          = var.environment
  region               = local.selected_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  jumphost_machine_type = local.instance_type_map.gcp.jumphost
  private_vm_machine_type = local.instance_type_map.gcp.private_vm
  jumphost_ssh_key      = var.jumphost_ssh_key

  enable_jumphost   = var.enable_jumphost
  enable_private_vm = var.enable_private_vm

  tags = local.common_tags
}

