terraform {
  required_version = "= 0.14.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.21"
    }

  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {}