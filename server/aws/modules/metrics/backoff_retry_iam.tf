resource "aws_iam_role" "backoff" {
  name               = "backoff_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.service_principal.json
}

resource "aws_iam_role_policy_attachment" "backoff_update" {
  role       = aws_iam_role.backoff.name
  policy_arn = aws_iam_policy.aggregate_metrics_update.arn
}

resource "aws_iam_role_policy_attachment" "backoff_log_writer" {
  role       = aws_iam_role.backoff.name
  policy_arn = aws_iam_policy.write_logs.arn
}

resource "aws_iam_role_policy_attachment" "backoff_vpc_networking" {
  role       = aws_iam_role.backoff.name
  policy_arn = aws_iam_policy.vpc_networking.arn
}

resource "aws_iam_role_policy_attachment" "backoff_raw_metrics_stream_processor" {
  role       = aws_iam_role.backoff.name
  policy_arn = aws_iam_policy.raw_metrics_stream_processor.arn
}

resource "aws_iam_role_policy_attachment" "backoff_read_write_and_encrypt_deadletter_queue" {
  role       = aws_iam_role.backoff.name
  policy_arn = aws_iam_policy.read_write_and_encrypt_deadletter_queue.arn
}
