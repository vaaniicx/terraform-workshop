variable "project_name" {
  description = "Project name prefix used for tagging AWS resources"
  type        = string
  default     = "terraform_workshop"
  nullable    = false
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  nullable    = false
}

variable "instance_type" {
  description = "EC2 instance type to launch"
  type        = string
  default     = "t2.micro"
  nullable    = false
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_ip" {
  description = "Private IP address to assign to the EC2 instance network interface"
  type        = string
  default     = "10.0.1.50"
  nullable    = false
}
