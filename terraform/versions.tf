terraform {
  required_version = ">= 1.5"
  backend "s3" {
    bucket = "cm-sdg-terraform-state-bucket"
    key    = "aws/eks-microservices/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
