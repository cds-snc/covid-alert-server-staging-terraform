
resource "aws_kms_key" "metrics_key" {
  description         = "Metrics key"
  enable_key_rotation = true
}
