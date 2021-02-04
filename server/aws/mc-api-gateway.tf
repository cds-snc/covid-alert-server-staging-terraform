##
#  Mectrics Collection API Gateway
##

resource "aws_api_gateway_rest_api" "metrics" {
  depends_on  = [aws_lambda_function.metrics]
  name        = var.service_name
  description = var.api-description
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name                  = var.service_name
    Environment           = var.environment
    (var.billing_tag_key) = var.billing_tag_value
    Resource              = "API-Gateway"
    Project               = var.project
    Deployment            = "Terraform"
  }
}

resource "aws_api_gateway_domain_name" "metrics" {
  regional_certificate_arn = aws_acm_certificate.covidshield.arn
  domain_name              = "metrics.${aws_route53_zone.covidshield.name}"
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

output "base_url" {
  value = aws_api_gateway_deployment.metrics.invoke_url
}

resource "aws_api_gateway_resource" "create_resource" {
  rest_api_id = aws_api_gateway_rest_api.metrics.id
  parent_id   = aws_api_gateway_rest_api.metrics.root_resource_id
  path_part   = var.service_name
}

resource "aws_api_gateway_method" "create_method" {
  rest_api_id      = aws_api_gateway_rest_api.metrics.id
  resource_id      = aws_api_gateway_resource.create_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.metrics.id
  resource_id = aws_api_gateway_resource.create_resource.id
  http_method = aws_api_gateway_method.create_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "metrics" {
  rest_api_id             = aws_api_gateway_rest_api.metrics.id
  resource_id             = aws_api_gateway_method.create_method.resource_id
  http_method             = aws_api_gateway_method.create_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.metrics.invoke_arn
}

resource "aws_api_gateway_integration_response" "metrics_response" {
  depends_on = [
    aws_api_gateway_integration.metrics
  ]
  http_method = aws_api_gateway_method.create_method.http_method
  resource_id = aws_api_gateway_resource.create_resource.id
  rest_api_id = aws_api_gateway_rest_api.metrics.id
  status_code = aws_api_gateway_method_response.response_200.status_code
}

resource "aws_api_gateway_deployment" "metrics" {
  depends_on  = [aws_api_gateway_integration.metrics]
  rest_api_id = aws_api_gateway_rest_api.metrics.id
}

resource "aws_cloudwatch_log_group" "api_log_group" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.metrics.id}/${var.environment}"
  retention_in_days = 7
  # ... potentially other configuration ...
}

resource "aws_api_gateway_stage" "metrics" {
  depends_on           = [aws_cloudwatch_log_group.api_log_group]
  deployment_id        = aws_api_gateway_deployment.metrics.id
  rest_api_id          = aws_api_gateway_rest_api.metrics.id
  stage_name           = var.environment
  xray_tracing_enabled = true
}

resource "aws_api_gateway_usage_plan" "metrics_usage_plan" {
  name = "${var.apiKeyName}_usage_plan"
  depends_on = [
    aws_api_gateway_stage.metrics
  ]
  api_stages {
    api_id = aws_api_gateway_rest_api.metrics.id
    stage  = var.environment
  }
}

resource "aws_api_gateway_api_key" "metrics_api_key" {
  name = var.apiKeyName
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.metrics_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.metrics_usage_plan.id
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.api_gatway_cloudwatch_role.arn
}

resource "aws_iam_role" "api_gatway_cloudwatch_role" {
  name = "${var.service_name}api_gateway_cloudwatch_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.api_gatway_cloudwatch_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_api_gateway_method_settings" "method_settings" {
  rest_api_id = aws_api_gateway_rest_api.metrics.id
  stage_name  = aws_api_gateway_stage.metrics.stage_name
  method_path = "${aws_api_gateway_resource.create_resource.path_part}/${aws_api_gateway_method.create_method.http_method}"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = var.api_gateway_burst
    throttling_rate_limit  = var.api_gateway_rate
  }
}
