resource "aws_dynamodb_table" "raw_metrics" {

  name         = "raw_metrics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"

  ttl {
    attribute_name = "expdate"
    enabled        = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "uuid"
    type = "S"
  }

}


resource "aws_dynamodb_table" "aggregate_metrics" {

  name         = "aggregate_metrics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

}