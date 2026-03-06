variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "us-east-1"
}

variable "service_name" {
  description = "Name of the service"
  default     = "skynet-ops-audit-service"
}

variable "environment" {
  description = "Environment name (dev/pilot)"
  default     = "dev"
}