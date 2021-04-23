variable "vpc_id" {
  type = string
}

variable "route_table_id" {
  type = string
}

variable "region" {
  type = string
}

variable "role_name" {
  type = string
}

variable "lambda_function_runtime" {
  type = string
}

variable "subnet_ids" {
  type = set(string)
}

variable "privatelink_sg" {
  type = string
}

variable "warn_topic" {
  type = string
}

variable "critical_topic" {
  type = string
}

variable "raw_metrics_dynamodb_wcu_max" {
  type = string
}

variable "aggregate_metrics_dynamodb_wcu_max" {
  type = string
}

variable "aggregate_metrics_max_avg_duration" {
  type = string
}

variable "backoff_retry_max_avg_duration" {
  type = string
}

variable "service_name" {
  type = string
}

variable "feature_count_alarms" {
  type = bool
}

variable "create_csv_tag" {
  type = string
}

variable "s3_endpoint" {
  type = string
}

variable "environment" {
  type = string
}