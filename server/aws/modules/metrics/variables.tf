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
