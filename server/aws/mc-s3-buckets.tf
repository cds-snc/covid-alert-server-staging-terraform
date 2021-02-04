##
#  Mectrics Collection S3 Bucket and Logging
##

resource "aws_s3_bucket" "raw_metrics_bucket" {
  bucket = "${var.s3_raw_metrics_bucket_name}-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "cbs-satellite-account-bucket${data.aws_caller_identity.current.account_id}"
    target_prefix = "${data.aws_caller_identity.current.account_id}/s3_access_logs/${var.s3_raw_metrics_bucket_name}-${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_s3_bucket_public_access_block" "raw_metrics_bucket" {
  bucket                  = aws_s3_bucket.raw_metrics_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


