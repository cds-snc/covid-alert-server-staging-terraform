module "metrics_data_vm" {
  source         = "github.com/cds-snc/terraform-ec2-module?ref=v1.0.1"
  name           = "metrics-data-vm"
  auto_public_ip = true
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCszlBXAE+FuP4l3Srh1KDfUzmx1sUy4KW5+khfCLMf6LQVl0ZxrBc82XrXo7s5eWKw7n+XR16Sa3hh4S6ZusCVsKnPkCqvyhad7K+IOxDjAzUBugrZcsTml1Qxz9Yb0ELJa3gqU230Jfim6Sd2fGHxzw8S06uKbgJ6ZmZnSPqi3RfxQj84w83ZW7Ubh7HyNF0Jr2O9VlEGqBAhqxLpheRU4+G/g1UrIAlMtcoVM1yaPkxmKPzCU2a0mY2IpWc2I8VegPXX2Jotkjxi3Ju8omnCvTENH8zD/uF0Pz8H1fh/dWYHeZfYJRh+j5m5FB0CM+I5cL+vqgMx9eiABFgZmDBx"
  # read_dynamodb   = true
  # dynamodb_tables = [ aws_dynamodb_table.raw_metrics.stream_arn ]
}
