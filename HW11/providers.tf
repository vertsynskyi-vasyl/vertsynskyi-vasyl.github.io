# --- root/providers.tf ---

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  shared_credentials_files = var.aws_credentials
  region = var.aws_region
  default_tags {
    tags = {
      Environment     = "Test"
      Service         = "Sonarqube"
    }
  }
}
