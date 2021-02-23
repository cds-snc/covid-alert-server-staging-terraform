data "archive_file" "lambda_backoff_retry" {
  type        = "zip"
  source_file = "lambda/backoff_retry.js"
  output_path = "/tmp/lambda_backoff_retry.js.zip"
}

resource "aws_lambda_function" "backoff_retry" {
  function_name = "backoff_retry"
  filename      = "/tmp/lambda_backoff_retry.js.zip"

  source_code_hash = data.archive_file.lambda_backoff_retry.output_base64sha256

  handler = "backoff_retry.handler"
  runtime = var.lambda_function_runtime
  role    = aws_iam_role.backoff.arn

  vpc_config {
    security_group_ids = [aws_security_group.backoff_retry_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      DEAD_LETTER_QUEUE_URL = aws_sqs_queue.aggregation_lambda_dead_letter.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "dead_letters" {
  event_source_arn = aws_sqs_queue.aggregation_lambda_dead_letter.arn
  function_name    = aws_lambda_function.backoff_retry.arn
}

resource "aws_security_group" "backoff_retry_sg" {
  name        = "backoff_retry_sg"
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

resource "aws_security_group_rule" "privatelink_metrics_backoff_ingress" {
  description              = "Security group rule for metricsRetrieval ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.privatelink_sg
  source_security_group_id = aws_security_group.backoff_retry_sg.id
}

resource "aws_cloudwatch_log_group" "backoff_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.backoff_retry.function_name}"
  retention_in_days = 14
}
