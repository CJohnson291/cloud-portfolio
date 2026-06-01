terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "cloud-portfolio-tfstate-cj"
    key            = "portfolio/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "cloud-portfolio-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "azurerm" {
  features {}
}