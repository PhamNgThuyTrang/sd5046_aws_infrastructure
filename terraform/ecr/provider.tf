provider "aws" {
  region  = "us-east-1"
  profile = "trangphamSD5046"
}

terraform {
  required_version = "~> 1.3.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-boostrap-nashtech-devops"
    key            = "ecr.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-boostrap-nashtech-devops"
    profile        = "trangphamSD5046"
    encrypt        = true
  }
} 