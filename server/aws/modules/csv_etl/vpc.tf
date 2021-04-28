resource "aws_vpc" "main" {

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}_vpc"
  }

}

resource "aws_nat_gateway" "nat_gateway" {

  allocation_id = aws_eip.lambda.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.name}-natgw"
  }

  depends_on = [
    aws_internet_gateway.gw
  ]
}


resource "aws_eip" "lambda" {
  vpc = true
}

resource "aws_subnet" "private" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}_private_subnet"
  }

  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "public" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}_public_subnet"
  }

  cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "gw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}_internet_gateway"
  }

}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "lambda" {
  description = "Used by lamba for access to the internet and the S3/DynamoDB private endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.name}_lambda_sg"
  }
}

resource "aws_security_group_rule" "inet_egress" {
  description       = "Allow lambda egress to the internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007  required to pull in lambda's data
  security_group_id = aws_security_group.lambda.id
}
