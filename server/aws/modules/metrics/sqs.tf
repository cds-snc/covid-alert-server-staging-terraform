data "aws_sqs_queue" "aggregation_lambda_dead_letter" {
  name = "aggregation-lambda-dead-letter-queue"
}

data "aws_kms_key" "metrics_key" {
  key_id = "arn:aws:kms:ca-central-1:005133826942:key/47379609-95bb-4691-a3d0-7e70bb8d8684"
}
