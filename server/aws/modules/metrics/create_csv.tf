
locals {
  image_uri = "${aws_ecr_repository.create_csv.repository_url}:${var.create_csv_tag}"
}
resource "aws_lambda_function" "unmasked_metrics" {
  function_name = "unmasked_metrics"

  package_type = "Image"
  image_uri    = local.image_uri

  role = aws_iam_role.backoff.arn

  vpc_config {
    security_group_ids = [aws_security_group.metrics_csv_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      MASK_DATA   = false
      BUCKET_NAME = aws_s3_bucket.unmasked_metrics.id
    }
  }
}
resource "aws_lambda_function" "masked_metrics" {
  function_name = "masked_metrics"

  package_type = "Image"
  image_uri    = local.image_uri

  role = aws_iam_role.backoff.arn

  vpc_config {
    security_group_ids = [aws_security_group.metrics_csv_sg.id]
    subnet_ids         = var.subnet_ids
  }

  environment {
    variables = {
      MASK_DATA   = true
      BUCKET_NAME = aws_s3_bucket.masked_metrics.id
    }
  }
}

resource "aws_security_group" "metrics_csv_sg" {
  name        = "metrics_csv_sg"
  description = "Allow TLS outbound traffic to S3"
  vpc_id      = var.vpc_id
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [var.s3_endpoint]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.privatelink_sg]
  }
}

resource "aws_security_group_rule" "privatelink_metrics_csv" {
  description              = "Security group rule for metrics CSV export"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.privatelink_sg
  source_security_group_id = aws_security_group.metrics_csv_sg.id
}


resource "aws_cloudwatch_log_group" "masked_metrics" {
  name              = "/aws/lambda/${aws_lambda_function.masked_metrics.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "unmasked_metrics" {
  name              = "/aws/lambda/${aws_lambda_function.unmasked_metrics.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "twice-a-day" {
  name                = "twice-a-day"
  description         = "Fires twice a day"
  schedule_expression = "cron(0 6,18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "tigger-unmasked_metrics" {
  rule      = aws_cloudwatch_event_rule.twice-a-day.name
  target_id = "unmasked_metrics"
  arn       = aws_lambda_function.unmasked_metrics.arn
}

resource "aws_cloudwatch_event_target" "tigger-masked_metrics" {
  rule      = aws_cloudwatch_event_rule.twice-a-day.name
  target_id = "masked_metrics"
  arn       = aws_lambda_function.masked_metrics.arn
}

resource "aws_lambda_permission" "allow-cloudwatch-to-call-unmasked_metrics" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unmasked_metrics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.twice-a-day.arn
}

resource "aws_lambda_permission" "allow-cloudwatch-to-call-masked_metrics" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.masked_metrics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.twice-a-day.arn
}