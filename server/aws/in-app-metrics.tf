module "in_app_metrics" {
  region                  = var.region
  source                  = "./modules/metrics"
  vpc_id                  = aws_vpc.covidshield.id
  route_table_id          = aws_vpc.covidshield.main_route_table_id
  role_name               = aws_iam_role.role.name
  lambda_function_runtime = var.lambda-function-runtime
  subnet_ids              = aws_subnet.covidshield_private.*.id
  privatelink_sg          = aws_security_group.privatelink.id
  warn_topic              = aws_sns_topic.alert_warning.arn
  crticial_topic          = aws_sns_topic.alert_critical.arn
}
