data "aws_dynamodb_table" "raw_metrics" {
  name = "raw_metrics"
}

data "aws_dynamodb_table" "aggregate_metrics" {
  name = "aggregate_metrics"
}