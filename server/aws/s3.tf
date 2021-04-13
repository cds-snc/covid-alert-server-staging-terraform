###
# AWS S3 bucket - Exposure config
###
resource "aws_s3_bucket" "exposure_config" {

  # Versioning on this resource is handled through git
  # tfsec:ignore:AWS077

  bucket = "covid-shield-exposure-config-${var.environment}"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "cbs-satellite-account-bucket${data.aws_caller_identity.current.account_id}"
    target_prefix = "${data.aws_caller_identity.current.account_id}/s3_access_logs/covid-shield-exposure-config-${var.environment}/"
  }

}

resource "aws_s3_bucket_policy" "exposure_config" {
  bucket = aws_s3_bucket.exposure_config.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyCloudfrontReadAccess",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.exposure_config.arn}/*"
    }
  ]
}
POLICY
}

###
# AWS S3 bucket - WAF log target
###

resource "aws_s3_bucket" "firehose_waf_logs" {

  # Don't need to version these they should expire and are ephemeral
  # tfsec:ignore:AWS077

  bucket = "covid-shield-${var.environment}-waf-logs"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }

  logging {
    target_bucket = "cbs-satellite-account-bucket${data.aws_caller_identity.current.account_id}"
    target_prefix = "${data.aws_caller_identity.current.account_id}/s3_access_logs/covid-shield-${var.environment}-waf-logs/"
  }
}

###
# AWS S3 bucket - cloudfront log target
###
resource "aws_s3_bucket" "cloudfront_logs" {

  # Don't need to version these they should expire and are ephemeral
  # tfsec:ignore:AWS077

  bucket = "covid-shield-${var.environment}-cloudfront-logs"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }

  # awslogsdelivery account needs full control for cloudfront logging
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
  grant {
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  logging {
    target_bucket = "cbs-satellite-account-bucket${data.aws_caller_identity.current.account_id}"
    target_prefix = "${data.aws_caller_identity.current.account_id}/s3_access_logs/covid-shield-${var.environment}-cloudfront-logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "firehose_waf_logs" {
  bucket = aws_s3_bucket.firehose_waf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}