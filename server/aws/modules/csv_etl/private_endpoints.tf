
resource "aws_security_group_rule" "covidshield_key_retrieval_egress_s3_privatelink" {
  description       = "Security group rule for Retrieval S3 egress through privatelink"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda.id
  prefix_list_ids = [
    aws_vpc_endpoint.s3.prefix_list_id
  ]
}

resource "aws_security_group_rule" "covidshield_key_retrieval_egress_dynamodb_privatelink" {
  description       = "Security group rule for Retrieval dynamodb egress through privatelink"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda.id
  prefix_list_ids = [
    aws_vpc_endpoint.dynamodb.prefix_list_id
  ]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [aws_route_table.public.id]

  tags = {
    Name = "${var.name}_s3_gateway"
  }
}


resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids   = [aws_route_table.public.id]

  tags = {
    Name = "${var.name}_dynamodb_gateway"
  }
}

