terraform {
    required_version = ">= 1.3.0"

    backend "s3" {
        bucket         = "shopnow-terraform-state"
        key            = "dev/terraform.tfstate"
        region         = "ap-southeast-3"
        dynamodb_table = "shopnow-terraform-lock"
        encrypt        = true
    }
    
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.region
}

data "aws_region" "current" {}
