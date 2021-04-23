# aggregator_metrics_put

data "aws_iam_policy_document" "aggregate_metrics_update" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:UpdateItem"
    ]

    resources = [
      aws_dynamodb_table.aggregate_metrics.arn
    ]
  }

}


resource "aws_iam_policy" "aggregate_metrics_update" {
  name   = "CovidAlertAggregateMetricsUpdateItem"
  path   = "/"
  policy = data.aws_iam_policy_document.aggregate_metrics_update.json
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
      "dynamodb:ListStreams",
      "dyanmodb:ListShards"
    ]
    resources = [
      aws_dynamodb_table.raw_metrics.stream_arn
    ]

  }

}

resource "aws_iam_policy" "raw_metrics_stream_processor" {
  name   = "CovidAlertRawMetricsStreamProcessor"
  path   = "/"
  policy = data.aws_iam_policy_document.raw_metrics_stream_processor.json
}

data "aws_iam_policy_document" "aggregate_metrics_stream_processor" {
  statement {

    effect = "Allow"
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
      "dyanmodb:ListShards"
    ]
    resources = [
      aws_dynamodb_table.aggregate_metrics.arn
    ]

  }

}

resource "aws_iam_policy" "aggregate_metrics_stream_processor" {
  name   = "CovidAlertAggregateMetricsStreamProcessor"
  path   = "/"
  policy = data.aws_iam_policy_document.aggregate_metrics_stream_processor.json
}

# Write an encrypt to SQS deadletter queue

data "aws_iam_policy_document" "write_and_encrypt_deadletter_queue" {
  statement {

    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "sqs:SendMessage"

    ]
    resources = [
      aws_kms_key.metrics_key.arn,
      aws_sqs_queue.aggregation_lambda_dead_letter.arn
    ]

  }

}

resource "aws_iam_policy" "write_and_encrypt_deadletter_queue" {
  name   = "CovidAlertWriteAndEncryptDeadletterQueue"
  path   = "/"
  policy = data.aws_iam_policy_document.write_and_encrypt_deadletter_queue.json
}

# Read write and encrypt to deadletter queue
data "aws_iam_policy_document" "read_write_and_encrypt_deadletter_queue" {
  statement {

    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"

    ]
    resources = [
      aws_kms_key.metrics_key.arn,
      aws_sqs_queue.aggregation_lambda_dead_letter.arn
    ]

  }

}

resource "aws_iam_policy" "read_write_and_encrypt_deadletter_queue" {
  name   = "CovidAlertReadWriteAndEncryptDeadletterQueue"
  path   = "/"
  policy = data.aws_iam_policy_document.read_write_and_encrypt_deadletter_queue.json
}

# Write to S3
data "aws_iam_policy_document" "write_s3_metrics_csv_buckets" {
  statement {

    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      aws_s3_bucket.unmasked_metrics.arn,
      aws_s3_bucket.masked_metrics.arn
    ]

  }

}

resource "aws_iam_policy" "write_s3_metrics_csv_buckets" {
  name   = "CovidAlertWriteS3CSVBuckets"
  path   = "/"
  policy = data.aws_iam_policy_document.write_s3_metrics_csv_buckets.json
}


# read from private ECR repository 

data "aws_iam_policy_document" "pull_create_csv_image" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForlayer",
      "ecr:BatchGetImage"
    ]
    resources = [
      aws_ecr_repository.create_csv.arn
    ]
  }
}

resource "aws_iam_policy" "pull_create_csv_image_policy" {
  name   = "PullCreateCSVImage"
  path   = "/"
  policy = data.aws_iam_policy_document.pull_create_csv_image.json
}