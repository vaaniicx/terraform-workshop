# Konfiguriert Terraform
# Deklariert AWS als Anbieter und legt die Terraform-Version fest
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

# Legt die AWS-Region fest
provider "aws" {
  region = var.aws_region # definiert in variables.tf / terraform.tfvars
}
