output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.database.id
}

output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.database.endpoint
}

output "address" {
  description = "RDS instance address"
  value       = aws_db_instance.database.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.database.port
}

