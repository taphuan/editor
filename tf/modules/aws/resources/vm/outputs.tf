output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.vm.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.vm.private_ip
}

output "public_ip" {
  description = "Public IP address (if applicable)"
  value       = aws_instance.vm.public_ip
}

