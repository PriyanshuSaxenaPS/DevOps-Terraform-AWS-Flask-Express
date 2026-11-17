variable "aws_region" { type = string
  default = "ap-south-1" }
variable "state_bucket" { type = string
  description = "Globally unique S3 bucket name for Terraform state." }
