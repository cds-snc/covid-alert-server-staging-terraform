variable "service_name" {
  type        = string
  description = "Name of the service"
  default     = "cds-covid-alert-create-metric-record"
}

variable "owner" {
  type        = string
  description = "Name of the owner"
  default     = "terraform-lambda-zips"
}

variable "project" {
  type        = string
  description = "Name of the project"
  default     = "COVID-Alert"
}

variable "lambda_code" {
  type        = string
  description = "Name of the project"
  default     = "terraform-lambda-zips"
}

variable "s3_raw_metrics_bucket_name" {
  type        = string
  description = "S3 bucket that holds the raw mentric counts"
  default     = "cds-covid-alert-bucket-dev"
}

variable "api-description"{
  type        = string
  default     = "Terraform Serverless api for COVID Alert metrics collection"
}

variable "mks-description"{
  type        = string
  default     = "This CMK is used to encrypt the metrics bucket"
}

variable "lambda-description"{
  type        = string
  default     = "Lambda function for collecting metrics records"
}

variable "lambda-function-code"{
  type        = string
  default     = "createRecord.zip"
}

variable "lambda-function-runtime"{
  type        = string
  default     = "nodejs12.x"
}

variable "lambda-function-handler"{
  type        = string
  default     = "index.handler"
}

variable "waf-description"{
  type        = string
  default     = "WAF for API protection"
}


