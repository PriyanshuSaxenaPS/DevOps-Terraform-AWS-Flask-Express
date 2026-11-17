variable "aws_region" { type = string
  default = "ap-south-1" }
variable "project" { type = string
  default = "terraform-demo-p2" }
variable "instance_type" { type = string
  default = "t3.micro" }
variable "ssh_cidr" { type = string
  description = "Your public IPv4 CIDR, e.g. 203.0.113.10/32" }
