##
#  Mectrics Collection Variables File mc-
##

variable "service_name" {
  type        = string
  description = "Name of the service"
  default     = "cds-covid-alert-create-metric-record"
}

variable "owner" {
  type        = string
  description = "Name of the owner"
  default     = "CDS"
}

variable "project" {
  type        = string
  description = "Name of the project"
  default     = "COVID-Alert"
}

variable "lambda_code" {
  type        = string
  description = "Name of the project"
  default     = "cds-terraform-lambda-zips"
}

variable "s3_raw_metrics_bucket_name" {
  type        = string
  description = "S3 bucket that holds the raw mentric counts"
  default     = "cds-covid-alert-bucket-dev"
}

variable "s3_raw_metrics_bucket_logging_name" {
  type        = string
  description = "S3 bucket that holds the logs for the metrics bucket"
  default     = "cds-covid-alert-bucket-logging-dev"
}

variable "api-description" {
  type    = string
  default = "Terraform Serverless api for COVID Alert metrics collection"
}

variable "mks-description" {
  type    = string
  default = "This CMK is used to encrypt the metrics bucket"
}

variable "lambda-description" {
  type    = string
  default = "Lambda function for collecting metrics records"
}

variable "lambda-function-code" {
  type    = string
  default = "createRecord.zip"
}

variable "lambda-function-runtime" {
  type    = string
  default = "nodejs14.x"
}

variable "lambda-function-handler" {
  type    = string
  default = "index.handler"
}

variable "waf-description" {
  type    = string
  default = "WAF for API protection"
}

variable "apiKeyName" {
  type        = string
  description = "API Key Name"
  default     = "Dev-Key"
}

variable "apiKeyDescription" {
  type    = string
  default = "API Key for Development"
}

variable "api_gateway_rate" {
  type    = string
  default = 10000
}

variable "api_gateway_burst" {
  type    = string
  default = 5000
}
