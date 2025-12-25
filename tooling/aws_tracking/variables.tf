variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "RealtimeTrail"
}

variable "log_group_name" {
  description = "CloudWatch Logs group for CloudTrail"
  type        = string
  default     = "/aws/cloudtrail/realtime"
}

variable "s3_bucket_name_prefix" {
  description = "Prefix for CloudTrail S3 bucket (suffix will include account and region)"
  type        = string
  default     = "cloudtrail-logs"
}
