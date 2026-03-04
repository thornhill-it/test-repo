terraform {
  required_version = ">= 1.0.0"

  #############################################################################
  # REMOTE BACKEND CONFIGURATION (Enterprise Scale)
  # To enable: Create the S3 bucket and DynamoDB table, then uncomment below.
  # This ensures State Persistence and State Locking for team collaboration.
  # Consideration for concurrency and data protection in the production environment.
  #############################################################################
  # backend "s3" {
  #   bucket         = "your-unique-terraform-state-bucket" # Globally unique S3 bucket
  #   key            = "projects/cloud-janitor/terraform.tfstate"
  #   region         = "us-east-1"                          # Static region required for backend initialization
  #   dynamodb_table = "terraform-state-lock"               # Used for State Locking to prevent concurrent modifications
  #   encrypt        = true                                 # AES-256 encryption at rest data protection
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Dynamically pulls from your variables.tf
  region = var.aws_region

  # Global Governance: Every resource created will inherit these tags
  default_tags {
    tags = {
      Environment = "Production"
      Project     = "CloudJanitor"
      ManagedBy   = "Terraform"
      Owner       = "Security-Team"
    }
  }
}