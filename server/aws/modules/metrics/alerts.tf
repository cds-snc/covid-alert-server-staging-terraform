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
    TableName = aws_dynamodb_table.raw_metrics.name
  }
}

resource "aws_cloudwatch_metric_alarm" "aggregate_metrics_dynamodb_wcu" {
  count               = var.feature_count_alarms ? 1 : 0
  alarm_name          = "aggregate-metrics-dynamodb-wcu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsumedWriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.aggregate_metrics_dynamodb_wcu_max
  alarm_description   = "This metric monitors maximum write capacity units for the aggregate_metrics table"

  alarm_actions = [var.critical_topic]
  dimensions = {
    TableName = aws_dynamodb_table.aggregate_metrics.name
  }
}

###
# AWS Lambda
###

resource "aws_cloudwatch_metric_alarm" "aggregate_metrics_average_duration" {
  alarm_name          = "aggregate-metrics-average-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Average"
  threshold           = var.aggregate_metrics_max_avg_duration
  alarm_description   = "This metric monitors average duration for the aggregate_metrics lambda"

  alarm_actions = [var.critical_topic]
  dimensions = {
    FunctionName = aws_lambda_function.aggregate_metrics.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "backoff_retry_average_duration" {
  alarm_name          = "save-metrics-average-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "60"
  extended_statistic  = "p99"
  threshold           = var.backoff_retry_max_avg_duration
  alarm_description   = "This metric monitors average duration for the backoff_retry lambda"

  alarm_actions = [var.critical_topic]
  dimensions = {
    FunctionName = aws_lambda_function.backoff_retry.function_name
  }
}