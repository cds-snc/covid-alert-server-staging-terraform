# Raw Metrics
resource "aws_iam_role_policy_attachment" "raw_metrics_put" {
  role       = var.role_name
  policy_arn = aws_iam_policy.raw_metrics_put.arn
}
