resource "aws_iam_role" "aggregator" {
  name               = "aggregate_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.service_principal.json
}

resource "aws_iam_role_policy_attachment" "aggregator_update" {
  role       = aws_iam_role.aggregator.name
  policy_arn = aws_iam_policy.aggregate_metrics_update.arn
}

resource "aws_iam_role_policy_attachment" "aggregator_log_writer" {
  role       = aws_iam_role.aggregator.name
  policy_arn = aws_iam_policy.write_logs.arn
}

resource "aws_iam_role_policy_attachment" "aggregator_vpc_networking" {
  role       = aws_iam_role.aggregator.name
  policy_arn = aws_iam_policy.vpc_networking.arn
}

resource "aws_iam_role_policy_attachment" "aggregator_raw_metrics_stream_processor" {
  role       = aws_iam_role.aggregator.name
  policy_arn = aws_iam_policy.raw_metrics_stream_processor.arn
}

resource "aws_iam_role_policy_attachment" "aggregator_write_and_encrypt_deadletter_queue" {
  role       = aws_iam_role.aggregator.name
  policy_arn = aws_iam_policy.write_and_encrypt_deadletter_queue.arn
}
