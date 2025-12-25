terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name = "${var.s3_bucket_name_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = local.bucket_name
  force_destroy = false

  tags = {
    Name    = local.bucket_name
    Project = "cloudtrail-monitoring"
  }
}

# Recommended bucket settings
resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy for CloudTrail delivery
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AWSCloudTrailWrite"
        Effect   = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cloudtrail.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid      = "AWSCloudTrailAclCheck"
        Effect   = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.cloudtrail.bucket}"
      }
    ]
  })
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = var.log_group_name
  retention_in_days = 30

  tags = {
    Name    = var.log_group_name
    Project = "cloudtrail-monitoring"
  }
}

# IAM role for CloudTrail to send logs to CloudWatch
resource "aws_iam_role" "cloudtrail_to_cw" {
  name               = "CloudTrail_CloudWatchRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "cloudtrail-monitoring"
  }
}

# Inline policy granting CloudTrail permissions to write to the log group
resource "aws_iam_role_policy" "cloudtrail_to_cw" {
  name = "CloudTrail-CloudWatch-Policy"
  role = aws_iam_role.cloudtrail_to_cw.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:*"
      }
    ]
  })
}

# CloudTrail trail (multi-region)
resource "aws_cloudtrail" "realtime" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.cloudtrail.arn
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cw.arn

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_to_cw
  ]

  tags = {
    Project = "cloudtrail-monitoring"
  }
}
