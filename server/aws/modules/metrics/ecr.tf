
resource "aws_ecr_repository" "create_csv" {
  name                 = "covid-server/metrics-server"
  image_tag_mutability = "MUTABLE"  # tfsec:ignore:AWS078  `latest` tags are used in Staging

  image_scanning_configuration {
    scan_on_push = true
  }
}