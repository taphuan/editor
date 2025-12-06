# Common outputs that work across all cloud providers
output "cloud_provider" {
  description = "The cloud provider being used"
  value       = var.cloud_provider
}

output "region" {
  description = "The region where resources are deployed"
  value       = local.selected_region
}

output "vpc_id" {
  description = "VPC/VNet ID"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].vpc_id : null
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].vnet_id : null
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].vpc_id : null
  ) : null
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].public_subnet_ids : []
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].public_subnet_ids : []
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].public_subnet_ids : []
  ) : []
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].private_subnet_ids : []
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].private_subnet_ids : []
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].private_subnet_ids : []
  ) : []
}

output "jumphost_public_ip" {
  description = "Public IP address of the jumphost"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].jumphost_public_ip : null
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].jumphost_public_ip : null
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].jumphost_public_ip : null
  ) : null
}

output "jumphost_private_ip" {
  description = "Private IP address of the jumphost"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].jumphost_private_ip : null
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].jumphost_private_ip : null
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].jumphost_private_ip : null
  ) : null
}

output "private_vm_private_ip" {
  description = "Private IP address of the private VM"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].private_vm_private_ip : null
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].private_vm_private_ip : null
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].private_vm_private_ip : null
  ) : null
}

output "security_group_ids" {
  description = "Security group/NSG IDs"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 ? module.aws_network[0].security_group_ids : {}
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 ? module.azure_network[0].nsg_ids : {}
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 ? module.gcp_network[0].firewall_rule_names : {}
  ) : {}
}

output "ssh_command" {
  description = "SSH command to connect to jumphost"
  value = var.cloud_provider == "aws" ? (
    length(module.aws_network) > 0 && module.aws_network[0].jumphost_public_ip != null ? 
    "ssh -i <your-key.pem> ec2-user@${module.aws_network[0].jumphost_public_ip}" : null
  ) : var.cloud_provider == "azure" ? (
    length(module.azure_network) > 0 && module.azure_network[0].jumphost_public_ip != null ? 
    "ssh azureuser@${module.azure_network[0].jumphost_public_ip}" : null
  ) : var.cloud_provider == "gcp" ? (
    length(module.gcp_network) > 0 && module.gcp_network[0].jumphost_public_ip != null ? 
    "ssh <username>@${module.gcp_network[0].jumphost_public_ip}" : null
  ) : null
}

