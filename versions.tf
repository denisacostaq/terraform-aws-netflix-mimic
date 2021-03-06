terraform {
  required_version = "~> 0.15.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.40"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# terraform {
#   backend "remote" {
#     organization = "netflix-mimic"

#     workspaces {
#       name = "production"
#     }
#   }
# }