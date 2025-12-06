output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "jumphost_public_ip" {
  description = "Public IP of jumphost"
  value       = var.enable_jumphost ? aws_instance.jumphost[0].public_ip : null
}

output "jumphost_private_ip" {
  description = "Private IP of jumphost"
  value       = var.enable_jumphost ? aws_instance.jumphost[0].private_ip : null
}

output "private_vm_private_ip" {
  description = "Private IP of private VM"
  value       = var.enable_private_vm ? aws_instance.private_vm[0].private_ip : null
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    public  = aws_security_group.public.id
    private = aws_security_group.private.id
  }
}

output "jumphost_ssh_private_key" {
  description = "SSH private key for jumphost (if generated)"
  value       = var.jumphost_ssh_key == "" && var.enable_jumphost ? tls_private_key.jumphost_key[0].private_key_pem : null
  sensitive   = true
}

