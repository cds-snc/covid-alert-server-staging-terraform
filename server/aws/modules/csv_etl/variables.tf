variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

## This variable will be read from TF_VAR_CREATE_CSV_IMAGE in github actions
variable "create_csv_tag" {
  type = string
}

variable "aggregate_metrics_arn" {
  type = string
}