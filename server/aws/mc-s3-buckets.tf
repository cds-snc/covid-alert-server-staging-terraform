resource "aws_s3_bucket" "raw_metrics_bucket" {
  bucket  = var.s3_raw_metrics_bucket_name
  acl     = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id   = aws_kms_key.mykey.arn
        sse_algorithm       = "aws:kms"
      }
    }
  }

  tags = {
    Name        = var.service_name
    Environment = var.environment
    Resource    = "S3",
    Project     = var.project,
    (var.billing_tag_key) = var.billing_tag_value
    Deployment  = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "raw_metrics_bucket" {
  bucket                  = aws_s3_bucket.raw_metrics_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

