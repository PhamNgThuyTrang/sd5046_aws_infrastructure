provider "aws" {
  region  = "us-east-1"
  profile = "trangphamSD5046"
}

terraform {
  backend "s3" {
    bucket         = "terraform-boostrap-nashtech-devops-0002"
    key            = "ec2.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-boostrap-nashtech-devops"
    profile        = "trangphamSD5046"
    encrypt        = true
  }
}

data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket  = "terraform-boostrap-nashtech-devops-0002"
    key     = "terraform.tfstate"
    profile = "trangphamSD5046"
    region  = "us-east-1"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  workspace = "dev"

  config = {
    bucket  = "terraform-boostrap-nashtech-devops-0002"
    key     = "network.tfstate"
    profile = "trangphamSD5046"
    region  = "us-east-1"
  }
}

terraform {
  required_version = "~> 1.3.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.67.0"
    }
  }
}