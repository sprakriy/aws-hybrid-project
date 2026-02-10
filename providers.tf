terraform {
  backend "s3" {
    bucket         = "sp-01102026-aws-kub"
    key            = "rds/terraform.tfstate" # Path inside the bucket
    region         = "us-east-1"
    encrypt        = true
    # Note: We are skipping DynamoDB locking to save you from more complexity/cost
  }
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# --- AWS PROVIDER ---
provider "aws" {
  region = "us-east-1" 
}

# --- KUBERNETES PROVIDER ---
# This configuration works both locally AND inside the cluster
provider "kubernetes" {
  # When running in a Pod, this can usually be left empty. 
  # Terraform will automatically detect the ServiceAccount.
}