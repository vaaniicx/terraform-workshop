terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

# Konfiguriert die Terraform-Einstellungen
# Einschließlich der erforderlichen Anbieter (AWS) und der Terraform-Version
# Mindestens Version 1.2 für Terraform erforderlich

provider "aws" {
  region = var.aws_region
}

# Konfiguriert den AWS-Anbieter mit der angegebenen Region
# Es ist möglich die Region in der Variable aws_region zu ändern
