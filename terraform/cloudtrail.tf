resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "iam-sentinel-cloudtrail-logs-${random_id.bucket.hex}"
  force_destroy = true
}

resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck20150319",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}"
      },
      {
        Sid       = "AWSCloudTrailWrite20150319",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "sentinel" {
  name                          = "iam-sentinel"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}