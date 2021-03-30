##
#  Mectrics Collection Variables File mc-
##

variable "service_name" {
  type        = string
  description = "Name of the service"
  default     = "save-metrics"
}

variable "s3_raw_metrics_bucket_name" {
  type        = string
  description = "S3 bucket that holds the raw mentric counts"
  default     = "in-app-metrics"
}

variable "api-description" {
  type    = string
  default = "Terraform Serverless api for COVID Alert metrics collection"
}

variable "lambda-description" {
  type    = string
  default = "Lambda function for collecting metrics records"
}

variable "lambda-function-runtime" {
  type    = string
  default = "nodejs12.x"
}

variable "waf-description" {
  type    = string
  default = "WAF for API protection"
}

variable "apiKeyName" {
  type        = string
  description = "API Key Name"
  default     = "in-app-metrics-key"
}

variable "api_gateway_rate" {
  type    = string
  default = 10000
}

variable "api_gateway_burst" {
  type    = string
  default = 5000
}

variable "api_gateway_error_threshold" {
  type = string
}

variable "api_gateway_min_invocations" {
  type = string
}

variable "api_gateway_max_invocations" {
  type = string
}

variable "api_gateway_max_latency" {
  type = string
}

variable "save_metrics_max_avg_duration" {
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