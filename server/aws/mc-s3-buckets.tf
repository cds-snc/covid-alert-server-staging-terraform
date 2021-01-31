##
#  Mectrics Collection S3 Bucket and Logging
##

resource "aws_s3_bucket" "raw_metrics_bucket" {
  bucket  = "${var.s3_raw_metrics_bucket_name}-${data.aws_caller_identity.current.account_id}"
  acl     = "private"

  depends_on = [aws_s3_bucket.raw_metrics_bucket_logs]

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id   = aws_kms_key.mykey.arn
        sse_algorithm       = "aws:kms"
      }
    }
  }

  tags = {
    Name        = var.s3_raw_metrics_bucket_name
    Environment = var.environment
    Resource    = "S3",
    Project     = var.project,
    (var.billing_tag_key) = var.billing_tag_value
    Deployment  = "Terraform"
  }

  logging {
    target_bucket = "${var.s3_raw_metrics_bucket_logging_name}-${data.aws_caller_identity.current.account_id}"
    target_prefix = "${var.service_name}/logs${data.aws_caller_identity.current.account_id}"
  }

}

resource "aws_s3_bucket_public_access_block" "raw_metrics_bucket" {
  bucket                  = aws_s3_bucket.raw_metrics_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "raw_metrics_bucket_logs" {
  bucket = "${var.s3_raw_metrics_bucket_logging_name}-${data.aws_caller_identity.current.account_id}"
  acl    = "log-delivery-write"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id   = aws_kms_key.mykey.arn
        sse_algorithm       = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }

  tags = {
    Name        = var.s3_raw_metrics_bucket_logging_name
    Environment = var.environment
    Resource    = "S3",
    Project     = var.project,
    (var.billing_tag_key) = var.billing_tag_value
    Deployment  = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "raw_metrics_bucket_logs" {
  bucket = aws_s3_bucket.raw_metrics_bucket_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
