
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
  name = "CovidAlertRawMetricsPutItem"
  path = "/"
  policy = data.aws_iam_policy_document.raw_metrics_put
}

resource "aws_iam_role_policy_attachment" "raw_metrics_put" {
  role       = var.role_arn
  policy_arn = aws_iam_policy.raw_metrics_put.arn
}