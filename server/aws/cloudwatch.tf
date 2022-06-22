resource "aws_cloudwatch_log_group" "covidshield" {
  name              = var.cloudwatch_log_group_name
  kms_key_id        = aws_kms_key.cw.arn
  retention_in_days = 90

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_detected_cdn" {
  provider = aws.us-east-1

  alarm_name          = "DDoSDetectedCDN"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors for DDoS detected on retrieval CDN"

  alarm_actions = [aws_sns_topic.alert_warning_us_east.arn, aws_sns_topic.alert_critical_us_east.arn]

  dimensions = {
    ResourceArn = aws_cloudfront_distribution.key_retrieval_distribution.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_detected_route53" {
  provider = aws.us-east-1

  alarm_name          = "DDoSDetectedRoute53"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors for DDoS detected on route 53"

  alarm_actions = [aws_sns_topic.alert_warning_us_east.arn, aws_sns_topic.alert_critical_us_east.arn]

  dimensions = {
    ResourceArn = "arn:aws:route53:::hostedzone/${aws_route53_zone.covidshield.zone_id}"
  }
}

###
# AWS Route53 Metrics - Health check
###

resource "aws_cloudwatch_metric_alarm" "route53_retrieval_health_check_ca_json" {
  provider = aws.us-east-1

  alarm_name          = "Route53RetrievalHealthCheckCAJson"
  alarm_description   = "Check that the Retrieval server is correctly serving CA.json"
  comparison_operator = "LessThanThreshold"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "breaching"

  alarm_actions = [aws_sns_topic.alert_warning_us_east.arn, aws_sns_topic.alert_critical_us_east.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.covidshield_key_retrieval_healthcheck_ca_json.id
  }
}

resource "aws_cloudwatch_metric_alarm" "route53_retrieval_health_check_region_json" {
  provider = aws.us-east-1

  alarm_name          = "Route53RetrievalHealthCheckRegionJson"
  alarm_description   = "Check that the Retrieval server is correctly serving region.json"
  comparison_operator = "LessThanThreshold"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  evaluation_periods  = "2"
  statistic           = "Average"
  threshold           = "1"
  treat_missing_data  = "breaching"

  alarm_actions = [aws_sns_topic.alert_warning_us_east.arn, aws_sns_topic.alert_critical_us_east.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.covidshield_key_retrieval_healthcheck_region_json.id
  }
}
