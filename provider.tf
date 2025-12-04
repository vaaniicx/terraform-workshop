terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket = "terraform-state-github-vaaniicx"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Konfiguriert die Terraform-Einstellungen
# Einschließlich der erforderlichen Anbieter (AWS) und der Terraform-Version
# Mindestens Version 1.2 für Terraform erforderlich
# Backend S3 Bucket wird verwendet um Terraform State zu speichern
# Außerdem ist der S3 Bucket für GitHub Actions konfiguriert (z.B. Terraform Destroy)

provider "aws" {
  region = var.aws_region
}

# Konfiguriert den AWS-Anbieter mit der angegebenen Region
# Es ist möglich die Region in der Variable aws_region zu ändern