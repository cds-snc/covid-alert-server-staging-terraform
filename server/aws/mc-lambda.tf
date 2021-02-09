##
#  Mectrics Collection Lambda
##

data "archive_file" "lambda_create_metric" {
  type        = "zip"
  source_file = "lambda/create_metric.js"
  output_path = "/tmp/lambda_create_metric.js.zip"
}


resource "aws_lambda_function" "metrics" {
  function_name = var.service_name
  description   = var.lambda-description
  filename      = "/tmp/lambda_create_metric.js.zip"

  source_code_hash = data.archive_file.lambda_create_metric.output_base64sha256

  handler = "create_metric.handler"
  runtime = var.lambda-function-runtime
  role    = aws_iam_role.role.arn

  environment {
    variables = {
      TABLE_NAME = module.in_app_metrics.raw_table_name
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.lambda_sg.id]
    subnet_ids         = aws_subnet.covidshield_private.*.id
  }

}

resource "aws_security_group" "lambda_sg" {
  name        = "allow_lambda_to_s3"
  description = "Allow TLS outbound traffic to S3"
  vpc_id      = aws_vpc.covidshield.id
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [module.in_app_metrics.dynamodb_prefix_list_id]
  }
}

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

resource "aws_cloudwatch_log_group" "metrics" {
  name              = "/aws/lambda/${var.service_name}"
  retention_in_days = 14
}

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
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_raw_metrics_bucket_name}-${data.aws_caller_identity.current.account_id}/*"
      ]
    },
    {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metrics.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.metrics.execution_arn}/*/POST/${var.service_name}"
}

