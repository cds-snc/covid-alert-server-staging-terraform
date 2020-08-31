resource "aws_elasticache_subnet_group" "covidshield" {
  name       = "covidshield"
  subnet_ids = aws_subnet.covidshield_private.*.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_elasticache_replication_group" "covidshield" {
  automatic_failover_enabled    = true
  availability_zones            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  replication_group_id          = "covidshield"
  replication_group_description = "covidshield"
  node_type                     = "cache.t2.small"
  number_cache_clusters         = 3
  parameter_group_name          = "default.redis5.0"
  security_group_ids            = [aws_security_group.covidshield_redis.id]
  subnet_group_name             = aws_elasticache_subnet_group.covidshield.name
  apply_immediately             = true
  port                          = 6379
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}