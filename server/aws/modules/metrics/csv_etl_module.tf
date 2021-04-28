

module "csv_etl" {
  source                = "../csv_etl"
  name                  = "csv_etl"
  region                = var.region
  environment           = var.environment
  create_csv_tag        = var.create_csv_tag
  aggregate_metrics_arn = aws_dynamodb_table.aggregate_metrics.arn
}