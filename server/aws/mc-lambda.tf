terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "metrics" {
  function_name = var.service_name
  description = var.lambda-description
  s3_bucket = var.lambda_code
  s3_key = var.lambda-function-code
  handler = var.lambda-function-handler
  runtime = var.lambda-function-runtime
  role = aws_iam_role.role.arn
  environment {
    variables = {
      dataBucket = var.s3_raw_metrics_bucket_name
      dataKey = aws_kms_key.mykey.id
      fileLoca = "metrics"
    }
  }

  vpc_config {
    security_group_ids = []
    subnet_ids = []
  }
  tags = {
    Name = var.service_name
    Resource = "Lambda"
    Environment = var.environment
    (var.billing_tag_key) = var.billing_tag_value
    Project = var.project
    Deployment = "Terraform"
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "role" {
  name = "${var.service_name}.role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "metrics" {
  name = "/aws/lambda/${var.service_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name = var.service_name
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "kms:Encrypt"
      ],
      "Resource": [

        "${aws_kms_key.mykey.arn}",
        "arn:aws:s3:::${var.s3_raw_metrics_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metrics.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.metrics.execution_arn}/*/*"
}

