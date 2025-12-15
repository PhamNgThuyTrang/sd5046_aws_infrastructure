provider "aws" {
  region  = "us-east-1"
  profile = "trangphamSD5046"
}

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-boostrap-sd5046-aws-infrastructure-0002"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-boostrap-sd5046-aws-infrastructure"
    profile        = "trangphamSD5046"
    encrypt        = true
    kms_key_id     = "36567f5c-4c73-4639-9650-273b82016f02"
  }
}
