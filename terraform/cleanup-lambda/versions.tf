terraform {
  required_version = ">= 1.5"
  backend "s3" {
    bucket = "terraform-state-bucket-gbzfds"
    key    = "aws/eks-cleanup-lambda/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
