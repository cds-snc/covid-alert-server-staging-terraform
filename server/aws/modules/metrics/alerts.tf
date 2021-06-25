###
# AWS DynamoDB
###

resource "aws_cloudwatch_metric_alarm" "raw_metrics_dynamodb_wcu" {
  count               = var.feature_count_alarms ? 1 : 0
  alarm_name          = "raw-metrics-dynamodb-wcu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.raw_metrics_dynamodb_wcu_max
  alarm_description   = "This metric monitors maximum write capacity units for the raw_metrics table"

  alarm_actions = [var.critical_topic]
  dimensions = {
    TableName = data.aws_dynamodb_table.raw_metrics.name
  }
}