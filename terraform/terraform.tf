# Define Terrraform Backend and Providers
terraform {
  required_version = "> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  shared_config_files      = ["~/.aws/config"]
  #profile                  = "prom_infradmin"
  region = "us-east-1"
}