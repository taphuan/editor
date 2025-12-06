output "bucket_id" {
  description = "Storage bucket ID"
  value       = google_storage_bucket.storage.id
}

output "bucket_name" {
  description = "Storage bucket name"
  value       = google_storage_bucket.storage.name
}

output "bucket_url" {
  description = "Storage bucket URL"
  value       = google_storage_bucket.storage.url
}

