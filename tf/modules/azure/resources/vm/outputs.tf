output "vm_id" {
  description = "VM ID"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "private_ip" {
  description = "Private IP address"
  value       = azurerm_network_interface.vm.ip_configuration[0].private_ip_address
}

output "public_ip" {
  description = "Public IP address (if applicable)"
  value       = var.public_ip_id != null ? azurerm_network_interface.vm.ip_configuration[0].public_ip_address : null
}

output "network_interface_id" {
  description = "Network interface ID"
  value       = azurerm_network_interface.vm.id
}

