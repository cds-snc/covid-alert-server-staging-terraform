# aggregator_metrics_put

data "aws_iam_policy_document" "aggregate_metrics_put" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem"
    ]

    resources = [
      aws_dynamodb_table.aggregate_metrics.arn
    ]
  }

}

resource "aws_iam_policy" "aggregate_metrics_put" {
  name   = "CovidAlertAggregateMetricsPutItem"
  path   = "/"
  policy = data.aws_iam_policy_document.aggregate_metrics_put.json
}

# raw_metrics_put

data "aws_iam_policy_document" "raw_metrics_put" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem"
    ]

    resources = [
      aws_dynamodb_table.raw_metrics.arn
    ]
  }

}

resource "aws_iam_policy" "raw_metrics_put" {
  name   = "CovidAlertRawMetricsPutItem"
  path   = "/"
  policy = data.aws_iam_policy_document.raw_metrics_put.json
}

# assume_role

data "aws_iam_policy_document" "service_principal" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# write_logs

data "aws_iam_policy_document" "write_logs" {
  statement {

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "write_logs" {
  name   = "CovidAlertLogWriter"
  path   = "/"
  policy = data.aws_iam_policy_document.write_logs.json
}

# vpc_networking

data "aws_iam_policy_document" "vpc_networking" {
  statement { 

    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]

    resources = [
      "*"
    ]

  }
}

resource "aws_iam_policy" "vpc_networking" {
  name   = "CovidAlertVplNetworking"
  path   = "/"
  policy = data.aws_iam_policy_document.vpc_networking.json
}

# dynamodb_streams

data "aws_iam_policy_document" "raw_metrics_stream_processor" {
  statement { 

    effect = "Allow"
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams"
    ]
    resources = [
      aws_dynamodb_table.raw_metrics.arn
    ]

  }

}

resource "aws_iam_policy" "raw_metrics_stream_processor" {
  name   = "CovidAlertRawMetricsStreamProcessor"
  path   = "/"
  policy = data.aws_iam_policy_document.raw_metrics_stream_processor.json
}