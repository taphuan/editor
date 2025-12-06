output "secret_id" {
  description = "Secret Manager secret ID"
  value       = google_secret_manager_secret.vault.secret_id
}

output "secret_name" {
  description = "Secret Manager secret name"
  value       = google_secret_manager_secret.vault.name
}

output "secret_path" {
  description = "Full path to the secret"
  value       = google_secret_manager_secret.vault.id
}

