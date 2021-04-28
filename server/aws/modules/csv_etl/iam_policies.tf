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
  name   = "${var.name}PullCreateCSVImage"
  path   = "/"
  policy = data.aws_iam_policy_document.pull_create_csv_image.json
}

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
  name   = "${var.name}WriteS3CSVBuckets"
  path   = "/"
  policy = data.aws_iam_policy_document.write_s3_metrics_csv_buckets.json
}

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
  name   = "${var.name}LogWriter"
  path   = "/"
  policy = data.aws_iam_policy_document.write_logs.json
}

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
  name   = "${var.name}VpcNetworking"
  path   = "/"
  policy = data.aws_iam_policy_document.vpc_networking.json
}


data "aws_iam_policy_document" "aggregate_metrics_read" {
  statement {

    effect = "Allow"
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dyanmodb:ListShards"
    ]
    resources = [
      var.aggregate_metrics_arn
    ]

  }

}

resource "aws_iam_policy" "aggregate_metrics_read" {
  name   = "${var.name}AggregateMetricsRead"
  path   = "/"
  policy = data.aws_iam_policy_document.aggregate_metrics_read.json
}
