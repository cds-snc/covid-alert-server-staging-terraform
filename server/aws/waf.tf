###
# AWS IPSet - list of IPs/CIDRs to allow
###
resource "aws_wafv2_ip_set" "new_key_claim" {
  name               = "new-key-claim"
  description        = "New Key Claim Allow IPs/CIDRs"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = toset(var.new_key_claim_allow_list)
}

###
# AWS WAF - Key Retrieval CDN Rules
###
resource "aws_wafv2_web_acl" "key_retrieval_cdn" {
  provider = aws.us-east-1

  name  = "key_retrieval_cdn"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "KeyRetrievalRateLimit"
    priority = 101

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KeyRetrievalRateLimit"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "key_retrieval_cdn"
    sampled_requests_enabled   = false
  }
}

###
# AWS WAF - Logging
###
resource "aws_wafv2_web_acl_logging_configuration" "firehose_waf_logs_retrieval_cdn" {
  provider = aws.us-east-1

  log_destination_configs = [aws_kinesis_firehose_delivery_stream.firehose_waf_logs_us_east.arn]
  resource_arn            = aws_wafv2_web_acl.key_retrieval_cdn.arn
}
