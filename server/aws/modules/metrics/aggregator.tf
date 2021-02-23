
data "archive_file" "lambda_aggregate_metric" {
  type        = "zip"
  source_file = "lambda/aggregate_values.js"
  output_path = "/tmp/lambda_aggregate_values.js.zip"
}

resource "aws_lambda_function" "aggregate_metrics" {
  function_name = "aggregate_metrics"
  filename      = "/tmp/lambda_aggregate_values.js.zip"

  source_code_hash = data.archive_file.lambda_aggregate_metric.output_base64sha256

  handler = "aggregate_values.handler"
  runtime = var.lambda_function_runtime
  role    = aws_iam_role.aggregator.arn
  timeout = 60

  vpc_config {
    security_group_ids = [aws_security_group.aggregate_metrics_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      DEAD_LETTER_QUEUE_URL = aws_sqs_queue.aggregation_lambda_dead_letter.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "raw_metric_stream" {
  event_source_arn  = aws_dynamodb_table.raw_metrics.stream_arn
  function_name     = aws_lambda_function.aggregate_metrics.arn
  starting_position = "LATEST"
  batch_size        = 100
}

resource "aws_security_group" "aggregate_metrics_sg" {
  name        = "aggregate_metrics_sg"
  description = "Allow TLS outbound traffic to dynamodb"
  vpc_id      = var.vpc_id
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.dynamodb.prefix_list_id]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.privatelink_sg]
  }
}

resource "aws_security_group_rule" "privatelink_metrics_aggregator" {
  description              = "Security group rule for metricsRetrieval ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.privatelink_sg
  source_security_group_id = aws_security_group.aggregate_metrics_sg.id
}

resource "aws_cloudwatch_log_group" "metrics" {
  name              = "/aws/lambda/${aws_lambda_function.aggregate_metrics.function_name}"
  retention_in_days = 14
}
