output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = google_compute_subnetwork.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = google_compute_subnetwork.private[*].id
}

output "jumphost_public_ip" {
  description = "Public IP of jumphost"
  value       = var.enable_jumphost ? google_compute_instance.jumphost[0].network_interface[0].access_config[0].nat_ip : null
}

output "jumphost_private_ip" {
  description = "Private IP of jumphost"
  value       = var.enable_jumphost ? google_compute_instance.jumphost[0].network_interface[0].network_ip : null
}

output "private_vm_private_ip" {
  description = "Private IP of private VM"
  value       = var.enable_private_vm ? google_compute_instance.private_vm[0].network_interface[0].network_ip : null
}

output "firewall_rule_names" {
  description = "Firewall rule names"
  value = {
    public_ssh              = google_compute_firewall.public_ssh.name
    public_egress           = google_compute_firewall.public_egress.name
    private_ssh_from_public = google_compute_firewall.private_ssh_from_public.name
    vpc_internal            = google_compute_firewall.vpc_internal.name
    private_egress          = google_compute_firewall.private_egress.name
  }
}

output "jumphost_ssh_private_key" {
  description = "SSH private key for jumphost (if generated)"
  value       = var.jumphost_ssh_key == "" && var.enable_jumphost ? tls_private_key.jumphost_key[0].private_key_pem : null
  sensitive   = true
}

