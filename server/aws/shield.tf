# Enable shield on cloudfront distribution
resource "aws_shield_protection" "key_retrieval_distribution" {
  count        = var.feature_shield ? 1 : 0
  name         = "key_retrieval_distribution"
  resource_arn = aws_cloudfront_distribution.key_retrieval_distribution.arn
}

# Enable shield on Route53 hosted zone
resource "aws_shield_protection" "route53_covidshield" {
  count        = var.feature_shield ? 1 : 0
  name         = "route53_covidshield"
  resource_arn = "arn:aws:route53:::hostedzone/${aws_route53_zone.covidshield.zone_id}"
}
