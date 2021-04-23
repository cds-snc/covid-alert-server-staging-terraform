resource "aws_iam_role" "metrics_csv" {
  name               = "metrics_csv_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.service_principal.json
}

resource "aws_iam_role_policy_attachment" "metrics_csv_log_writer" {
  role       = aws_iam_role.metrics_csv.name
  policy_arn = aws_iam_policy.write_logs.arn
}

resource "aws_iam_role_policy_attachment" "metrics_csv_vpc_networking" {
  role       = aws_iam_role.metrics_csv.name
  policy_arn = aws_iam_policy.vpc_networking.arn
}

resource "aws_iam_role_policy_attachment" "metrics_csv_aggregate_streams" {
  role       = aws_iam_role.metrics_csv.name
  policy_arn = aws_iam_policy.aggregate_metrics_stream_processor.arn
}

resource "aws_iam_role_policy_attachment" "metrics_csv_s3_write" {
  role       = aws_iam_role.metrics_csv.name
  policy_arn = aws_iam_policy.write_s3_metrics_csv_buckets.arn
}

resource "aws_iam_role_policy_attachment" "metrics_csv_pull_create_csv_image" {
  role       = aws_iam_role.metrics_csv.name
  policy_arn = aws_iam_policy.pull_create_csv_image_policy.arn
}