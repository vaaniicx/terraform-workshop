variable "project_name" {
  description = "Project name prefix used for tagging AWS resources"
  type        = string
  default     = "terraform-workshop"
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
