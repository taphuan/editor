output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.vault.arn
}

output "secret_id" {
  description = "Secrets Manager secret ID"
  value       = aws_secretsmanager_secret.vault.id
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.vault.name
}

