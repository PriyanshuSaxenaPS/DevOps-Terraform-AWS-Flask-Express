variable "aws_region" { type = string
  default = "ap-south-1" }
variable "project" { type = string
  default = "terraform-demo-p3"
  validation { condition = can(regex("^[a-z0-9-]+$", var.project)) && length(var.project) <= 20
  error_message = "Use lowercase letters, digits and hyphens
  max 20 characters." } }
variable "image_tag" { type = string
  default = "v1" }
