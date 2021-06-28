# raw_metrics_put

data "aws_iam_policy_document" "raw_metrics_put" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem"
    ]

    resources = [
      data.aws_dynamodb_table.raw_metrics.arn
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
