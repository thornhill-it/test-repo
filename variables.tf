variable "aws_region" {
  description = "Region to deploy the Janitor"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource naming"
  type        = string
  default     = "cloud-janitor"
}

variable "lambda_function_name" {
  type    = string
  default = "S3_Public_Access_Janitor"
}

variable "alert_email" {
  description = "Email address for security notifications"
  type        = string
  # Will provide "default" valude via a command line or a .tfvars file
  default     = "" 
}
