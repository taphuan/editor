output "instance_id" {
  description = "Instance ID"
  value       = google_compute_instance.vm.id
}

output "private_ip" {
  description = "Private IP address"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "public_ip" {
  description = "Public IP address (if applicable)"
  value       = var.public_ip ? google_compute_instance.vm.network_interface[0].access_config[0].nat_ip : null
}

