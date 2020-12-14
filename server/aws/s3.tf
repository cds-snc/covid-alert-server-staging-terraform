###
# AWS S3 bucket - WAF log target
###

resource "aws_s3_bucket" "exposure_config" {
  bucket = "covid-shield-exposure-config-${var.environment}"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "cbs-satellite-account-bucket005133826942"
    target_prefix = "005133826942/s3_access_logs/covid-shield-exposure-config-staging/" 
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

resource "aws_s3_bucket" "firehose_waf_logs" {
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
    target_bucket = "cbs-satellite-account-bucket005133826942"
    target_prefix = "005133826942/s3_access_logs/covid-shield-staging-waf-logs/"
  }
}

###
# AWS S3 bucket - cloudfront log target
###
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "covid-shield-${var.environment}-cloudfront-logs"
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
    target_bucket = "cbs-satellite-account-bucket005133826942"
    target_prefix = "005133826942/s3_access_logs/covid-shield-staging-cloudfront-logs/"
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