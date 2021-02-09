module "in_app_metrics" { 
  source = "./modules/metrics"
  vpc_id = aws_vpc.covidshield.id
  route_table_id = aws_vpc.covidshield.main_route_table_id
}