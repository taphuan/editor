output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = azurerm_subnet.private[*].id
}

output "jumphost_public_ip" {
  description = "Public IP of jumphost"
  value       = var.enable_jumphost ? azurerm_public_ip.jumphost[0].ip_address : null
}

output "jumphost_private_ip" {
  description = "Private IP of jumphost"
  value       = var.enable_jumphost ? azurerm_network_interface.jumphost[0].ip_configuration[0].private_ip_address : null
}

output "private_vm_private_ip" {
  description = "Private IP of private VM"
  value       = var.enable_private_vm ? azurerm_network_interface.private_vm[0].ip_configuration[0].private_ip_address : null
}

output "nsg_ids" {
  description = "Network Security Group IDs"
  value = {
    public  = azurerm_network_security_group.public.id
    private = azurerm_network_security_group.private.id
  }
}

output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.main.name
}

output "jumphost_ssh_private_key" {
  description = "SSH private key for jumphost (if generated)"
  value       = var.jumphost_ssh_key == "" && length(tls_private_key.jumphost_key) > 0 ? tls_private_key.jumphost_key[0].private_key_pem : null
  sensitive   = true
}

