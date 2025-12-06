output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.storage.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.storage.arn
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.storage.bucket_domain_name
}

