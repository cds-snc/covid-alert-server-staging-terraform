output "raw_table_name" {
  value = data.aws_dynamodb_table.raw_metrics.name
}
output "dynamodb_prefix_list_id" {
  value = aws_vpc_endpoint.dynamodb.prefix_list_id
}