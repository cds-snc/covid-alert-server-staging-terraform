output "vpc" {
  value = aws_vpc.covidshield
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.covidshield
}

output "route53_zone" {
  value = aws_route53_zone.covidshield
}

output "aws_private_subnets" {
  value = aws_subnet.covidshield_private
}

output "aws_public_subnets" {
  value = aws_subnet.covidshield_public
}

output "security_group_load_balancer" {
  value = aws_security_group.covidshield_load_balancer
}
